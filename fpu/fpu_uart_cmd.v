`timescale 1ns/1ps
module fpu_uart_cmd #(
  parameter integer RX_TIMEOUT_CYCLES = 2_000_000,   // ~40 ms @50 MHz
  parameter integer Z_TIMEOUT_CYCLES  = 50_000_000   // ~1 s  @50 MHz
)(
  input  wire        clk,
  input  wire        rst,

  input  wire        rx_dv,
  input  wire [7:0]  rx_byte,

  output reg         tx_dv,
  output reg  [7:0]  tx_byte,
  input  wire        tx_active,
  input  wire        tx_done,

  output reg  [1:0]  op,
  output reg  [31:0] input_a,
  output reg         input_a_stb,
  input  wire        input_a_ack,

  output reg  [31:0] input_b,
  output reg         input_b_stb,
  input  wire        input_b_ack,

  input  wire [31:0] output_z,
  input  wire        output_z_stb,
  output reg         output_z_ack
);

  localparam [7:0] SYNC_REQ  = 8'hA5;
  localparam [7:0] SYNC_RESP = 8'h5A;

  localparam [7:0]
    ST_OK       = 8'h00,
    ST_BAD_SYNC = 8'h01,
    ST_BAD_OP   = 8'h02,
    ST_TIMEOUT  = 8'h10;

  localparam [4:0]
    S_WAIT_SYNC = 5'd0,
    S_GET_OP    = 5'd1,
    S_GET_A     = 5'd2,
    S_GET_B     = 5'd3,
    S_ISSUE     = 5'd4,
    S_WAIT_AB   = 5'd5,
    S_WAIT_Z    = 5'd6,
    S_TX_0      = 5'd7,
    S_TX_1      = 5'd8,
    S_TX_2      = 5'd9,
    S_TX_3      = 5'd10,
    S_TX_4      = 5'd11,
    S_TX_5      = 5'd12;

  reg [4:0]  state;
  reg [7:0]  status;

  reg [31:0] a_buf, b_buf, z_buf;
  reg [2:0]  byte_idx;

  reg [31:0] rx_gap_cnt;
  reg [31:0] z_wait_cnt;

  function automatic can_tx;
    input dummy;
    begin
      can_tx = (tx_active == 1'b0);
    end
  endfunction

  wire a_xfer = input_a_stb && input_a_ack;
  wire b_xfer = input_b_stb && input_b_ack;

  always @(posedge clk) begin
    if (rst) begin
      state        <= S_WAIT_SYNC;
      status       <= ST_OK;

      op           <= 2'b00;
      input_a      <= 32'h0;
      input_b      <= 32'h0;
      input_a_stb  <= 1'b0;
      input_b_stb  <= 1'b0;
      output_z_ack <= 1'b0;

      a_buf        <= 32'h0;
      b_buf        <= 32'h0;
      z_buf        <= 32'h0;

      byte_idx     <= 3'd0;

      tx_dv        <= 1'b0;
      tx_byte      <= 8'h00;

      rx_gap_cnt   <= 32'd0;
      z_wait_cnt   <= 32'd0;
    end else begin
      // tx_dv is cleared at the start, then set conditionally in states
      tx_dv <= 1'b0;

      // RX gap counter (only used in RX states)
      if (state == S_GET_OP || state == S_GET_A || state == S_GET_B) begin
        if (rx_dv) rx_gap_cnt <= 32'd0;
        else if (rx_gap_cnt != 32'hFFFF_FFFF) rx_gap_cnt <= rx_gap_cnt + 1;
      end else begin
        rx_gap_cnt <= 32'd0;
      end

      case (state)
        S_WAIT_SYNC: begin
          input_a_stb  <= 1'b0;
          input_b_stb  <= 1'b0;
          output_z_ack <= 1'b0;
          byte_idx     <= 3'd0;
          z_wait_cnt   <= 32'd0;

          if (rx_dv) begin
            if (rx_byte == SYNC_REQ) begin
              status <= ST_OK;
              state  <= S_GET_OP;
            end else begin
              // stay quiet until we see A5
              status <= ST_BAD_SYNC;
              state  <= S_WAIT_SYNC;
            end
          end
        end

        S_GET_OP: begin
          if (rx_gap_cnt >= RX_TIMEOUT_CYCLES) begin
            status <= ST_TIMEOUT;
            z_buf  <= 32'h0;
            state  <= S_TX_0;
          end else if (rx_dv) begin
            if (rx_byte[7:2] != 6'd0 || rx_byte[1:0] > 2'd2) begin
              status <= ST_BAD_OP;
              op     <= 2'b00;
              z_buf  <= 32'h0;
              state  <= S_TX_0;
            end else begin
              status   <= ST_OK;
              op       <= rx_byte[1:0];
              a_buf    <= 32'h0;
              b_buf    <= 32'h0;
              byte_idx <= 3'd0;
              state    <= S_GET_A;
            end
          end
        end

        S_GET_A: begin
          if (rx_gap_cnt >= RX_TIMEOUT_CYCLES) begin
            status <= ST_TIMEOUT;
            z_buf  <= 32'h0;
            state  <= S_TX_0;
          end else if (rx_dv) begin
            a_buf[byte_idx*8 +: 8] <= rx_byte;
            if (byte_idx == 3'd3) begin
              byte_idx <= 3'd0;
              state    <= S_GET_B;
            end else begin
              byte_idx <= byte_idx + 1;
            end
          end
        end

        S_GET_B: begin
          if (rx_gap_cnt >= RX_TIMEOUT_CYCLES) begin
            status <= ST_TIMEOUT;
            z_buf  <= 32'h0;
            state  <= S_TX_0;
          end else if (rx_dv) begin
            b_buf[byte_idx*8 +: 8] <= rx_byte;
            if (byte_idx == 3'd3) begin
              byte_idx <= 3'd0;
              state    <= S_ISSUE;
            end else begin
              byte_idx <= byte_idx + 1;
            end
          end
        end

        S_ISSUE: begin
          input_a <= a_buf;
          input_b <= b_buf;

          input_a_stb  <= 1'b1;
          input_b_stb  <= 1'b1;

          // Assert early and keep high; safe for normal ready/valid handshakes
          output_z_ack <= 1'b1;

          z_wait_cnt <= 32'd0;
          state      <= S_WAIT_AB;
        end

        S_WAIT_AB: begin
          if (a_xfer) input_a_stb <= 1'b0;
          if (b_xfer) input_b_stb <= 1'b0;

          // both accepted
          if (!input_a_stb && !input_b_stb) begin
            state <= S_WAIT_Z;
          end
        end

        S_WAIT_Z: begin
          if (output_z_stb) begin
            z_buf        <= output_z;
            output_z_ack <= 1'b0;
            state        <= S_TX_0;
          end else if (z_wait_cnt >= Z_TIMEOUT_CYCLES) begin
            status       <= ST_TIMEOUT;
            z_buf        <= 32'h0;
            output_z_ack <= 1'b0;
            state        <= S_TX_0;
          end else begin
            z_wait_cnt <= z_wait_cnt + 1;
          end
        end

        S_TX_0: begin
          if (!tx_active) begin
            tx_byte <= SYNC_RESP;
            tx_dv <= 1'b1;
            state <= S_TX_1;
          end
        end
        S_TX_1: begin
          // Wait for transmission to complete (!tx_active) before sending next byte
          if (!tx_active) begin
            tx_byte <= status;
            tx_dv <= 1'b1;
            state <= S_TX_2;
          end
        end
        S_TX_2: begin
          if (!tx_active) begin
            tx_byte <= z_buf[7:0];
            tx_dv <= 1'b1;
            state <= S_TX_3;
          end
        end
        S_TX_3: begin
          if (!tx_active) begin
            tx_byte <= z_buf[15:8];
            tx_dv <= 1'b1;
            state <= S_TX_4;
          end
        end
        S_TX_4: begin
          if (!tx_active) begin
            tx_byte <= z_buf[23:16];
            tx_dv <= 1'b1;
            state <= S_TX_5;
          end
        end
        S_TX_5: begin
          if (!tx_active) begin
            tx_byte <= z_buf[31:24];
            tx_dv <= 1'b1;
            state <= S_WAIT_SYNC;
          end
        end

        default: state <= S_WAIT_SYNC;
      endcase
    end
  end
endmodule
