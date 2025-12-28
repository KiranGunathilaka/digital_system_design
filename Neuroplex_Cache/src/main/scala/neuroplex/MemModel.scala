package neuroplex

import chisel3._
import chisel3.util._

class MemModelIO extends Bundle {
  val memReq  = Flipped(Decoupled(new MemReq))
  val memResp = Decoupled(new MemResp)
}

/** Tiny memory model: returns a deterministic 32B line after fixed latency. */
class MemModel(latency: Int) extends Module {
  val io = IO(new MemModelIO)

  val busy = RegInit(false.B)
  val cnt  = RegInit(0.U(8.W))
  val baseAddr = Reg(UInt(CacheParams.AddrBits.W))

  // default
  io.memReq.ready := !busy
  io.memResp.valid := false.B
  io.memResp.bits.rline := 0.U

  def makeLine(base: UInt): UInt = {
    val w = Wire(Vec(8, UInt(32.W)))
    for (i <- 0 until 8) {
      w(i) := (base + (i.U << 2)).asUInt
    }
    Cat(w.reverse) // word7..word0
  }

  when(!busy) {
    when(io.memReq.fire) {
      baseAddr := io.memReq.bits.addr
      cnt := latency.U
      busy := true.B
    }
  }.otherwise {
    when(cnt === 0.U) {
      io.memResp.valid := true.B
      io.memResp.bits.rline := makeLine(baseAddr)
      when(io.memResp.fire) {
        busy := false.B
      }
    }.otherwise {
      cnt := cnt - 1.U
    }
  }
}
