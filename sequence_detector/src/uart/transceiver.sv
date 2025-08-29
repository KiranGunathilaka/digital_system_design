module transceiver #(
    parameter CLOCKS_PER_PULSE = 5208,
    BITS_PER_WORD    = 8
) (
    input logic clk,
    input logic rstn,

    input logic mode_in,

    // UART interface
    input  logic rx,
    output logic tx,

    // Output for visual feedback
    output logic [7:0] led_detected
);

  // UART RX signals
  logic m_valid;
  logic [7:0] m_data;

  // UART TX signals
  logic s_valid, s_ready;
  logic [7:0] s_data;

  // Sequence detector
  logic o_seq_detected, no_seq_detected, out;

  logic mode, mode_in_q;

  uart #(
      .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE),
      .BITS_PER_WORD(BITS_PER_WORD)
  ) uart_inst (
      .clk(clk),
      .rstn(rstn),
      .s_valid(s_valid),
      .s_data(s_data),
      .s_ready(s_ready),
      .tx(tx),
      .rx(rx),
      .m_valid(m_valid),
      .m_data(m_data)
  );

  // logic for advancing the sequence detector only when a bit is received
  logic sym_bit, sym_en;

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      sym_bit <= 1'b0;
      sym_en  <= 1'b0;
    end else begin
      sym_en <= m_valid;  // one-cycle pulse when a byte arrives so FSM advanced only once
      if (m_valid) sym_bit <= m_data[0];
      else sym_bit <= sym_bit;  // if didn't received new value, hold value
    end
  end

  sequence_detector_0110 u_no_overlap (
      .clk     (clk),
      .reset   (!rstn),
      .en      (sym_en),          // only step once per byte
      .data_in (sym_bit),
      .detected(no_seq_detected)
  );

  overlapping_sequence_detector_0110 u_overlap (
      .clk     (clk),
      .reset   (!rstn),
      .en      (sym_en),         // only step once per byte
      .data_in (sym_bit),
      .detected(o_seq_detected)
  );

  always_comb begin
    case (mode)
      1'b0: out = no_seq_detected;
      1'b1: out = o_seq_detected;
    endcase
  end

  assign led_detected = {8{out}};  // make all LEDs light up

  // When sequence is detected, send 'D' over UART, or 0
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      s_valid <= 0;
      s_data  <= 0;
    end else begin
      if (out && s_ready) begin
        s_data  <= 8'h44;  // ASCII 'D' for "Detected"
        s_valid <= 1;
      end else begin
        s_valid <= 0;
      end
    end
  end

  // Toggles between non overlapping and overlapping mode

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      mode      <= 1'b0;
      mode_in_q <= 1'b1;  //on de0 nano buttons are pulled high when not pressed
    end else begin
      if (!mode_in && mode_in_q) begin  // falling edge detect
        mode <= ~mode;                  // toggle once per press
      end
		mode_in_q <= mode_in;              // register input
    end
  end

endmodule
