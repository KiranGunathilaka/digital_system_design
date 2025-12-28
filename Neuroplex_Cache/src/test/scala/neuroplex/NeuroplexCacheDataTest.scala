package neuroplex

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class NeuroplexCacheDataTest extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "NeuroplexCache (with data + miss FSM)"

  it should "return refill data on miss-response and support byte/half/word writes via size" in {
    println("\n================ NeuroplexCacheDataTest ================")
    println(s"[Config] LineBytes=${CacheParams.LineBytes}, NumSets=${CacheParams.NumSets}, Ways=${CacheParams.Ways}, OffsetBits=${CacheParams.OffsetBits}")

    test(new NeuroplexCache).withAnnotations(Seq(WriteVcdAnnotation)) { c =>

      val memLatency = 2
      var pendingCycles  = -1
      var pendingBaseAddr = 0

      def lineBase(addr: Int): Int = addr & ~((1 << CacheParams.OffsetBits) - 1)
      def expectedWord(addr: Int): Int = {
        val base = lineBase(addr)
        val wordOff = (addr >> 2) & 0x7
        base + (wordOff << 2)
      }

      def makeLine(base: Int): BigInt = {
        var res = BigInt(0)
        for (i <- 7 to 0 by -1) {
          val w = (base + (i * 4)) & 0xFFFFFFFF
          res = (res << 32) | BigInt(w)
        }
        res
      }

      def sizeName(size: Int): String = size match {
        case 0 => "BYTE"
        case 1 => "HALF"
        case 2 => "WORD"
        case _ => s"UNK($size)"
      }

      // Simple memory model stepping (prints only when something happens)
      def stepMem(): Unit = {
        c.io.memReq.ready.poke(true.B)
        c.io.memResp.valid.poke(false.B)
        c.io.memResp.bits.rline.poke(0.U)

        val memReqFire = c.io.memReq.valid.peek().litToBoolean && c.io.memReq.ready.peek().litToBoolean

        if (memReqFire && pendingCycles < 0) {
          pendingBaseAddr = c.io.memReq.bits.addr.peek().litValue.toInt
          pendingCycles = memLatency
          println(f"[MemModel] accepted memReq base=0x$pendingBaseAddr%05X, will respond in $memLatency cycles")
        }

        if (pendingCycles == 0 && c.io.memResp.ready.peek().litToBoolean) {
          val line = makeLine(pendingBaseAddr)
          c.io.memResp.valid.poke(true.B)
          c.io.memResp.bits.rline.poke(line.U(CacheParams.LineBits.W))
          println(f"[MemModel] -> memResp VALID base=0x$pendingBaseAddr%05X (line[255:0] generated)")
          pendingCycles = -1
        } else if (pendingCycles > 0) {
          pendingCycles -= 1
        }

        c.clock.step(1)
      }

      // One CPU transaction (R/W) until response comes back
      def doTxn(addr: Int, wen: Boolean, size: Int, wdata: Long, label: String): (Boolean, BigInt) = {
        val exp = expectedWord(addr) & 0xFFFFFFFFL

        println(f"\n[Txn:$label] ${if (wen) "WRITE" else "READ "} size=${sizeName(size)} addr=0x$addr%05X expRead=0x$exp%08X wdata=0x${wdata & 0xFFFFFFFFL}%08X")

        c.io.req.valid.poke(true.B)
        c.io.req.bits.addr.poke((addr & 0xFFFFF).U)
        c.io.req.bits.wen.poke(wen.B)
        c.io.req.bits.size.poke((size & 0x3).U)
        c.io.req.bits.wdata.poke((wdata & 0xFFFFFFFFL).U)
        c.io.resp.ready.poke(true.B)

        var guard = 0
        while (!c.io.req.ready.peek().litToBoolean && guard < 200) { stepMem(); guard += 1 }

        stepMem() // accept request
        c.io.req.valid.poke(false.B)

        guard = 0
        while (!c.io.resp.valid.peek().litToBoolean && guard < 500) { stepMem(); guard += 1 }

        val hit  = c.io.resp.bits.hit.peek().litToBoolean
        val data = c.io.resp.bits.rdata.peek().litValue
        println(f"[Resp:$label] hit=$hit rdata=0x$data%08X")

        stepMem() // consume response
        (hit, data)
      }

      val addr = 0x1234

      // 1) Read miss then refill returns correct word (hit=false)
      val (h1, r1) = doTxn(addr, wen=false, size=2, wdata=0, label="read-miss")
      assert(!h1)
      assert(r1 == (expectedWord(addr) & 0xFFFFFFFFL))

      // 2) Read hit
      val (h2, r2) = doTxn(addr, wen=false, size=2, wdata=0, label="read-hit")
      assert(h2)
      assert(r2 == (expectedWord(addr) & 0xFFFFFFFFL))

      // 3) HALF write hit (addr[1:0] = 00 here => low halfword)
      val wdata = 0xA1B2C3D4L
      val (h3, _) = doTxn(addr, wen=true, size=1, wdata=wdata, label="half-write-hit")
      assert(h3)

      // 4) Read back shows merged bytes
      val (h4, r4) = doTxn(addr, wen=false, size=2, wdata=0, label="read-after-half")
      assert(h4)

      val oldW = expectedWord(addr) & 0xFFFFFFFF
      val newW = {
        val b0 = (wdata & 0xFF).toInt
        val b1 = ((wdata >> 8) & 0xFF).toInt
        val b2 = ((oldW >> 16) & 0xFF)
        val b3 = ((oldW >> 24) & 0xFF)
        (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)) & 0xFFFFFFFF
      }
      println(f"[Check] expected merged=0x$newW%08X got=0x${r4.toLong & 0xFFFFFFFFL}%08X")
      require(r4 == (newW & 0xFFFFFFFFL))

      // ---- Summary prints (great for report screenshots) ----
      val acc = c.io.stat_access.peek().litValue
      val hits = c.io.stat_hits.peek().litValue
      val miss = c.io.stat_misses.peek().litValue
      val ev   = c.io.stat_evictions.peek().litValue
      println(s"\n[Summary] access=$acc hits=$hits misses=$miss evictions=$ev")

      // If you added latency totals in IO, print averages too
      // (If these ports don't exist in your current IO, delete this block)
      if (c.io.elements.contains("stat_hitCyclesTotal") && c.io.elements.contains("stat_missCyclesTotal")) {
        val hitCyc  = c.io.stat_hitCyclesTotal.peek().litValue
        val missCyc = c.io.stat_missCyclesTotal.peek().litValue
        val hitLat  = if (hits > 0) hitCyc.toDouble / hits.toDouble else 0.0
        val missLat = if (miss > 0) missCyc.toDouble / miss.toDouble else 0.0
        val missPenalty = missLat - hitLat
        println(f"[Latency] avgHit=$hitLat%.2f cyc, avgMiss=$missLat%.2f cyc, missPenalty=$missPenalty%.2f cyc")
      }

      println("[PASS] NeuroplexCacheDataTest\n")
    }
  }
}
