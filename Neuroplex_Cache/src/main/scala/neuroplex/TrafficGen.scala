package neuroplex

import chisel3._
import chisel3.util._

class TrafficGenIO extends Bundle {
  val cpuReq  = Decoupled(new CpuReq)
  val cpuResp = Flipped(Decoupled(new CpuResp))

  val start = Input(Bool())
  val done  = Output(Bool())
}

/** Generates an interleaved "two-app" conflict trace (reads only). */
class TrafficGen(rounds: Int = 64) extends Module {
  val io = IO(new TrafficGenIO)

  // stride chosen so that addresses map to the same set index (different tags)
  val stride = CacheParams.NumSets * CacheParams.LineBytes
  val baseA  = 0x4000
  val baseB  = 0x4000 + stride * 8

  val uniquePerApp = 4

  val addrList = VecInit(Seq.tabulate(uniquePerApp * 2) { i =>
    val k   = i / 2
    val isA = (i % 2) == 0
    val a   = if (isA) baseA + k * stride else baseB + k * stride
    (a & 0xFFFFF).U(CacheParams.AddrBits.W)
  })

  val sIdle :: sSend :: sWait :: sNext :: sDone :: Nil = Enum(5)
  val st = RegInit(sIdle)

  val idx = RegInit(0.U(4.W))   // 0..(2*uniquePerApp-1)
  val r   = RegInit(0.U(16.W))  // rounds counter

  io.done := (st === sDone)

  // default CPU req
  io.cpuReq.valid      := false.B
  io.cpuReq.bits.addr  := 0.U
  io.cpuReq.bits.wen   := false.B
  io.cpuReq.bits.size  := CpuSize.WORD   // ✅ always word reads for now
  io.cpuReq.bits.wdata := 0.U

  io.cpuResp.ready := false.B

  switch(st) {
    is(sIdle) {
      when(io.start) {
        idx := 0.U
        r   := 0.U
        st  := sSend
      }
    }

    is(sSend) {
      io.cpuReq.valid     := true.B
      io.cpuReq.bits.addr := addrList(idx)

      when(io.cpuReq.fire) {
        st := sWait
      }
    }

    is(sWait) {
      io.cpuResp.ready := true.B
      when(io.cpuResp.fire) {
        st := sNext
      }
    }

    is(sNext) {
      val lastIdx = (uniquePerApp * 2 - 1).U
      when(idx === lastIdx) {
        idx := 0.U
        when(r === (rounds - 1).U) {
          st := sDone
        }.otherwise {
          r := r + 1.U
          st := sSend
        }
      }.otherwise {
        idx := idx + 1.U
        st := sSend
      }
    }

    is(sDone) {
      // stay done
    }
  }
}
