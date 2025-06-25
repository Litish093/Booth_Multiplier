`timescale 1ns / 1ps

module tb_booth_multiplier();
reg start, clk_100MHz;
reg [7:0] data_in;
wire done;
wire [15:0] ans;

booth_multiplier uut(
    .start(start),
    .clk_100MHz(clk_100MHz),
    .data_in(data_in),
    .done(done),
    .ans(ans)
);

initial begin
    clk_100MHz = 0;
    forever #5 clk_100MHz = ~clk_100MHz;
end

initial begin
    start = 0;
    data_in = 0;
    #100;
    
    // Test 1: 5 * 3 = 15
    // Load multiplicand (5)
    data_in = 5;
    start = 1;
    #10;
    start = 0;
    #1000;
    
    // Load multiplier (3)
    data_in = 3;
    #1000;
    
    // Wait for completion
    wait(done);
    #100;
    
    // Test 2: -5 * 3 = -15
    data_in = -5;
    start = 1;
    #10;
    start = 0;
    #1000;
    
    data_in = 3;
    #1000;
    wait(done);
    #100;
    
    // Test 3: 5 * -3 = -15
    data_in = 5;
    start = 1;
    #10;
    start = 0;
    #1000;
    
    data_in = -3;
    #1000;
    wait(done);
    #100;
    
    // Test 4: -5 * -3 = 15
    data_in = -5;
    start = 1;
    #10;
    start = 0;
    #1000;
    
    data_in = -3;
    #1000;
    wait(done);
    #100;
    
    // Test 5: Max values 127 * 127 = 16129
    data_in = 127;
    start = 1;
    #10;
    start = 0;
    #1000;
    
    data_in = 127;
    #1000;
    wait(done);
    #100;
    
    $finish;
end
endmodule