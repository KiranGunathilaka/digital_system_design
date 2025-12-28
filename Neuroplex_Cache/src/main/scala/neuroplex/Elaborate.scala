package neuroplex

import chisel3.stage.ChiselStage

object Elaborate extends App {
  (new ChiselStage).emitVerilog(
    new NeuroplexCache,
    Array("--target-dir", "generated")
  )
}
