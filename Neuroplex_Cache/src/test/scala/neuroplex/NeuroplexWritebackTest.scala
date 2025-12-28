package neuroplex

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import scala.collection.mutable

class NeuroplexWritebackTest extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "NeuroplexCache write-back + dirty"

  it should "write back a dirty victim and later read the modified data from memory" in {
    println("\n================ NeuroplexWritebackTest ================")
    println(s"[Config] Ways=${CacheParams.Ways}, NumSets=${CacheParams.NumSets}, LineBytes=${CacheParams.LineBytes} stride=${CacheParams.NumSets*CacheParams.LineBytes}")

    test(new NeuroplexCache).withAnnotations(Seq(WriteVcdAnnotation)) { c =>

      val memLatency = 2
      var pendingCycles  = -1
      var pendingBaseAddr = 0

      val memStore = mutable.HashMap[Int, BigInt]()

      val stride = CacheParams.NumSets * CacheParams.LineBytes
      def idxOf(a: Int): Int = (a >> CacheParams.OffsetBits) & ((1 << CacheParams.IndexBits) - 1)
      def tagOf(a: Int): Int = (a >> (CacheParams.OffsetBits + CacheParams.IndexBits)) & ((1 << CacheParams.TagBits) - 1)

      def makeLine(base: Int): BigInt = {
        var res = BigInt(0)
        for (i <- 7 to 0 by -1) {
          val w = (base + (i * 4)) & 0xFFFFFFFF
          res = (res << 32) | BigInt(w)
        }
        res
      }

      def stepMem(): Unit = {
        c.io.memReq.ready.poke(true.B)
        c.io.memResp.valid.poke(false.B)
        c.io.memResp.bits.rline.poke(0.U)

        if (c.io.memReq.valid.peek().litToBoolean && c.io.memReq.ready.peek().litToBoolean) {
          val a   = c.io.memReq.bits.addr.peek().litValue.toInt
          val wen = c.io.memReq.bits.wen.peek().litToBoolean

          if (wen) {
            val lineBI: BigInt = c.io.memReq.bits.wline.peek().litValue
            memStore(a) = lineBI
            println(f"[MEM] WRITEBACK addr=0x${a}%05X idx=0x${idxOf(a)}%03X tag=0x${tagOf(a)}%02X  (store now has ${memStore.size}%d lines)")
          } else {
            if (pendingCycles < 0) {
              pendingBaseAddr = a
              pendingCycles = memLatency
              println(f"[MEM] READ-REQ  addr=0x${a}%05X idx=0x${idxOf(a)}%03X tag=0x${tagOf(a)}%02X  latency=${memLatency}%d")
            }
          }
        }

        if (pendingCycles == 0 && c.io.memResp.ready.peek().litToBoolean) {
          val line = memStore.getOrElse(pendingBaseAddr, makeLine(pendingBaseAddr))
          c.io.memResp.valid.poke(true.B)
          c.io.memResp.bits.rline.poke(line.U(CacheParams.LineBits.W))
          println(f"[MEM] READ-RSP  addr=0x${pendingBaseAddr}%05X (from ${if (memStore.contains(pendingBaseAddr)) "STORE" else "GEN"}%s)")
          pendingCycles = -1
        } else if (pendingCycles > 0) {
          pendingCycles -= 1
        }

        c.clock.step(1)
      }

      var opCount = 0

      def doTxn(label: String, addr: Int, wen: Boolean, size: UInt, wdata: Long): (Boolean, Long) = {
        opCount += 1

        c.io.req.valid.poke(true.B)
        c.io.req.bits.addr.poke((addr & 0xFFFFF).U)
        c.io.req.bits.wen.poke(wen.B)
        c.io.req.bits.size.poke(size)
        c.io.req.bits.wdata.poke((wdata & 0xFFFFFFFFL).U)
        c.io.resp.ready.poke(true.B)

        var guard = 0
        while (!c.io.req.ready.peek().litToBoolean && guard < 200) { stepMem(); guard += 1 }
        stepMem() // accept
        c.io.req.valid.poke(false.B)

        guard = 0
        while (!c.io.resp.valid.peek().litToBoolean && guard < 800) { stepMem(); guard += 1 }

        val hit  = c.io.resp.bits.hit.peek().litToBoolean
        val data = c.io.resp.bits.rdata.peek().litValue.toLong
        val phase  = if (wen) "WR" else "RD"
        val status = if (hit) "HIT" else "MISS"

        println(
          f"[CPU][${phase}%s] ${label}%-10s addr=0x${addr}%05X idx=0x${idxOf(addr)}%03X tag=0x${tagOf(addr)}%02X => ${status}%s rdata=0x${data}%08X"
        )

        stepMem() // consume
        (hit, data)
      }

      val base = 0x3000
      val a0 = base + 0*stride
      val a1 = base + 1*stride
      val a2 = base + 2*stride
      val a3 = base + 3*stride

      val written = Map(
        a0 -> 0x11111111L,
        a1 -> 0x22222222L,
        a2 -> 0x33333333L,
        a3 -> 0x44444444L
      )

      println("\n[Phase 1] Fill 4 ways (reads -> misses + fills)")
      doTxn("fill-a0", a0, wen=false, CpuSize.WORD, 0)
      doTxn("fill-a1", a1, wen=false, CpuSize.WORD, 0)
      doTxn("fill-a2", a2, wen=false, CpuSize.WORD, 0)
      doTxn("fill-a3", a3, wen=false, CpuSize.WORD, 0)

      println("\n[Phase 2] Make all dirty (writes on hits)")
      doTxn("dirty-a0", a0, wen=true,  CpuSize.WORD, written(a0))
      doTxn("dirty-a1", a1, wen=true,  CpuSize.WORD, written(a1))
      doTxn("dirty-a2", a2, wen=true,  CpuSize.WORD, written(a2))
      doTxn("dirty-a3", a3, wen=true,  CpuSize.WORD, written(a3))

      println("\n[Phase 3] Thrash same set until we observe at least one WRITEBACK")
      var wbBase: Option[Int] = None
      var i = 4
      var guardEv = 0
      while (wbBase.isEmpty && guardEv < 30) {
        val ax = base + i*stride
        doTxn(s"thrash-$i", ax, wen=false, CpuSize.WORD, 0)

        val candidates = memStore.keys.filter(k => written.contains(k)).toSeq
        if (candidates.nonEmpty) wbBase = Some(candidates.head)

        i += 1
        guardEv += 1
      }

      assert(wbBase.isDefined, "expected at least one dirty write-back under conflict thrash")
      val evictedBase = wbBase.get
      val expectedWord0 = written(evictedBase)

      println(f"\n[Phase 4] Re-access evicted line addr=0x${evictedBase}%05X, should MISS and refill from memStore with written data")
      val (hitAfter, rdata) = doTxn("re-read", evictedBase, wen=false, CpuSize.WORD, 0)

      assert(!hitAfter, "should miss after being evicted")
      assert((rdata & 0xFFFFFFFFL) == (expectedWord0 & 0xFFFFFFFFL),
        "should read back the written word from memory after write-back")

      println(s"\n[PASS] Write-back observed + data preserved via memory store. ops=$opCount\n")
    }
  }
}
