module alu32(
input wire reset,
input wire  [31:0] alu_a,
input wire  [31:0] alu_b,
input wire  [ 3:0] alu_op,
output reg [31:0] alu_y_reg
);
reg [31:0] temp_reg;
always_comb begin
        casez(alu_op)
        4'b0001: alu_y_reg = alu_a + alu_b;
        4'b0010: alu_y_reg = alu_a - alu_b;
        4'b0011: alu_y_reg = alu_a & alu_b;
        4'b0100: alu_y_reg = alu_a | alu_b;
        4'b0101: alu_y_reg = alu_a ^ alu_b;
        4'b0110: alu_y_reg = ~ alu_a;
        4'b0111: alu_y_reg = alu_a << (alu_b)%32;
        4'b1000: alu_y_reg = alu_a >> (alu_b)%32;
        // 4'b1001: begin
        //     alu_y_reg = alu_a >> (alu_b)%16;
        //     temp_reg = 17'h10000;
        //     temp_reg[16] = alu_a[15];
        //     temp_reg = temp_reg - (temp_reg >> (alu_b%16));
        //     alu_y_reg = alu_y_reg | temp_reg[15:0];
        // end
        // 4'b1010: alu_y_reg = (alu_a << (alu_b)%16) | (alu_a >> (16 - (alu_b)%16));
        default: alu_y_reg = 32'b0;
        endcase
end

endmodule
