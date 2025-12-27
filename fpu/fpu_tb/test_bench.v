`timescale 1ns/1ps

module test_bench(input clk, input rst);

  // DUT I/O
  reg  [1:0]  op;
  reg  [31:0] input_a;
  reg         input_a_stb;
  wire        input_a_ack;

  reg  [31:0] input_b;
  reg         input_b_stb;
  wire        input_b_ack;

  wire [31:0] output_z;
  wire        output_z_stb;
  reg         output_z_ack;

  // Instantiate top
  fpu_top dut (
    .clk(clk),
    .rst(rst),
    .op(op),
    .input_a(input_a),
    .input_a_stb(input_a_stb),
    .input_a_ack(input_a_ack),
    .input_b(input_b),
    .input_b_stb(input_b_stb),
    .input_b_ack(input_b_ack),
    .output_z(output_z),
    .output_z_stb(output_z_stb),
    .output_z_ack(output_z_ack)
  );

  integer fop, fa, fb, fz;
  integer rc;
  integer op_i;
  reg [31:0] a_val;
  reg [31:0] b_val;
  reg [31:0] z_val;

  // Handshake helpers
  task automatic send_a(input [31:0] v);
    begin
      input_a <= v;
      input_a_stb <= 1'b1;

      // Wait until ACK is observed high (it is registered in the DUT)
      while (input_a_ack !== 1'b1) @(posedge clk);

      // Transfer occurs on the next posedge with stb held high
      @(posedge clk);
      input_a_stb <= 1'b0;
    end
  endtask

  task automatic send_b(input [31:0] v);
    begin
      input_b <= v;
      input_b_stb <= 1'b1;
      while (input_b_ack !== 1'b1) @(posedge clk);
      @(posedge clk);
      input_b_stb <= 1'b0;
    end
  endtask

  task automatic recv_z(output [31:0] v);
    begin
      while (output_z_stb !== 1'b1) @(posedge clk);
      v = output_z;

      output_z_ack <= 1'b1;
      @(posedge clk);
      output_z_ack <= 1'b0;
    end
  endtask

  initial begin
    // defaults
    op = 2'b00;
    input_a = 32'h0;
    input_b = 32'h0;
    input_a_stb = 1'b0;
    input_b_stb = 1'b0;
    output_z_ack = 1'b0;

    // open files
    fop = $fopen("stim_op", "r");
    fa  = $fopen("stim_a",  "r");
    fb  = $fopen("stim_b",  "r");
    fz  = $fopen("resp_z",  "w");

    if (fop == 0 || fa == 0 || fb == 0 || fz == 0) begin
      $display("ERROR: failed to open stim/resp files.");
      $finish;
    end

    // wait for reset deassert + a couple cycles
    wait(rst == 1'b0);
    repeat (5) @(posedge clk);

    forever begin
      // op is decimal, a/b are hex
      rc = $fscanf(fop, "%d\n", op_i);
      if (rc != 1) begin
        $display("EOF stim_op -> finishing.");
        $finish;
      end

      rc = $fscanf(fa, "%h\n", a_val);
      if (rc != 1) begin
        $display("EOF stim_a -> finishing.");
        $finish;
      end

      rc = $fscanf(fb, "%h\n", b_val);
      if (rc != 1) begin
        $display("EOF stim_b -> finishing.");
        $finish;
      end

      op <= op_i[1:0];

      // IMPORTANT: keep op stable until A handshake completes
      send_a(a_val);
      send_b(b_val);

      recv_z(z_val);
      $fdisplay(fz, "%08h", z_val);
    end
  end

endmodule
