package neuroplex

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class AddrDecodeTest extends AnyFlatSpec with ChiselScalatestTester {

  behavior of "AddrDecode"

  it should "split tag/index/offset correctly" in {
    println("\n================ AddrDecodeTest ================")
    println(s"[Config] AddrBits=${CacheParams.AddrBits}, OffsetBits=${CacheParams.OffsetBits}, IndexBits=${CacheParams.IndexBits}, TagBits=${CacheParams.TagBits}")
    println("[Meaning] addr -> {tag, index, offset}")

    test(new AddrDecode).withAnnotations(Seq(WriteVcdAnnotation)) { c =>

      val addrMask = (1 << CacheParams.AddrBits) - 1
      val offMask  = (1 << CacheParams.OffsetBits) - 1
      val idxMask  = (1 << CacheParams.IndexBits) - 1
      val tagMask  = (1 << CacheParams.TagBits) - 1

      def check(addrIn: Int, label: String): Unit = {
        val addr = addrIn & addrMask

        val offset = addr & offMask
        val index  = (addr >> CacheParams.OffsetBits) & idxMask
        val tag    = (addr >> (CacheParams.OffsetBits + CacheParams.IndexBits)) & tagMask

        c.io.addr.poke(addr.U)
        c.io.offset.expect(offset.U)
        c.io.index.expect(index.U)
        c.io.tag.expect(tag.U)

        println(f"[Check] $label%-18s addr=0x$addr%05X -> tag=0x$tag%02X index=0x$index%03X offset=0x$offset%02X")
      }

      check(0,      "zero")
      check(1,      "small +1")
      check(31,     "offset max")
      check(32,     "next line")
      check(33,     "next line +1")
      check(0x3FFF, "tag boundary -1")
      check(0x4000, "tag boundary +0")
      check(0xABCDE, "random")
      check(0xFFFFF, "max 20-bit")

      println("[PASS] AddrDecode outputs match expected bit-splitting.\n")
    }
  }
}
