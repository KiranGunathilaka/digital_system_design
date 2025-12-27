`timescale 1ns / 1ps

//
// op encoding:
//   2'b00 = ADD
//   2'b01 = MUL
//   2'b10 = DIV
//
// Important usage rule:
//   Need to keep `op` stable from the cycle that assert `input_a_stb` until the
//   A-handshake completes (input_a_stb && input_a_ack). After that, this
//   top-level latches the op and ignores changes until the result is accepted.
// Handshake is passed through to the selected unit.
module fpu_top (
  input         clk,
  input         rst,

  input  [1:0]  op,

  input  [31:0] input_a,
  input         input_a_stb,
  output        input_a_ack,

  input  [31:0] input_b,
  input         input_b_stb,
  output        input_b_ack,

  output [31:0] output_z,
  output        output_z_stb,
  input         output_z_ack
);

  localparam [1:0] OP_ADD = 2'b00;
  localparam [1:0] OP_MUL = 2'b01;
  localparam [1:0] OP_DIV = 2'b10;

  // Latch op for the duration of a transaction (from A accepted to Z accepted)
  reg  [1:0] op_lat;
  reg        busy;

  wire [1:0] op_sel = busy ? op_lat : op;

  wire add_a_ack, add_b_ack, add_z_stb;
  wire mul_a_ack, mul_b_ack, mul_z_stb;
  wire div_a_ack, div_b_ack, div_z_stb;

  wire [31:0] add_z, mul_z, div_z;

  // Gate STBs so only the selected unit sees them
  wire add_a_stb = input_a_stb && (op_sel == OP_ADD);
  wire add_b_stb = input_b_stb && (op_sel == OP_ADD);

  wire mul_a_stb = input_a_stb && (op_sel == OP_MUL);
  wire mul_b_stb = input_b_stb && (op_sel == OP_MUL);

  wire div_a_stb = input_a_stb && (op_sel == OP_DIV);
  wire div_b_stb = input_b_stb && (op_sel == OP_DIV);

  // Route output_z_ack only to the selected unit
  wire add_z_ack = output_z_ack && (op_sel == OP_ADD);
  wire mul_z_ack = output_z_ack && (op_sel == OP_MUL);
  wire div_z_ack = output_z_ack && (op_sel == OP_DIV);

  // Pass back ACKs from the selected unit
  assign input_a_ack =
      (op_sel == OP_ADD) ? add_a_ack :
      (op_sel == OP_MUL) ? mul_a_ack :
      (op_sel == OP_DIV) ? div_a_ack :
                           1'b0;

  assign input_b_ack =
      (op_sel == OP_ADD) ? add_b_ack :
      (op_sel == OP_MUL) ? mul_b_ack :
      (op_sel == OP_DIV) ? div_b_ack :
                           1'b0;

  // Mux result channel from the selected unit
  assign output_z =
      (op_sel == OP_ADD) ? add_z :
      (op_sel == OP_MUL) ? mul_z :
      (op_sel == OP_DIV) ? div_z :
                           32'h0;

  assign output_z_stb =
      (op_sel == OP_ADD) ? add_z_stb :
      (op_sel == OP_MUL) ? mul_z_stb :
      (op_sel == OP_DIV) ? div_z_stb :
                           1'b0;

  // Instantiate units
  adder u_add (
    .input_a      (input_a),
    .input_b      (input_b),
    .input_a_stb  (add_a_stb),
    .input_b_stb  (add_b_stb),
    .output_z_ack (add_z_ack),
    .clk          (clk),
    .rst          (rst),
    .output_z     (add_z),
    .output_z_stb (add_z_stb),
    .input_a_ack  (add_a_ack),
    .input_b_ack  (add_b_ack)
  );

  multiplier u_mul (
    .input_a      (input_a),
    .input_b      (input_b),
    .input_a_stb  (mul_a_stb),
    .input_b_stb  (mul_b_stb),
    .output_z_ack (mul_z_ack),
    .clk          (clk),
    .rst          (rst),
    .output_z     (mul_z),
    .output_z_stb (mul_z_stb),
    .input_a_ack  (mul_a_ack),
    .input_b_ack  (mul_b_ack)
  );

  divider u_div (
    .input_a      (input_a),
    .input_b      (input_b),
    .input_a_stb  (div_a_stb),
    .input_b_stb  (div_b_stb),
    .output_z_ack (div_z_ack),
    .clk          (clk),
    .rst          (rst),
    .output_z     (div_z),
    .output_z_stb (div_z_stb),
    .input_a_ack  (div_a_ack),
    .input_b_ack  (div_b_ack)
  );

  // Transaction tracking
  wire a_xfer = input_a_stb && input_a_ack;        // A accepted by selected unit
  wire z_xfer = output_z_stb && output_z_ack;      // Result accepted by downstream

  always @(posedge clk) begin
    if (rst) begin
      busy   <= 1'b0;
      op_lat <= OP_ADD;
    end else begin
      // Latch op at the start of a transaction (when A is accepted)
      if (!busy && a_xfer) begin
        op_lat <= op;
        busy   <= 1'b1;
      end

      // Clear busy when the selected unit's output is accepted
      if (busy && z_xfer) begin
        busy <= 1'b0;
      end
    end
  end

endmodule
