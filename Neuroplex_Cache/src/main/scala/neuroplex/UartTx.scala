package neuroplex

import chisel3._
import chisel3.util._

class UartTxIO extends Bundle {
  val inValid = Input(Bool())
  val inByte  = Input(UInt(8.W))
  val inReady = Output(Bool())
  val txd     = Output(Bool())
  val busy    = Output(Bool())
}

/** Minimal UART TX (8N1) using fractional baud generator (phase accumulator).
  * Works for common combos like 50MHz + 115200.
  */
class UartTx(clockHz: Int, baud: Int) extends Module {
  val io = IO(new UartTxIO)

  // ------------------------------------------------------------
  // Fractional baud tick generator (phase accumulator)
  // acc += baud; if acc >= clockHz => tick, acc -= clockHz
  //
  // IMPORTANT FIX:
  // Use a minimal accumulator width so XST doesn't create
  // "unconnected sequential node" warnings for unused bits.
  // ------------------------------------------------------------
  val accWidth = log2Ceil(clockHz) + 1
  val acc  = RegInit(0.U(accWidth.W))
  val tick = WireDefault(false.B)

  val next = acc + baud.U(accWidth.W)
  when(next >= clockHz.U(accWidth.W)) {
    acc  := next - clockHz.U(accWidth.W)
    tick := true.B
  }.otherwise {
    acc := next
  }

  // UART shift reg: start(0) + 8 data bits + stop(1)
  val shreg  = RegInit("b1111111111".U(10.W)) // idle high
  val bitCnt = RegInit(0.U(4.W))
  val active = RegInit(false.B)

  io.txd     := shreg(0)
  io.busy    := active
  io.inReady := !active

  when(!active) {
    bitCnt := 0.U
    when(io.inValid) {
      val frame = Cat(1.U(1.W), io.inByte, 0.U(1.W)) // stop, data, start
      shreg  := frame
      active := true.B
    }
  }.otherwise {
    when(tick) {
      shreg  := Cat(1.U(1.W), shreg(9, 1)) // shift right, fill with 1s
      bitCnt := bitCnt + 1.U
      when(bitCnt === 9.U) { // 10 bits sent
        active := false.B
      }
    }
  }
}
