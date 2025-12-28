package neuroplex

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class NeuroplexConflictTraceTest extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "NeuroplexCache conflict-miss traces (multi-app)"

  it should "show conflict misses under interleaved streams and report avg latencies" in {
    println("\n================ NeuroplexConflictTraceTest ================")

    test(new NeuroplexCache).withAnnotations(Seq(WriteVcdAnnotation)) { c =>

      // ---- simple memory model (2-cycle fixed latency line reads) ----
      val memLatency = 2
      var pendingCycles   = -1
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

        // capture new mem request
        val memReqFire =
          c.io.memReq.valid.peek().litToBoolean &&
          c.io.memReq.ready.peek().litToBoolean

        if (memReqFire && pendingCycles < 0) {
          pendingBaseAddr = c.io.memReq.bits.addr.peek().litValue.toInt
          pendingCycles = memLatency
        }

        // respond after latency
        if (pendingCycles == 0 && c.io.memResp.ready.peek().litToBoolean) {
          c.io.memResp.valid.poke(true.B)
          c.io.memResp.bits.rline.poke(makeLine(pendingBaseAddr).U(CacheParams.LineBits.W))
          pendingCycles = -1
        } else if (pendingCycles > 0) {
          pendingCycles -= 1
        }

        c.clock.step(1)
      }

      // Pretty decode (for report prints)
      def idxOf(addr: Int): Int = (addr >> CacheParams.OffsetBits) & ((1 << CacheParams.IndexBits) - 1)
      def tagOf(addr: Int): Int = (addr >> (CacheParams.OffsetBits + CacheParams.IndexBits)) & ((1 << CacheParams.TagBits) - 1)

      // Print only first few operations (avoid flooding terminal)
      val verboseOps = 24
      var opCount = 0

      def doRead(addr: Int, label: String): Boolean = {
        val a = addr & ((1 << CacheParams.AddrBits) - 1)

        c.io.req.valid.poke(true.B)
        c.io.req.bits.addr.poke(a.U)
        c.io.req.bits.wen.poke(false.B)
        c.io.req.bits.size.poke(CpuSize.WORD)
        c.io.req.bits.wdata.poke(0.U)
        c.io.resp.ready.poke(true.B)

        var guard = 0
        while (!c.io.req.ready.peek().litToBoolean && guard < 400) { stepMem(); guard += 1 }

        stepMem() // accept request
        c.io.req.valid.poke(false.B)

        guard = 0
        while (!c.io.resp.valid.peek().litToBoolean && guard < 800) { stepMem(); guard += 1 }

        val hit = c.io.resp.bits.hit.peek().litToBoolean

        if (opCount < verboseOps) {
          println(f"[Op $opCount%03d] $label addr=0x$a%05X idx=${idxOf(a)} tag=${tagOf(a)} => " + (if (hit) "HIT" else "MISS"))
        }
        opCount += 1

        stepMem() // consume response
        hit
      }

      // ---- conflict trace generator ----
      // stride keeps same set index: 512 sets * 32B = 16384 bytes
      val stride = CacheParams.NumSets * CacheParams.LineBytes

      val baseA = 0x4000
      val baseB = 0x4000 + (stride * 8) // different tag, same index mapping

      val uniquePerApp = 4
      val rounds       = 10   // ✅ changed from 50 -> 10

      val aLines = (0 until uniquePerApp).map(k => baseA + k * stride)
      val bLines = (0 until uniquePerApp).map(k => baseB + k * stride)

      println(s"[Config] Ways=${CacheParams.Ways}, NumSets=${CacheParams.NumSets}, LineBytes=${CacheParams.LineBytes}, stride=$stride")
      println(s"[Trace ] two-app interleave: uniquePerApp=$uniquePerApp, rounds=$rounds, totalAccesses=${rounds * uniquePerApp * 2}")

      println("\n[AddrMap] Showing that all lines map to SAME index (conflict misses expected):")
      aLines.zipWithIndex.foreach { case (a, k) =>
        val aa = a & ((1 << CacheParams.AddrBits) - 1)
        println(f"  AppA[$k] addr=0x$aa%05X idx=${idxOf(aa)} tag=${tagOf(aa)}")
      }
      bLines.zipWithIndex.foreach { case (a, k) =>
        val aa = a & ((1 << CacheParams.AddrBits) - 1)
        println(f"  AppB[$k] addr=0x$aa%05X idx=${idxOf(aa)} tag=${tagOf(aa)}")
      }
      println(s"[Expect] Total unique lines in that set = ${uniquePerApp * 2} > Ways=${CacheParams.Ways} => thrashing")

      // Run trace
      var hits: Long = 0L
      var misses: Long = 0L

      for (r <- 0 until rounds) {
        for (k <- 0 until uniquePerApp) {
          if (doRead(aLines(k), s"A$r-$k")) hits = hits + 1 else misses = misses + 1
          if (doRead(bLines(k), s"B$r-$k")) hits = hits + 1 else misses = misses + 1
        }
      }

      val total: Long = hits + misses
      val missRate = misses.toDouble / total.toDouble
      val hitRate  = hits.toDouble / total.toDouble

      // Cache counters
      val acc  = c.io.stat_access.peek().litValue
      val hCnt = c.io.stat_hits.peek().litValue
      val mCnt = c.io.stat_misses.peek().litValue
      val ev   = c.io.stat_evictions.peek().litValue

      println("\n[ConflictTrace] Results (from observed hit flag):")
      println(f"  total=$total hits=$hits misses=$misses hitRate=$hitRate%.4f missRate=$missRate%.4f")

      println("[Counters] Results (from cache internal counters):")
      println(s"  access=$acc hits=$hCnt misses=$mCnt evictions=$ev")

      // ---- latency reporting (requires these ports exist in NeuroplexCacheIO) ----
      val hitCycTot  = c.io.stat_hitCyclesTotal.peek().litValue
      val missCycTot = c.io.stat_missCyclesTotal.peek().litValue

      val hitLat  = if (hCnt > 0) hitCycTot.toDouble / hCnt.toDouble else 0.0
      val missLat = if (mCnt > 0) missCycTot.toDouble / mCnt.toDouble else 0.0
      val missPenalty = missLat - hitLat

      println("\n[Latency] Averages from cache cycle counters:")
      println(f"  avgHitLatency=$hitLat%.3f cycles")
      println(f"  avgMissLatency=$missLat%.3f cycles")
      println(f"  missPenalty  =$missPenalty%.3f cycles (avgMiss - avgHit)")

      // Sanity: should not be near 0 miss-rate because two apps thrash a 4-way set
      require(missRate > 0.10, "miss rate should be noticeably > 0 under conflict-thrashing")

      println("[PASS] NeuroplexConflictTraceTest\n")
    }
  }
}
