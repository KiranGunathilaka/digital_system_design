package neuroplex

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class NeuroplexCacheTagOnlyTest extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "NeuroplexCache (with miss FSM)"

  it should "miss then hit and show eviction on 5th conflicting line" in {
    println("\n================ NeuroplexCacheTagOnlyTest ================")

    test(new NeuroplexCache).withAnnotations(Seq(WriteVcdAnnotation)) { c =>

      val stride = CacheParams.NumSets * CacheParams.LineBytes // same-set stride (512*32=16384)

      println(s"[Config] NumSets=${CacheParams.NumSets}, LineBytes=${CacheParams.LineBytes}, Ways=${CacheParams.Ways}, stride(same index)=$stride bytes")

      // Memory model: fixed latency line returns (2 cycles)
      val memLatency = 2
      var pendingCycles  = -1
      var pendingBaseAddr = 0

      def makeLine(base: Int): BigInt = {
        var res = BigInt(0)
        for (i <- 7 to 0 by -1) {
          val w = (base + (i * 4)) & 0xFFFFFFFF
          res = (res << 32) | BigInt(w)
        }
        res
      }

      def stepMem(): Unit = {
        // default
        c.io.memReq.ready.poke(true.B)
        c.io.memResp.valid.poke(false.B)
        c.io.memResp.bits.rline.poke(0.U)

        val memReqFire =
          c.io.memReq.valid.peek().litToBoolean && c.io.memReq.ready.peek().litToBoolean

        // capture request
        if (memReqFire && pendingCycles < 0) {
          pendingBaseAddr = c.io.memReq.bits.addr.peek().litValue.toInt
          pendingCycles = memLatency
          println(f"[MemModel] accepted memReq base=0x$pendingBaseAddr%05X, respond in $memLatency cycles")
        }

        // countdown + respond
        if (pendingCycles == 0 && c.io.memResp.ready.peek().litToBoolean) {
          c.io.memResp.valid.poke(true.B)
          c.io.memResp.bits.rline.poke(makeLine(pendingBaseAddr).U(CacheParams.LineBits.W))
          println(f"[MemModel] -> memResp VALID base=0x$pendingBaseAddr%05X")
          pendingCycles = -1
        } else if (pendingCycles > 0) {
          pendingCycles -= 1
        }

        c.clock.step(1)
      }

      def doAccess(addr: Int, label: String): Boolean = {
        println(f"\n[Access:$label] READ addr=0x$addr%05X")

        c.io.req.valid.poke(true.B)
        c.io.req.bits.addr.poke((addr & 0xFFFFF).U)
        c.io.req.bits.wen.poke(false.B)          // read
        c.io.req.bits.size.poke(CpuSize.WORD)    // word
        c.io.req.bits.wdata.poke(0.U)
        c.io.resp.ready.poke(true.B)

        // wait accept
        var guard = 0
        while (!c.io.req.ready.peek().litToBoolean && guard < 200) { stepMem(); guard += 1 }

        stepMem() // accept happens here
        c.io.req.valid.poke(false.B)

        // wait response
        guard = 0
        while (!c.io.resp.valid.peek().litToBoolean && guard < 400) { stepMem(); guard += 1 }

        val hit = c.io.resp.bits.hit.peek().litToBoolean
        println(s"[Resp:$label] " + (if (hit) "HIT" else "MISS"))

        stepMem() // consume
        hit
      }

      // ---------------------------------------------------------
      // 1) cold miss then hit on same address
      // ---------------------------------------------------------
      val base1 = 0x00000
      println("\n[Test1] Cold miss then hit on same address")
      assert(!doAccess(base1, "base1-first"))
      assert(doAccess(base1, "base1-second"))

      // ---------------------------------------------------------
      // 2) 5 conflicting lines mapping to the SAME set index
      //    In a 4-way cache: first 4 fill ways, 5th forces eviction
      // ---------------------------------------------------------
      println("\n[Test2] Conflict set thrash: 5 lines -> eviction expected on 5th")
      val base2 = 0x2000

      val a0 = base2 + 0 * stride
      val a1 = base2 + 1 * stride
      val a2 = base2 + 2 * stride
      val a3 = base2 + 3 * stride
      val a4 = base2 + 4 * stride

      println(f"[ConflictAddrs] a0=0x$a0%05X a1=0x$a1%05X a2=0x$a2%05X a3=0x$a3%05X a4=0x$a4%05X")
      println(s"[Expect] First touches: all MISS. Then re-touch first 4: HIT. Then touch a4: MISS + eviction counter increments.")

      // Fill 4 ways (all misses)
      assert(!doAccess(a0, "a0-fill"))
      assert(!doAccess(a1, "a1-fill"))
      assert(!doAccess(a2, "a2-fill"))
      assert(!doAccess(a3, "a3-fill"))

      // Re-access (should be hits)
      assert(doAccess(a0, "a0-hit"))
      assert(doAccess(a1, "a1-hit"))
      assert(doAccess(a2, "a2-hit"))
      assert(doAccess(a3, "a3-hit"))

      val evBefore = c.io.stat_evictions.peek().litValue
      println(s"\n[EvictionCounter] before a4 = $evBefore")

      assert(!doAccess(a4, "a4-evict")) // 5th should evict one of the previous lines

      val evAfter = c.io.stat_evictions.peek().litValue
      println(s"[EvictionCounter] after a4 = $evAfter")
      assert(evAfter == evBefore + 1)

      // Summary for report
      val acc  = c.io.stat_access.peek().litValue
      val hits = c.io.stat_hits.peek().litValue
      val miss = c.io.stat_misses.peek().litValue
      val ev   = c.io.stat_evictions.peek().litValue

      println(s"\n[Summary] access=$acc hits=$hits misses=$miss evictions=$ev")
      println("[PASS] NeuroplexCacheTagOnlyTest\n")
    }
  }
}
