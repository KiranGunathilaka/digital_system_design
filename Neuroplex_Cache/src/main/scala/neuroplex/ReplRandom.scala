package neuroplex

import chisel3._
import chisel3.util._

class ReplRandomIO extends Bundle {
  // Step the RNG only when you actually need a victim
  val step      = Input(Bool())

  // Optional deterministic seed control (good for tests)
  val seedEn    = Input(Bool())
  val seedValue = Input(UInt(16.W))

  // Output victim way (0..3)
  val victimWay = Output(UInt(log2Ceil(CacheParams.Ways).W)) // 2 bits for 4 ways
}

class ReplRandom extends Module {
  val io = IO(new ReplRandomIO)

  // 16-bit Fibonacci LFSR (simple, hardware-friendly)
  // taps: 16, 14, 13, 11 (common choice)
  val lfsr = RegInit(1.U(16.W)) // must not be 0

  when(io.seedEn) {
    lfsr := Mux(io.seedValue === 0.U, 1.U, io.seedValue)
  }.elsewhen(io.step) {
    val feedback = lfsr(15) ^ lfsr(13) ^ lfsr(12) ^ lfsr(10)
    lfsr := Cat(lfsr(14, 0), feedback)
  }

  // For 4-way, use 2 bits
  io.victimWay := lfsr(1, 0)
}
