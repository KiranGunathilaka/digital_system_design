`timescale 1ns/1ps

// TX-only beacon test: sends 0x55 every 100ms
// Use this to verify UART_TX pin, IO standard, and baud rate
module uart_beacon #(
  parameter integer CLK_HZ = 50_000_000,
  parameter integer BAUD   = 9600  // Start at 9600, then test 115200
)(
  input  wire CLOCK_50,
  input  wire RESET_N,
  output wire UART_TX
);

  wire clk = CLOCK_50;
  wire rst = ~RESET_N;

  // Properly rounded baud divider
  localparam integer CLKS_PER_BIT = (CLK_HZ + BAUD/2) / BAUD;

  // 100ms timer: 50MHz * 0.1s = 5,000,000 cycles
  localparam integer TIMER_MAX = CLK_HZ / 10;
  localparam integer TIMER_W = $clog2(TIMER_MAX+1);

  wire       tx_dv;
  wire [7:0] tx_byte;
  wire       tx_active;
  wire       tx_done;

  reg [TIMER_W-1:0] timer;
  reg               send_pending;

  uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
    .clk(clk),
    .rst(rst),
    .tx_dv(tx_dv),
    .tx_byte(tx_byte),
    .tx_active(tx_active),
    .tx(UART_TX),
    .tx_done(tx_done)
  );

  assign tx_dv = send_pending && !tx_active;
  assign tx_byte = 8'h55;

  always @(posedge clk) begin
    if (rst) begin
      timer <= 0;
      send_pending <= 1'b0;
    end else begin
      if (timer == TIMER_MAX) begin
        timer <= 0;
        if (!tx_active) begin
          send_pending <= 1'b1;
        end
      end else begin
        timer <= timer + 1;
      end

      if (tx_dv) begin
        send_pending <= 1'b0;
      end
    end
  end

endmodule

