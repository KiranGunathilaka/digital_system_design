`timescale 1ns/1ps

module test_bench_tb;
  reg clk;
  reg rst;

  initial begin
    rst = 1'b1;
    #50 rst = 1'b0;
  end

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // safety timeout
  initial begin
    #5000000;
    $display("TIMEOUT");
    $finish;
  end

  test_bench uut(.clk(clk), .rst(rst));
endmodule
