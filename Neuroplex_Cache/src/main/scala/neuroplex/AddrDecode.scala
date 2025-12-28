package neuroplex

import chisel3._

class AddrDecodeIO extends Bundle {
  val addr   = Input(UInt(CacheParams.AddrBits.W))
  val tag    = Output(UInt(CacheParams.TagBits.W))
  val index  = Output(UInt(CacheParams.IndexBits.W))
  val offset = Output(UInt(CacheParams.OffsetBits.W))
}

class AddrDecode extends Module {
  val io = IO(new AddrDecodeIO)

  io.offset := io.addr(CacheParams.OffsetBits - 1, 0)
  io.index  := io.addr(CacheParams.OffsetBits + CacheParams.IndexBits - 1, CacheParams.OffsetBits)
  io.tag    := io.addr(CacheParams.AddrBits - 1, CacheParams.OffsetBits + CacheParams.IndexBits)
}
