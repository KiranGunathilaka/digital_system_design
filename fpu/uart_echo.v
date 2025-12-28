`timescale 1ns/1ps

// Echo test: receives a byte and transmits it back
// Use this to verify UART_RX pin, idle level, pull-up, and RX sampling
module uart_echo #(
  parameter integer CLK_HZ = 50_000_000,
  parameter integer BAUD   = 9600  // Start at 9600, then test 115200
)(
  input  wire CLOCK_50,
  input  wire RESET_N,
  input  wire UART_RX,
  output wire UART_TX
);

  wire clk = CLOCK_50;
  wire rst = ~RESET_N;

  // Properly rounded baud divider
  localparam integer CLKS_PER_BIT = (CLK_HZ + BAUD/2) / BAUD;

  wire       rx_dv;
  wire [7:0] rx_byte;

  wire       tx_dv;
  wire [7:0] tx_byte;
  wire       tx_active;
  wire       tx_done;

  uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
    .clk(clk),
    .rst(rst),
    .rx(UART_RX),
    .rx_dv(rx_dv),
    .rx_byte(rx_byte)
  );

  uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
    .clk(clk),
    .rst(rst),
    .tx_dv(tx_dv),
    .tx_byte(tx_byte),
    .tx_active(tx_active),
    .tx(UART_TX),
    .tx_done(tx_done)
  );

  // Echo logic: when we receive a byte, send it back
  reg [7:0] echo_buf;
  reg       echo_pending;

  assign tx_dv = echo_pending && !tx_active;
  assign tx_byte = echo_buf;

  always @(posedge clk) begin
    if (rst) begin
      echo_pending <= 1'b0;
      echo_buf <= 8'h00;
    end else begin
      // Store received byte (will echo when TX is ready)
      if (rx_dv) begin
        echo_buf <= rx_byte;
        echo_pending <= 1'b1;
      end

      // Clear pending flag when we start transmitting
      if (tx_dv) begin
        echo_pending <= 1'b0;
      end
    end
  end

endmodule

