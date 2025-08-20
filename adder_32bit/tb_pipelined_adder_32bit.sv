`timescale 1ns/1ps

module tb_pipelined_adder_32bit;

  // === DUT I/O ===
  logic        clk;
  logic        reset;
  logic [31:0] num_a, num_b;
  logic        Cin;
  logic [31:0] sum;
  logic        Cout;

  // Instantiate DUT
  pipelined_adder_32bit dut (
    .clk   (clk),
    .reset (reset),
    .num_a (num_a),
    .num_b (num_b),
    .Cin   (Cin),
    .sum   (sum),
    .Cout  (Cout)
  );

  // 100 MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // DUT pipeline latency
  localparam int LAT = 4;

  // === Scoreboard shift registers ===
  logic [31:0] exp_sum  [0:LAT];
  logic        exp_cout [0:LAT];

  int total_vecs = 0;
  int errors     = 0;

  // Optional: delay Cout by 1 to match registered sum if DUT leaves Cout combinational
  localparam bit USE_COUT_DELAY = 1'b0; // set to 1 if your DUT does NOT register Cout
  logic Cout_d;
  always_ff @(posedge clk) Cout_d <= Cout;
  wire Cout_aligned = (USE_COUT_DELAY) ? Cout_d : Cout;

  // === Helpers ===
  task push_expected(input logic [31:0] a,
                     input logic [31:0] b,
                     input logic        cin);
    logic [32:0] big;
    // shift toward index 0
    for (int j = 0; j < LAT; j++) begin
      exp_sum[j]  = exp_sum[j+1];
      exp_cout[j] = exp_cout[j+1];
    end
    big = {1'b0,a} + {1'b0,b} + cin;
    exp_sum[LAT]  = big[31:0];
    exp_cout[LAT] = big[32];
    total_vecs++;
  endtask

  task check_output;
    if ({Cout_aligned, sum} !== {exp_cout[0], exp_sum[0]}) begin
      $display("[%0t] MISMATCH: got Cout=%0b sum=%h | exp Cout=%0b sum=%h",
               $time, Cout_aligned, sum, exp_cout[0], exp_sum[0]);
      errors++;
    end
  endtask

  // === Main stimulus ===
  initial begin : main
    // ---- Declarations must come first in this block ----
    int i;
    logic [31:0] ra, rb;
    logic        rc;
    // Directed vectors (explicitly static to silence warnings)
    static logic [31:0] A   [6];
    static logic [31:0] B   [6];
    static logic        CINv[6];

    // ---- Now statements ----

    // init arrays & scoreboard
    for (i = 0; i <= LAT; i++) begin
      exp_sum[i]  = '0;
      exp_cout[i] = '0;
    end

    // init directed vectors
    A[0]=32'h0000_0000; B[0]=32'h0000_0000; CINv[0]=1'b0;
    A[1]=32'hFFFF_FFFF; B[1]=32'h0000_0001; CINv[1]=1'b0;
    A[2]=32'h7FFF_FFFF; B[2]=32'h0000_0001; CINv[2]=1'b0;
    A[3]=32'hFFFF_0000; B[3]=32'h0000_FFFF; CINv[3]=1'b1;
    A[4]=32'h1234_5678; B[4]=32'h9ABC_DEF0; CINv[4]=1'b0;
    A[5]=32'hDEAD_BEEF; B[5]=32'h1111_2222; CINv[5]=1'b1;

    // defaults
    num_a = '0; num_b = '0; Cin = 1'b0;

    // reset
    reset = 1'b1;
    repeat (3) @(posedge clk);
    reset = 1'b0;

    // warm-up
    repeat (LAT) begin
      num_a <= '0; num_b <= '0; Cin <= 1'b0;
      push_expected('0,'0,1'b0);
      @(posedge clk);
      check_output();
    end

    // directed cases
    for (i = 0; i < 6; i++) begin
      num_a <= A[i]; num_b <= B[i]; Cin <= CINv[i];
      push_expected(A[i], B[i], CINv[i]);
      @(posedge clk);
      check_output();
    end

    // pseudo-random traffic
    for (i = 0; i < 100; i++) begin
      ra = $random; rb = $random; rc = $random & 1'b1;
      num_a <= ra; num_b <= rb; Cin <= rc;
      push_expected(ra, rb, rc);
      @(posedge clk);
      check_output();
    end

    // drain
    repeat (LAT+2) begin
      num_a <= '0; num_b <= '0; Cin <= 1'b0;
      push_expected('0,'0,1'b0);
      @(posedge clk);
      check_output();
    end

    if (errors == 0)
      $display("\n[TB] ALL %0d TESTS PASSED", total_vecs);
    else
      $display("\n[TB] %0d / %0d TESTS FAILED", errors, total_vecs);

    $finish;
  end

endmodule
