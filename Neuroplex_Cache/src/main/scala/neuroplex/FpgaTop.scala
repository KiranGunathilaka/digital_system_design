package neuroplex

import chisel3._
import chisel3.util._

/**
  * FPGA Top:
  * - TrafficGen drives the cache
  * - MemModel answers cache misses (2-cycle latency)
  * - After TrafficGen finishes, stream counters out via UART TX
  *
  * Ports to map in UCF:
  *   clk      : board clock
  *   reset_n  : reset button (active low)
  *   uart_txd : RS232 TX pin (through level shifter on board)
  *   led      : optional LEDs (done/running)
  */
class FpgaTop(clockHz: Int = 50000000, baud: Int = 115200) extends RawModule {
  val clk     = IO(Input(Clock()))
  val reset_n = IO(Input(Bool()))
  val uart_txd= IO(Output(Bool()))
  val led     = IO(Output(UInt(8.W)))
  val done_all = IO(Output(Bool()))

  withClockAndReset(clk, (!reset_n).asAsyncReset) {

    val cache = Module(new NeuroplexCache)
    val mem   = Module(new MemModel(latency = 2))
    val gen   = Module(new TrafficGen(rounds = 10))
    val uart  = Module(new UartTx(clockHz, baud))
    val rep   = Module(new CounterReporter)

    // ---- hook cache <-> memory model ----
    mem.io.memReq  <> cache.io.memReq
    cache.io.memResp <> mem.io.memResp
    done_all := rep.io.done   // or (gen.io.done && rep.io.done)


    // ---- hook traffic gen <-> cache CPU port ----
    cache.io.req  <> gen.io.cpuReq
    cache.io.resp <> gen.io.cpuResp

    // ---- simple run control ----
    // Start generator immediately after reset
    val started = RegInit(false.B)
    when(!started) { started := true.B }
    gen.io.start := started

    // When generator done, start reporter once
    val repStarted = RegInit(false.B)
    when(gen.io.done && !repStarted) { repStarted := true.B }

    rep.io.start  := repStarted
    rep.io.access := cache.io.stat_access
    rep.io.hits   := cache.io.stat_hits
    rep.io.misses := cache.io.stat_misses
    rep.io.evicts := cache.io.stat_evictions

    // ---- UART wiring ----
    uart.io.inValid := rep.io.txValid
    uart.io.inByte  := rep.io.txByte
    rep.io.txReady  := uart.io.inReady

    uart_txd := uart.io.txd

    // ---- LEDs ----
// led0: blinks after generator done (termination visible without ChipScope)
// led1: cache busy (not accepting new req)
// led2: cache issued a memReq (miss or writeback in progress)
// led3: reporter done
// led4: uart busy
val blinkDiv = RegInit(0.U(26.W))    // ~0.7Hz at 50MHz (close enough)
blinkDiv := blinkDiv + 1.U
val blink = blinkDiv(25)

val doneBlink = Mux(gen.io.done, blink, false.B)

// Cache is "busy" whenever it is NOT ready to accept a new CPU request.
// In your cache, req.ready is only true in sIdle, so this is a clean proxy.
val cacheBusy = !cache.io.req.ready

led := Cat(
  0.U(3.W),
  uart.io.busy,            // led4
  rep.io.done,             // led3
  cache.io.memReq.valid,   // led2
  cacheBusy,               // led1
  doneBlink                // led0
)



  }
}
