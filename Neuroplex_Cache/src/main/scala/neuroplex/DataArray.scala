package neuroplex

import chisel3._
import chisel3.util._

class DataArrayIO extends Bundle {
  // Read
  val rIndex = Input(UInt(CacheParams.IndexBits.W))
  val rWay   = Input(UInt(log2Ceil(CacheParams.Ways).W))
  val rLine  = Output(UInt(CacheParams.LineBits.W))

  // Whole-line write (refill)
  val wLineEn = Input(Bool())
  val wIndex  = Input(UInt(CacheParams.IndexBits.W))
  val wWay    = Input(UInt(log2Ceil(CacheParams.Ways).W))
  val wLine   = Input(UInt(CacheParams.LineBits.W))

  // Word write (store hit / store-after-refill)
  val wWordEn     = Input(Bool())
  val wWordIndex  = Input(UInt(CacheParams.IndexBits.W))
  val wWordWay    = Input(UInt(log2Ceil(CacheParams.Ways).W))
  val wWordOffset = Input(UInt(3.W)) // 0..7 (8 words per line)
  val wData       = Input(UInt(CacheParams.CpuDataBits.W))      // 32-bit
  val wMask       = Input(UInt(CacheParams.CpuDataBytes.W))     // 4-bit byte mask
}

class DataArray extends Module {
  val io = IO(new DataArrayIO)

  // Storage: [set][way] => 256-bit line
  val mem = RegInit(VecInit(Seq.fill(CacheParams.NumSets)(
    VecInit(Seq.fill(CacheParams.Ways)(0.U(CacheParams.LineBits.W)))
  )))

  // Combinational read
  io.rLine := mem(io.rIndex)(io.rWay)

  // Pick a 32-bit word from a 256-bit line (wordOffset 0..7)
  def getWord(line: UInt, wordOffset: UInt): UInt = {
    val w0 = line(31, 0)
    val w1 = line(63, 32)
    val w2 = line(95, 64)
    val w3 = line(127, 96)
    val w4 = line(159, 128)
    val w5 = line(191, 160)
    val w6 = line(223, 192)
    val w7 = line(255, 224)

    MuxLookup(wordOffset, 0.U(32.W), Seq(
      0.U -> w0, 1.U -> w1, 2.U -> w2, 3.U -> w3,
      4.U -> w4, 5.U -> w5, 6.U -> w6, 7.U -> w7
    ))
  }

  // Write a 32-bit word with byte mask into a 256-bit line (NO comb loop)
  def writeWordMasked(line: UInt, wordOffset: UInt, wdata: UInt, wmask: UInt): UInt = {
    val oldW = getWord(line, wordOffset)

    // Byte-level merge
    val mergedBytes = Wire(Vec(4, UInt(8.W)))
    for (b <- 0 until 4) {
      val oldB = oldW(8*b + 7, 8*b)
      val newB = wdata(8*b + 7, 8*b)
      mergedBytes(b) := Mux(wmask(b), newB, oldB)
    }
    val mergedW = Cat(mergedBytes.reverse) // 32-bit

    // Repack 8 words, replacing only the selected word
    val newWords = Wire(Vec(8, UInt(32.W)))
    for (i <- 0 until 8) {
      val wi = line(32*i + 31, 32*i)
      newWords(i) := Mux(wordOffset === i.U, mergedW, wi)
    }
    Cat(newWords.reverse) // word7..word0
  }

  // If refill line + word write target same location in same cycle, apply word write onto wLine
  val sameLoc =
    io.wLineEn && io.wWordEn &&
      (io.wIndex === io.wWordIndex) &&
      (io.wWay   === io.wWordWay)

  // Line write (only when not sameLoc, otherwise word-write will cover it)
  when(io.wLineEn && !sameLoc) {
    mem(io.wIndex)(io.wWay) := io.wLine
  }

  // Word write (can happen alone, or on top of refill line)
  when(io.wWordEn) {
    val baseLine = Mux(sameLoc, io.wLine, mem(io.wWordIndex)(io.wWordWay))
    mem(io.wWordIndex)(io.wWordWay) := writeWordMasked(baseLine, io.wWordOffset, io.wData, io.wMask)
  }
}
