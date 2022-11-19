module regfile(
input wire clk,
input wire reset,
input wire[4:0] waddr,
input wire[15:0] wdata,
input wire we,
input wire[4:0] raddr_a,
output reg[15:0] rdata_a,
input wire[4:0] raddr_b,
output reg[15:0] rdata_b
);

reg [31:0] regfile_reg[0:31];
integer i;
always_ff @ (posedge clk or posedge reset) begin
regfile_reg[0] <= 16'b0;
if (reset) begin
for(i=0;i<32;i++) begin
regfile_reg[i] <= 16'b0;
end
end
else if (we && waddr != 5'b00000) begin
regfile_reg[waddr] <= wdata;
end
end


always_comb begin
rdata_a <= regfile_reg[raddr_a];
end

always_comb begin
rdata_b <= regfile_reg[raddr_b];
end

endmodule