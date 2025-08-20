`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/14/2025 12:38:14 PM
// Design Name: 
// Module Name: sequence_detector_0110
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Non-overlapping sequence detector for pattern "0110"
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sequence_detector_0110(
    input logic clk,
    input logic reset,
    input logic data_in,
    output logic detected
);

    // State enumeration
    typedef enum logic [2:0] {
        IDLE  = 3'b000,   // Initial state or after detection/wrong sequence
        S0    = 3'b001,   // Received first '0'
        S01   = 3'b010,   // Received "01"
        S011  = 3'b011,   // Received "011"
        S0110 = 3'b100    // Received "0110" - sequence detected
    } state_t;
    
    state_t current_state, next_state;
    
    // State register
    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (data_in == 1'b0) begin
                    next_state = S0;
                end else begin
                    next_state = IDLE;
                end
            end
            
            S0: begin
                if (data_in == 1'b1) begin
                    next_state = S01;
                end else begin
                    next_state = S0;  // Stay in S0 for consecutive 0s
                end
            end
            
            S01: begin
                if (data_in == 1'b1) begin
                    next_state = S011;
                end else begin
                    next_state = S0;  // Start over with new 0
                end
            end
            
            S011: begin
                if (data_in == 1'b0) begin
                    next_state = S0110;  // Sequence detected
                end else begin
                    next_state = IDLE;  // Wrong bit, go to idle
                end
            end
            
            S0110: begin
                // Non-overlapping: go to IDLE after detection
                // Next bit determines next state
                if (data_in == 1'b0) begin
                    next_state = S0;
                end else begin
                    next_state = IDLE;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Output logic
    always_comb begin
        detected = (current_state == S0110);
    end

endmodule