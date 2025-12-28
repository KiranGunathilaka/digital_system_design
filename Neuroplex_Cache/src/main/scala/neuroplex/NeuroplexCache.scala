package neuroplex

import chisel3._
import chisel3.util._

class NeuroplexCacheIO extends Bundle {
  val req  = Flipped(Decoupled(new CpuReq))
  val resp = Decoupled(new CpuResp)

  val memReq  = Decoupled(new MemReq)
  val memResp = Flipped(Decoupled(new MemResp))

  val stat_access          = Output(UInt(32.W))
  val stat_hits            = Output(UInt(32.W))
  val stat_misses          = Output(UInt(32.W))
  val stat_evictions       = Output(UInt(32.W))
  val stat_hitCyclesTotal  = Output(UInt(32.W))
  val stat_missCyclesTotal = Output(UInt(32.W))
  val stat_lastLatency     = Output(UInt(32.W))
}

class NeuroplexCache extends Module {
  val io = IO(new NeuroplexCacheIO)

  val dec  = Module(new AddrDecode)
  val tags = Module(new TagArray)
  val data = Module(new DataArray)
  val cmp  = Module(new HitCompare)
  val repl = Module(new ReplRandom)

  // ---------------------------
  // Latency measurement
  // ---------------------------
  val cycle = RegInit(0.U(32.W))
  cycle := cycle + 1.U

  val reqStartCycle = RegInit(0.U(32.W))

  val hitCyclesTotal  = RegInit(0.U(32.W))
  val missCyclesTotal = RegInit(0.U(32.W))
  val lastLatency     = RegInit(0.U(32.W))

  io.stat_hitCyclesTotal  := hitCyclesTotal
  io.stat_missCyclesTotal := missCyclesTotal
  io.stat_lastLatency     := lastLatency

  // ---------------------------
  // FSM
  // ---------------------------
  val sIdle :: sLookup :: sWbReq :: sMemReq :: sWaitResp :: sResp :: Nil = Enum(6)
  val state = RegInit(sIdle)

  // Latch one CPU request
  val reqReg = RegInit(0.U.asTypeOf(new CpuReq))

  // Response regs
  val respHitReg  = RegInit(false.B)
  val respDataReg = RegInit(0.U(32.W))

  // Miss bookkeeping
  val allocWayReg = Reg(UInt(log2Ceil(CacheParams.Ways).W))
  val lineBaseReg = Reg(UInt(CacheParams.AddrBits.W))

  // Write-back bookkeeping
  val evictBaseReg = RegInit(0.U(CacheParams.AddrBits.W))
  val evictLineReg = RegInit(0.U(CacheParams.LineBits.W))

  // Counters
  val accessCnt = RegInit(0.U(32.W))
  val hitCnt    = RegInit(0.U(32.W))
  val missCnt   = RegInit(0.U(32.W))
  val evictCnt  = RegInit(0.U(32.W))

  io.stat_access    := accessCnt
  io.stat_hits      := hitCnt
  io.stat_misses    := missCnt
  io.stat_evictions := evictCnt

  // ---------------------------
  // Default IO
  // ---------------------------
  io.req.ready       := (state === sIdle)

  io.resp.valid      := (state === sResp)
  io.resp.bits.hit   := respHitReg
  io.resp.bits.rdata := respDataReg

  val doingWb = (state === sWbReq)

  io.memReq.valid      := (state === sMemReq) || doingWb
  io.memReq.bits.addr  := Mux(doingWb, evictBaseReg, lineBaseReg)
  io.memReq.bits.wen   := doingWb
  io.memReq.bits.wline := Mux(doingWb, evictLineReg, 0.U(CacheParams.LineBits.W)) // ✅ width-safe

  io.memResp.ready := (state === sWaitResp)

  // Replacement defaults
  repl.io.seedEn    := false.B
  repl.io.seedValue := 1.U
  repl.io.step      := false.B

  // Decode from reqReg
  dec.io.addr := reqReg.addr

  // Tag read + compare
  tags.io.rIndex := dec.io.index
  cmp.io.reqTag  := dec.io.tag
  cmp.io.tags    := tags.io.rOut.tags
  cmp.io.valids  := tags.io.rOut.valids

  // Allocate way: invalid-first else random
  val allocWayComb =
    Mux(cmp.io.hasInvalid, cmp.io.firstInvalidWay, repl.io.victimWay)

  // Probe way:
  // - hit: hitWay
  // - miss: allocWayComb (lets us read victim line for possible writeback)
  val probeWay = Mux(cmp.io.hit, cmp.io.hitWay, allocWayComb)

  // Data read
  data.io.rIndex := dec.io.index
  data.io.rWay   := probeWay
  val probeLine  = data.io.rLine

  // Word offset within 32B line
  val wordOffset = dec.io.offset(CacheParams.OffsetBits - 1, 2) // [4:2] => 0..7
  val reqMask    = MaskGen.mask32(reqReg.size, reqReg.addr(1, 0))

  // Helpers
  def getWord(line: UInt, woff: UInt): UInt = {
    val w0 = line(31, 0)
    val w1 = line(63, 32)
    val w2 = line(95, 64)
    val w3 = line(127, 96)
    val w4 = line(159, 128)
    val w5 = line(191, 160)
    val w6 = line(223, 192)
    val w7 = line(255, 224)
    MuxLookup(woff, 0.U(32.W), Seq(
      0.U -> w0, 1.U -> w1, 2.U -> w2, 3.U -> w3,
      4.U -> w4, 5.U -> w5, 6.U -> w6, 7.U -> w7
    ))
  }

  def mergeWordMasked(line: UInt, woff: UInt, wdata: UInt, wmask: UInt): UInt = {
    val oldW = getWord(line, woff)

    val mergedBytes = Wire(Vec(4, UInt(8.W)))
    for (b <- 0 until 4) {
      val oldB = oldW(8*b + 7, 8*b)
      val newB = wdata(8*b + 7, 8*b)
      mergedBytes(b) := Mux(wmask(b), newB, oldB)
    }
    val mergedW = Cat(mergedBytes.reverse)

    val newWords = Wire(Vec(8, UInt(32.W)))
    for (i <- 0 until 8) {
      val wi = line(32*i + 31, 32*i)
      newWords(i) := Mux(woff === i.U, mergedW, wi)
    }
    Cat(newWords.reverse)
  }

  // Line base address
  val lineBaseAddr =
    Cat(reqReg.addr(CacheParams.AddrBits - 1, CacheParams.OffsetBits),
        0.U(CacheParams.OffsetBits.W))

  // Victim info (only meaningful when !hasInvalid)
  val victimTag   = tags.io.rOut.tags(allocWayComb)
  val victimDirty = tags.io.rOut.dirties(allocWayComb)
  val victimBase  = Cat(victimTag, dec.io.index, 0.U(CacheParams.OffsetBits.W))

  // ---------------------------
  // Default array writes (off)
  // ---------------------------
  tags.io.wEn       := false.B
  tags.io.wIndex    := dec.io.index
  tags.io.wWay      := 0.U
  tags.io.wTag      := dec.io.tag
  tags.io.wValid    := true.B
  tags.io.wDirtyEn  := false.B
  tags.io.wDirtyVal := false.B

  data.io.wLineEn := false.B
  data.io.wIndex  := dec.io.index
  data.io.wWay    := 0.U
  data.io.wLine   := 0.U(CacheParams.LineBits.W)

  data.io.wWordEn     := false.B
  data.io.wWordIndex  := dec.io.index
  data.io.wWordWay    := cmp.io.hitWay
  data.io.wWordOffset := wordOffset
  data.io.wData       := reqReg.wdata
  data.io.wMask       := reqMask

  // ---------------------------
  // FSM behavior
  // ---------------------------
  when(state === sIdle) {
    when(io.req.fire) {
      reqReg        := io.req.bits
      accessCnt     := accessCnt + 1.U
      reqStartCycle := cycle
      state         := sLookup
    }
  }

  when(state === sLookup) {
    when(cmp.io.hit) {
      hitCnt := hitCnt + 1.U

      respHitReg  := true.B
      respDataReg := Mux(reqReg.wen, 0.U, getWord(probeLine, wordOffset))

      when(reqReg.wen) {
        // write hit: update word + mark dirty
        data.io.wWordEn     := true.B
        tags.io.wDirtyEn    := true.B
        tags.io.wDirtyVal   := true.B
        tags.io.wWay        := cmp.io.hitWay
      }

      state := sResp
    }.otherwise {
      missCnt    := missCnt + 1.U
      respHitReg := false.B

      // replacement only if no invalid
      when(!cmp.io.hasInvalid) {
        repl.io.step := true.B
        evictCnt     := evictCnt + 1.U
      }

      allocWayReg := allocWayComb
      lineBaseReg := lineBaseAddr

      // dirty victim => writeback first
      when(!cmp.io.hasInvalid && victimDirty) {
        evictBaseReg := victimBase
        evictLineReg := probeLine
        state        := sWbReq
      }.otherwise {
        state := sMemReq
      }
    }
  }

  when(state === sWbReq) {
    when(io.memReq.fire) { state := sMemReq }
  }

  when(state === sMemReq) {
    when(io.memReq.fire) { state := sWaitResp }
  }

  when(state === sWaitResp) {
    when(io.memResp.fire) {
      val refillLine = io.memResp.bits.rline
      val finalLine  = Mux(reqReg.wen,
        mergeWordMasked(refillLine, wordOffset, reqReg.wdata, reqMask),
        refillLine
      )

      // install tag/valid
      tags.io.wEn    := true.B
      tags.io.wWay   := allocWayReg
      tags.io.wValid := true.B
      tags.io.wTag   := dec.io.tag

      // install dirty (write-back policy)
      tags.io.wDirtyEn  := true.B
      tags.io.wDirtyVal := reqReg.wen

      // install line
      data.io.wLineEn := true.B
      data.io.wWay    := allocWayReg
      data.io.wLine   := finalLine

      respDataReg := Mux(reqReg.wen, 0.U, getWord(finalLine, wordOffset))
      state       := sResp
    }
  }

  when(state === sResp) {
    when(io.resp.fire) {
      val lat = cycle - reqStartCycle
      lastLatency := lat
      when(respHitReg) { hitCyclesTotal  := hitCyclesTotal  + lat }
        .otherwise    { missCyclesTotal := missCyclesTotal + lat }
      state := sIdle
    }
  }
}
