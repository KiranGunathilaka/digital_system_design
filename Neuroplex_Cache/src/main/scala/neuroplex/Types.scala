package neuroplex

import chisel3._
import chisel3.util._

/** CPU access size encoding (matches rubric: 1B / 2B / 4B) */
object CpuSize {
  val BYTE = 0.U(2.W)  // 1 byte
  val HALF = 1.U(2.W)  // 2 bytes
  val WORD = 2.U(2.W)  // 4 bytes
}

/** CPU -> Cache request (Decoupled) */
class CpuReq extends Bundle {
  val addr  = UInt(CacheParams.AddrBits.W)   // byte address
  val wen   = Bool()                         // write enable (false => read)
  val size  = UInt(2.W)                      // 0=byte, 1=half, 2=word
  val wdata = UInt(CacheParams.CpuDataBits.W)// valid when wen=1
}

/** Cache -> CPU response (Decoupled) */
class CpuResp extends Bundle {
  val rdata = UInt(CacheParams.CpuDataBits.W)
  val hit   = Bool()
}

/** Cache -> Memory request (simple valid/ready style) */
class MemReq extends Bundle {
  val addr  = UInt(CacheParams.AddrBits.W)    // byte address of the *line base*
  val wen   = Bool()                          // false=read line, true=write line
  val wline = UInt(CacheParams.LineBits.W)    // used for write-back
}

/** Memory -> Cache response */
class MemResp extends Bundle {
  val rline = UInt(CacheParams.LineBits.W)    // 32B line returned
}

/**
  * Utility: generate a 4-bit byte mask (for 32-bit word interface)
  * from size + addr(1,0).
  *
  * - BYTE: one-hot mask shifted by addr(1,0)
  * - HALF: 2-bit mask aligned to addr(1) (00->bytes0-1, 10->bytes2-3)
  * - WORD: 1111
  */
object MaskGen {
  def mask32(size: UInt, addrLo: UInt): UInt = {
    val byteMask = (1.U(4.W) << addrLo)                       // 0001,0010,0100,1000
    val halfShift = Cat(addrLo(1), 0.U(1.W))                  // 0 or 2
    val halfMask  = (3.U(4.W) << halfShift)                   // 0011 or 1100
    MuxLookup(size, 15.U(4.W), Seq(
      CpuSize.BYTE -> byteMask,
      CpuSize.HALF -> halfMask,
      CpuSize.WORD -> 15.U(4.W)
    ))
  }
}
