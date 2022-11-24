module csrfile32(
input wire clk,
input wire reset,
input wire[11:0] waddr,
input wire[31:0] wdata,
input wire we,
input wire[11:0] raddr_a,
output reg[31:0] rdata_a,
input wire[11:0] raddr_b,
output reg[31:0] rdata_b
);

endmodule