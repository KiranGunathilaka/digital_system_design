`timescale 1ns / 1ps

module tb_overlapping_sequence_detector_0110;
    reg clk;
    reg reset;
    reg data_in;
    wire detected;
    
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns period
    
    overlapping_sequence_detector_0110 dut (
        .clk(clk),
        .reset(reset),
        .en(1'b1), // always one for the testbench
        .data_in(data_in),
        .detected(detected)
    );
    
    // Function to convert state enum to string
    function [39:0] state_to_string;  // 5 characters * 8 bits = 40 bits
        input [2:0] state;
        begin
            case (state)
                3'b000: state_to_string = "IDLE ";
                3'b001: state_to_string = "S0   ";
                3'b010: state_to_string = "S01  ";
                3'b011: state_to_string = "S011 ";
                3'b100: state_to_string = "S0110";
                default: state_to_string = "UNKN ";
            endcase
        end
    endfunction
    
    // Test sequence with automatic termination
    initial begin
        
        // Initialize
        reset = 1;
        data_in = 0;
        
        // Short reset period
        #20;
        reset = 0;
        #10;
        
        // Test case 1: Simple 0110 sequence
        $display("\n=== Test 1: Simple 0110 sequence ===");
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(0);
        check_detection(1, "Simple 0110");
        
        // Test case 2: Overlapping behavior
        $display("\n=== Test 2: Overlapping - Overlapped with old sequence ===");
        send_bit(1);
        send_bit(1);
        send_bit(0);
		  check_detection(1, "Overlapping 0110");
        send_bit(1);
        send_bit(1);
        send_bit(0);
        check_detection(1, "Overlapping 0110");
        
        // Test case 3: Partial sequence then restart
        $display("\n=== Test 3: Partial sequence 011 then 0110 ===");
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(1); // Wrong bit
		  check_detection(0, "Should not detect now");
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(0);
        check_detection(1, "Restart after wrong bit");
        
        // Test case 4: Multiple 0s
        $display("\n=== Test 4: Multiple 0s then 0110 ===");
        send_bit(0);
        send_bit(0);
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(0);
        check_detection(1, "Multiple 0s then 0110");
        
        // Test case 5: No detection case
        $display("\n=== Test 5: No detection - 0111 ===");
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(1); // Should not detect
        check_detection(0, "No detection for 0111");
        
        #20;
        
        $finish;
    end
    
    task send_bit;
        input bit_val;
        begin
            @(negedge clk);
				#3
            data_in = bit_val;
            #1; // Small delay to let combinational logic settle
        end
    endtask
    
    task check_detection;
        input expected;
        input [200*8-1:0] test_name;
        begin
            @(posedge clk);
            #1; // Small delay for logic to settle
            if (detected == expected) begin
                $display("PASS: %s - Expected: %b, Got: %b", test_name, expected, detected);
            end else begin
                $display("FAIL: %s - Expected: %b, Got: %b", test_name, expected, detected);
            end
        end
    endtask
    
    // For terminating if simulation runs too long
    initial begin
        #10000; // 10 microseconds timeout
        $display("ERROR: Simulation timeout! Terminating...");
        $finish;
    end

endmodule