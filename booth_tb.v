`timescale 1ns / 1ps

module booth_tb;

    // Inputs
    reg [3:0] m;      // multiplicand
    reg [3:0] q;      // multiplier
    reg clk;
    reg rst;

    // Output
    wire [7:0] result;

    // Instantiate the Booth module
    booth uut (
        .m(m),
        .q(q),
        .result(result),
        .clk(clk),
        .rst(rst)
    );

    // Clock generation (10ns period => 100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        m = 4'b0000;
        q = 4'b0000;

        // Apply reset
        #10;
        rst = 0;

        // Test Case 1: 3 * 2
        m = 4'b0011;  // 3
        q = 4'b0010;  // 2
        rst = 1;
        #10 rst = 0;

        // Wait enough time for the Booth algorithm to finish (e.g., >40ns)
        #100;

        // Test Case 2: -3 * 2
        m = -4'd3;
        q = 4'd2;
        rst = 1;
        #10 rst = 0;
        #100;

        // Test Case 3: -4 * -3
        m = -4'd4;
        q = -4'd3;
        rst = 1;
        #10 rst = 0;
        #100;

        // Test Case 4: 0 * 5
        m = 4'd0;
        q = 4'd5;
        rst = 1;
        #10 rst = 0;
        #100;

        $finish;
    end

endmodule
