package neuroplex

import chisel3._
import chisel3.util._

class HitCompareIO extends Bundle {
  val reqTag  = Input(UInt(CacheParams.TagBits.W))
  val tags    = Input(Vec(CacheParams.Ways, UInt(CacheParams.TagBits.W)))
  val valids  = Input(Vec(CacheParams.Ways, Bool()))

  val hit     = Output(Bool())
  val hitVec  = Output(UInt(CacheParams.Ways.W))                 // one-hot (4 bits)
  val hitWay  = Output(UInt(log2Ceil(CacheParams.Ways).W))       // 2 bits for 4 ways

  val hasInvalid      = Output(Bool())
  val firstInvalidWay = Output(UInt(log2Ceil(CacheParams.Ways).W))
}

class HitCompare extends Module {
  val io = IO(new HitCompareIO)

  // one-hot match per way
  val matches = Wire(Vec(CacheParams.Ways, Bool()))
  for (w <- 0 until CacheParams.Ways) {
    matches(w) := io.valids(w) && (io.tags(w) === io.reqTag)
  }

  // Convert to UInt one-hot for convenience
  val hitVecUInt = matches.asUInt
  io.hitVec := hitVecUInt
  io.hit    := hitVecUInt.orR

  // Choose hitWay: PriorityEncoder chooses lowest-index '1'
  io.hitWay := PriorityEncoder(hitVecUInt)

  // Find first invalid way (also lowest-index priority)
  val invalidVec = Wire(Vec(CacheParams.Ways, Bool()))
  for (w <- 0 until CacheParams.Ways) {
    invalidVec(w) := !io.valids(w)
  }
  val invalidUInt = invalidVec.asUInt
  io.hasInvalid      := invalidUInt.orR
  io.firstInvalidWay := PriorityEncoder(invalidUInt)
}
