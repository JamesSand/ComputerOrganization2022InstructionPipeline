module alu32(
input wire reset,
input wire  [31:0] alu_a,
input wire  [31:0] alu_b,
input wire  [ 3:0] alu_op,
output reg [31:0] alu_y_reg
);

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

        // begin code of szz
        4'b1100 : begin // sltu
                // // alu_a rs1, alu_b rs2, give back 1 if alu_b greater, 0 if alu_b less
                // if ((alu_a[31] == 1'b0) && (alu_b[31] == 1'b0))begin
                //         // rs1 positive, rs2 negative, return 0
                        
                // end else if ((alu_a[31] == 1'b1) && (alu_b[31] == 1'b0))begin
                //         // rs1 negative, 
                        
                // end else if ((alu_a[31] == 1'b1) && (alu_b[31] == 1'b0)) begin
                        
                // end else if ((alu_a[31] == 1'b1) && (alu_b[31] == 1'b0)) begin
                        
                // end else begin
                        
                // end

                if (alu_a < alu_b) begin
                        // rs1 < rs2
                        alu_y_reg = 1'b1;
                end else begin
                        alu_y_reg = 1'b0;
                end
                
        end
        // end code of szz

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
