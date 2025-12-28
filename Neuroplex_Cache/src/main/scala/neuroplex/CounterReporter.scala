package neuroplex

import chisel3._
import chisel3.util._

class CounterReporterIO extends Bundle {
  val start = Input(Bool())
  val done  = Output(Bool())

  val access = Input(UInt(32.W))
  val hits   = Input(UInt(32.W))
  val misses = Input(UInt(32.W))
  val evicts = Input(UInt(32.W))

  // UART TX interface
  val txValid = Output(Bool())
  val txByte  = Output(UInt(8.W))
  val txReady = Input(Bool())
}

class CounterReporter extends Module {
  val io = IO(new CounterReporterIO)

  val sIdle :: sSend :: sDone :: Nil = Enum(3)
  val st = RegInit(sIdle)
  val i  = RegInit(0.U(5.W)) // 0..17

  def byteOf(x: UInt, n: Int): UInt = x(8*n + 7, 8*n)

  val bytes = Wire(Vec(18, UInt(8.W)))
  bytes(0)  := "h55".U

  bytes(1)  := byteOf(io.access, 0)
  bytes(2)  := byteOf(io.access, 1)
  bytes(3)  := byteOf(io.access, 2)
  bytes(4)  := byteOf(io.access, 3)

  bytes(5)  := byteOf(io.hits, 0)
  bytes(6)  := byteOf(io.hits, 1)
  bytes(7)  := byteOf(io.hits, 2)
  bytes(8)  := byteOf(io.hits, 3)

  bytes(9)  := byteOf(io.misses, 0)
  bytes(10) := byteOf(io.misses, 1)
  bytes(11) := byteOf(io.misses, 2)
  bytes(12) := byteOf(io.misses, 3)

  bytes(13) := byteOf(io.evicts, 0)
  bytes(14) := byteOf(io.evicts, 1)
  bytes(15) := byteOf(io.evicts, 2)
  bytes(16) := byteOf(io.evicts, 3)

  bytes(17) := "hAA".U

  io.txValid := false.B
  io.txByte  := 0.U
  io.done    := (st === sDone)

  switch(st) {
    is(sIdle) {
      i := 0.U
      when(io.start) { st := sSend }
    }
    is(sSend) {
      io.txValid := true.B
      io.txByte  := bytes(i)
      when(io.txValid && io.txReady) {
        when(i === 17.U) { st := sDone }
        .otherwise { i := i + 1.U }
      }
    }
    is(sDone) {
      // stay done
    }
  }
}
