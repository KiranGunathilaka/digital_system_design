`timescale 1ns/1ps

module uart_tx #(
  parameter integer CLKS_PER_BIT = 434
)(
  input  wire       clk,
  input  wire       rst,      // active-high synchronous reset
  input  wire       tx_dv,    // pulse 1 cycle to start sending tx_byte
  input  wire [7:0] tx_byte,
  output reg        tx_active,
  output reg        tx,       // serial out
  output reg        tx_done   // 1-cycle pulse when frame done
);

  localparam integer CTR_W = $clog2(CLKS_PER_BIT+1);

  localparam [2:0]
    S_IDLE     = 3'd0,
    S_START    = 3'd1,
    S_DATA     = 3'd2,
    S_STOP     = 3'd3,
    S_CLEANUP  = 3'd4;

  reg [2:0] state;
  reg [CTR_W-1:0] clk_cnt;
  reg [2:0] bit_idx;
  reg [7:0] data_buf;

  always @(posedge clk) begin
    if (rst) begin
      state     <= S_IDLE;
      clk_cnt   <= 0;
      bit_idx   <= 0;
      data_buf  <= 0;
      tx_active <= 1'b0;
      tx        <= 1'b1; // idle high
      tx_done   <= 1'b0;
    end else begin
      tx_done <= 1'b0;

      case (state)
        S_IDLE: begin
          tx        <= 1'b1;
          tx_active <= 1'b0;
          clk_cnt   <= 0;
          bit_idx   <= 0;

          if (tx_dv) begin
            data_buf  <= tx_byte;
            tx_active <= 1'b1;
            state     <= S_START;
          end
        end

        S_START: begin
          tx <= 1'b0; // start bit
          if (clk_cnt == CLKS_PER_BIT-1) begin
            clk_cnt <= 0;
            state   <= S_DATA;
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end

        S_DATA: begin
          tx <= data_buf[bit_idx];
          if (clk_cnt == CLKS_PER_BIT-1) begin
            clk_cnt <= 0;
            if (bit_idx == 3'd7) begin
              bit_idx <= 0;
              state   <= S_STOP;
            end else begin
              bit_idx <= bit_idx + 1;
            end
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end

        S_STOP: begin
          tx <= 1'b1;
          if (clk_cnt == CLKS_PER_BIT-1) begin
            clk_cnt <= 0;
            tx_done <= 1'b1;
            state   <= S_CLEANUP;
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end

        S_CLEANUP: begin
          tx_active <= 1'b0;
          state     <= S_IDLE;
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule
