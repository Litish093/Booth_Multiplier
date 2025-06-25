`timescale 1ns / 1ps

module accumulator(lda, clk, shfta, clra, z, a);
parameter N=8;
input lda, clk, shfta, clra;
input [N-1:0] z;
output reg [N-1:0] a;
always @(posedge clk)
begin
    if(clra) a <= 0;
    else if(lda) a <= z;
    else if(shfta) a <= {a[N-1], a[N-1:1]};
end
endmodule

module multiplier(clk, ldq, data_in, shftq, clrq, prev, q);
parameter N=8;
input clk, ldq, shftq, clrq, prev;
input [N-1:0] data_in;
output reg [N-1:0] q;
always @(posedge clk)
begin
    if(clrq) q <= 0;
    else if(ldq) q <= data_in;
    else if(shftq) q <= {prev, q[N-1:1]};
end
endmodule

module store(shftff, clk, clrff, prev, qm1);
input shftff, clk, clrff, prev;
output reg qm1;
always @(posedge clk)
begin
    if(clrff) qm1 <= 0;
    else if(shftff) qm1 <= prev;
end
endmodule

module ALU(a, m, addsub, z);
parameter N=8;
input [N-1:0] a, m;
input addsub;
output reg [N-1:0] z;
always @(*)
begin
    if(addsub) z = a + m;
    else z = a - m;
end
endmodule

module multiplicand(ldm, clk, data_in, m);
parameter N=8;
input ldm, clk;
input [N-1:0] data_in;
output reg [N-1:0] m;
always @(posedge clk)
begin
    if(ldm) m <= data_in;
end
endmodule

module counter(clk, decr, ldcount, count);
parameter N=8;
parameter alpha=3;
input clk, decr, ldcount;
output reg [alpha:0] count;
always @(posedge clk)
begin
    if(ldcount) count <= N;
    else if(decr) count <= count - 1;
end
endmodule

module comparator(q0, qm1, value);
input q0, qm1;
output reg [1:0] value;
always @(*)
begin
    value = {q0, qm1};
end
endmodule

module finalans(a, q, ans);
parameter N=8;
input [N-1:0] a, q;
output reg [(2*N)-1:0] ans;
always @(*)
begin
    ans = {a, q};
end
endmodule

module datapath(
    input clk,
    input clra, lda, shfta,
    input ldq, shftq, clrq,
    input shftff, clrff,
    input addsub,
    input ldm,
    input ldcount, decr,
    input [7:0] data_in,
    output [15:0] ans,
    output [3:0] count,
    output [1:0] value,
    output [7:0] a, q,
    output qm1
);
parameter N=8;
parameter alpha=3;

wire [N-1:0] z, m;

accumulator acc(
    .lda(lda),
    .clk(clk),
    .shfta(shfta),
    .clra(clra),
    .z(z),
    .a(a)
);

multiplier mult(
    .clk(clk),
    .ldq(ldq),
    .data_in(data_in),
    .shftq(shftq),
    .clrq(clrq),
    .prev(a[0]),
    .q(q)
);

store str(
    .shftff(shftff),
    .clk(clk),
    .clrff(clrff),
    .prev(q[0]),
    .qm1(qm1)
);

ALU alu(
    .a(a),
    .m(m),
    .addsub(addsub),
    .z(z)
);

multiplicand mut(
    .ldm(ldm),
    .clk(clk),
    .data_in(data_in),
    .m(m)
);

counter cnt(
    .clk(clk),
    .decr(decr),
    .ldcount(ldcount),
    .count(count)
);

comparator co(
    .q0(q[0]),
    .qm1(qm1),
    .value(value)
);

finalans result(
    .a(a),
    .q(q),
    .ans(ans)
);
endmodule

module controlpath(
    input clk,
    input start,
    input [3:0] count,
    input [1:0] value,
    output reg clra, lda, shfta,
    output reg ldq, shftq, clrq,
    output reg shftff, clrff,
    output reg addsub,
    output reg ldm,
    output reg ldcount, decr,
    output reg done
);
parameter s0=0, s1=1, s2=2, s3=3, s4=4, s5=5, s6=6, s7=7;
reg [2:0] state;

always @(posedge clk)
begin
    case(state)
        s0: if(start) state <= s1;
        s1: state <= s2;
        s2: state <= s3;
        s3: case(value)
                2'b01: state <= s4;
                2'b10: state <= s5;
                default: state <= s6;
            endcase
        s4: state <= s7;
        s5: state <= s7;
        s6: if(count == 0) state <= s0; else state <= s3;
        s7: state <= s6;
        default: state <= s0;
    endcase
end

always @(state)
begin
    {clra, lda, shfta, ldq, shftq, clrq, shftff, clrff, addsub, ldm, ldcount, decr, done} = 0;
    
    case(state)
        s0: begin
            clra = 1;
            clrq = 1;
            clrff = 1;
        end
        
        s1: begin
            ldm = 1;
            ldcount = 1;
        end
        
        s2: begin
            ldq = 1;
        end
        
        s3: begin
            // Decision state only
        end
        
        s4: begin
            addsub = 1; // Add operation
        end
        
        s5: begin
            addsub = 0; // Subtract operation
        end
        
        s6: begin
            shfta = 1;
            shftq = 1;
            shftff = 1;
            decr = 1;
        end
        
        s7: begin
            lda = 1; // Load ALU result
        end
        
        default: begin
            clra = 1;
            clrq = 1;
            clrff = 1;
        end
    endcase
end
endmodule

module clock_divider_10KHz(input clk_100MHz, reset, output reg clk_10KHz);
parameter value = 4999;
integer count = 0;
always @(posedge clk_100MHz)
begin
    if(reset) begin
        count <= 0;
        clk_10KHz <= 0;
    end
    else if(count == value) begin
        clk_10KHz <= ~clk_10KHz;
        count <= 0;
    end
    else begin
        count <= count + 1;
    end
end
endmodule

module booth_multiplier(
    input start,
    input clk_100MHz,
    input [7:0] data_in,
    output done,
    output [15:0] ans
);
wire clk_10KHz;
wire clra, lda, shfta;
wire ldq, shftq, clrq;
wire shftff, clrff;
wire addsub;
wire ldm;
wire ldcount, decr;
wire [3:0] count;
wire [1:0] value;
wire [7:0] a, q;
wire qm1;
wire reset = 0;

clock_divider_10KHz clk_div(
    .clk_100MHz(clk_100MHz),
    .reset(reset),
    .clk_10KHz(clk_10KHz)
);

datapath dp(
    .clk(clk_10KHz),
    .clra(clra),
    .lda(lda),
    .shfta(shfta),
    .ldq(ldq),
    .shftq(shftq),
    .clrq(clrq),
    .shftff(shftff),
    .clrff(clrff),
    .addsub(addsub),
    .ldm(ldm),
    .ldcount(ldcount),
    .decr(decr),
    .data_in(data_in),
    .ans(ans),
    .count(count),
    .value(value),
    .a(a),
    .q(q),
    .qm1(qm1)
);

controlpath cp(
    .clk(clk_10KHz),
    .start(start),
    .count(count),
    .value(value),
    .clra(clra),
    .lda(lda),
    .shfta(shfta),
    .ldq(ldq),
    .shftq(shftq),
    .clrq(clrq),
    .shftff(shftff),
    .clrff(clrff),
    .addsub(addsub),
    .ldm(ldm),
    .ldcount(ldcount),
    .decr(decr),
    .done(done)
);
endmodule