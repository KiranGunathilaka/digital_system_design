package neuroplex

import chisel3._
import chisel3.util._

/** Read-port output for one set: all ways' tags + valids + dirties */
class TagReadOut extends Bundle {
  val tags    = Vec(CacheParams.Ways, UInt(CacheParams.TagBits.W))
  val valids  = Vec(CacheParams.Ways, Bool())
  val dirties = Vec(CacheParams.Ways, Bool())
}

/** IO bundle (named) */
class TagArrayIO extends Bundle {
  val rIndex = Input(UInt(CacheParams.IndexBits.W))
  val rOut   = Output(new TagReadOut)

  // Tag/valid write (used on refill / invalidate)
  val wEn    = Input(Bool())
  val wIndex = Input(UInt(CacheParams.IndexBits.W))
  val wWay   = Input(UInt(log2Ceil(CacheParams.Ways).W))
  val wTag   = Input(UInt(CacheParams.TagBits.W))
  val wValid = Input(Bool())

  // Dirty write (used on write-hit and on refill)
  val wDirtyEn  = Input(Bool())
  val wDirtyVal = Input(Bool())
}

/** Tag + valid + dirty storage: NumSets × Ways */
class TagArray extends Module {
  val io = IO(new TagArrayIO)

  val tagMem = RegInit(VecInit(Seq.fill(CacheParams.NumSets)(
    VecInit(Seq.fill(CacheParams.Ways)(0.U(CacheParams.TagBits.W)))
  )))

  val validMem = RegInit(VecInit(Seq.fill(CacheParams.NumSets)(
    VecInit(Seq.fill(CacheParams.Ways)(false.B))
  )))

  val dirtyMem = RegInit(VecInit(Seq.fill(CacheParams.NumSets)(
    VecInit(Seq.fill(CacheParams.Ways)(false.B))
  )))

  // Read
  io.rOut.tags    := tagMem(io.rIndex)
  io.rOut.valids  := validMem(io.rIndex)
  io.rOut.dirties := dirtyMem(io.rIndex)

  // Tag/valid write
  when(io.wEn) {
    tagMem(io.wIndex)(io.wWay)   := io.wTag
    validMem(io.wIndex)(io.wWay) := io.wValid
    when(!io.wValid) { dirtyMem(io.wIndex)(io.wWay) := false.B } // safe clear on invalidate
  }

  // Dirty write (separate so we can set dirty without changing tag)
  when(io.wDirtyEn) {
    dirtyMem(io.wIndex)(io.wWay) := io.wDirtyVal
  }
}
