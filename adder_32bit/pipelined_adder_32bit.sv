`timescale 1ns / 1ps

module pipelined_adder_32bit (
    input logic clk,
    input logic reset,

    input logic [31:0] num_a,
    input logic [31:0] num_b,

    input logic Cin,

    output logic [31:0] sum,
    output logic Cout
);

  logic [31:0] num_a_4;
  logic [31:0] num_b_4;

  logic [23:0] num_a_3;
  logic [23:0] num_b_3;

  logic [15:0] num_a_2;
  logic [15:0] num_b_2;

  logic [ 7:0] num_a_1;
  logic [ 7:0] num_b_1;

  logic [31:0] sum4;
  logic [23:0] sum3;
  logic [15:0] sum2;
  logic [ 7:0] sum1;

  logic c_in1, c_in2, c_in3, c_in4;

  //wires to avoid multiple driver issues
  logic [7:0] sum1_w, sum2_w, sum3_w, sum4_w;
  logic c_out1_w, c_out2_w, c_out3_w, c_out4_w;


  adder_8bit adder_1 (
      .a    (num_a_1),
      .b    (num_b_1),
      .c_in (c_in1),
      .sum  (sum1_w),
      .c_out(c_out1_w)
  );

  adder_8bit adder_2 (
      .a    (num_a_2[15:8]),
      .b    (num_b_2[15:8]),
      .c_in (c_in2),
      .sum  (sum2_w),
      .c_out(c_out2_w)
  );

  adder_8bit adder_3 (
      .a    (num_a_3[23:16]),
      .b    (num_b_3[23:16]),
      .c_in (c_in3),
      .sum  (sum3_w),
      .c_out(c_out3_w)
  );

  adder_8bit adder_4 (
      .a    (num_a_4[31:24]),
      .b    (num_b_4[31:24]),
      .c_in (c_in4),
      .sum  (sum4_w),
      .c_out(c_out4_w)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      num_a_4 <= '0;
      num_a_3 <= '0;
      num_a_2 <= '0;
      num_a_1 <= '0;
      num_b_4 <= '0;
      num_b_3 <= '0;
      num_b_2 <= '0;
      num_b_1 <= '0;

      c_in1 <= '0;
      c_in2 <= '0;
      c_in3 <= '0;
      c_in4 <= '0;

      sum1 <= '0;
      sum2 <= '0;
      sum3 <= '0;
      sum4 <= '0;
    end else begin
      sum1 <= sum1_w;
      sum2[15:8] <= sum2_w;  
      sum2[7:0] <= sum1;  
      sum3[23:16] <= sum3_w; 
      sum3[15:0] <= sum2;
      sum4[31:24] <= sum4_w; 
      sum4[23:0] <= sum3;

      num_a_1 <= num_a[7:0];
      num_b_1 <= num_b[7:0];
      num_a_2 <= {num_a_2[7:0], num_a[15:8]};
      num_b_2 <= {num_b_2[7:0], num_b[15:8]};
      num_a_3 <= {num_a_3[15:8], num_a_3[7:0], num_a[23:16]};
      num_b_3 <= {num_b_3[15:8], num_b_3[7:0], num_b[23:16]};
      num_a_4 <= {num_a_4[23:16], num_a_4[15:8], num_a_4[7:0], num_a[31:24]};
      num_b_4 <= {num_b_4[23:16], num_b_4[15:8], num_b_4[7:0], num_b[31:24]};

      c_in1 <= Cin;
      c_in2 <= c_out1_w;
      c_in3 <= c_out2_w;
      c_in4 <= c_out3_w;
    end
  end

  assign sum = sum4;
  assign Cout = c_out4_w;

endmodule
