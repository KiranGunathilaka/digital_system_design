package neuroplex

import chisel3.stage.ChiselStage

object ElaborateFpga extends App {
  (new ChiselStage).emitVerilog(
    new FpgaTop(clockHz = 50000000, baud = 115200),
    Array("--target-dir", "generated_fpga")
  )
}
