`timescale 1ns/1ps

module tb_adder_32bit;

    // Testbench signals
    logic [31:0] num1, num2;
    logic        Cin;
    logic [31:0] sum;
    logic        Cout;

    // Instantiate DUT (Design Under Test)
    adder_32bit dut (
        .num1(num1),
        .num2(num2),
        .C_in(Cin),
        .sum(sum),
        .C_out(Cout)
    );

    // Test procedure
    initial begin
        // Monitor outputs continuously
        $monitor("Time=%0t | num1=%h | num2=%h | Cin=%b || sum=%h | Cout=%b",
                  $time, num1, num2, Cin, sum, Cout);

        // Test case 1: simple addition
        num1 = 32'h00000005;  // 5
        num2 = 32'h00000003;  // 3
        Cin  = 1'b0;
        #10;

        // Test case 2: addition with carry-in
        num1 = 32'h0000000A;  // 10
        num2 = 32'h00000001;  // 1
        Cin  = 1'b1;          // expect 12
        #10;

        // Test case 3: large numbers
        num1 = 32'hFFFFFFF0;  
        num2 = 32'h00000020;
        Cin  = 1'b0;          // expect 0x10 with carry-out
        #10;

        // Test case 4: overflow check
        num1 = 32'hFFFFFFFF;
        num2 = 32'h00000001;
        Cin  = 1'b0;          // expect sum=0, Cout=1
        #10;

        $finish;
    end

endmodule
