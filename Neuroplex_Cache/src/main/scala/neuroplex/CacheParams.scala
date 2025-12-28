package neuroplex

import chisel3.util.log2Ceil

object CacheParams {
  // ===== Spec =====
  val AddrBits   = 20          // 1MB byte address space => 2^20 addresses
  val CacheBytes = 64 * 1024   // 64KB cache
  val LineBytes  = 32          // 32B cache line
  val Ways       = 4           // 4-way set associative

  // ===== Assumptions for now (can change later) =====
  // CPU accesses are 32-bit words. We'll handle unaligned later if needed.
  val CpuDataBits  = 32
  val CpuDataBytes = CpuDataBits / 8

  // Memory refill returns a whole cache line at once (32B).
  // If your memory model returns 32-bit beats, we’ll adapt later with a refill buffer.
  val RefillWholeLine = true

  // ===== Derived =====
  val NumLines  = CacheBytes / LineBytes     // 2048 lines
  val NumSets   = NumLines / Ways            // 512 sets

  val OffsetBits = log2Ceil(LineBytes)       // 5
  val IndexBits  = log2Ceil(NumSets)         // 9
  val TagBits    = AddrBits - IndexBits - OffsetBits // 6

  // Useful masks / sizes
  val LineBits = LineBytes * 8               // 256 bits
}
