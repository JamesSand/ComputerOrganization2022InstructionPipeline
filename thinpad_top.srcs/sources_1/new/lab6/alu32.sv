module alu32(
input wire reset,
input wire  [31:0] alu_a,
input wire  [31:0] alu_b,
input wire  [ 3:0] alu_op,
output reg [31:0] alu_y_reg
);

always_comb begin
        case(alu_op)
        4'b0001: alu_y_reg = alu_a + alu_b;
        4'b0010: alu_y_reg = alu_a - alu_b;
        4'b0011: alu_y_reg = alu_a & alu_b;
        4'b0100: alu_y_reg = alu_a | alu_b;
        4'b0101: alu_y_reg = alu_a ^ alu_b;
        4'b0110: alu_y_reg = ~ alu_a;
        4'b0111: alu_y_reg = alu_a << (alu_b)%32;
        4'b1000: alu_y_reg = alu_a >> (alu_b)%32;
        
        4'b1011: begin//sbset
                alu_y_reg = alu_b%32;
                alu_y_reg = alu_a | (1<<alu_y_reg);
        end
        // begin code of szz
        4'b1100 : begin // sltu
                if (alu_a < alu_b) begin
                        // rs1 < rs2
                        alu_y_reg = 1'b1;
                end else begin
                        alu_y_reg = 1'b0;
                end
        end
        4'b1101 : begin // csrrs
                alu_y_reg = alu_a | alu_b;
        end
        4'b1110 : begin // csrrw
                alu_y_reg = alu_a & (~alu_b);
        end
        // end code of szz
        //szzsb
        
        // 4'b1001: begin
        //     alu_y_reg = alu_a >> (alu_b)%16;
        //     temp_reg = 17'h10000;
        //     temp_reg[16] = alu_a[15];
        //     temp_reg = temp_reg - (temp_reg >> (alu_b%16));
        //     alu_y_reg = alu_y_reg | temp_reg[15:0];
        // end
        // 4'b1010: alu_y_reg = (alu_a << (alu_b)%16) | (alu_a >> (16 - (alu_b)%16));
        4'b1001: begin//pcnt
        alu_y_reg=0;
        if(alu_a[0]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[1]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[2]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[3]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[4]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[5]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[6]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[7]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[8]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[9]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[10]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[11]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[12]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[13]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[14]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[15]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[16]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[17]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[18]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[19]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[20]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[21]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[22]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[23]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[24]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[25]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[26]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[27]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[28]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[29]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[30]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        if(alu_a[31]==1) begin alu_y_reg = alu_y_reg+1; end
        else begin alu_y_reg = alu_y_reg; end
        end


        4'b1010: begin//clz
        if (alu_a[31]==1) begin
                alu_y_reg = 0;
        end 
        else if (alu_a[30]==1) begin alu_y_reg = 1; end
        else if (alu_a[29]==1) begin alu_y_reg = 2; end
        else if (alu_a[28]==1) begin alu_y_reg = 3; end
        else if (alu_a[27]==1) begin alu_y_reg = 4; end
        else if (alu_a[26]==1) begin alu_y_reg = 5; end
        else if (alu_a[25]==1) begin alu_y_reg = 6; end
        else if (alu_a[24]==1) begin alu_y_reg = 7; end
        else if (alu_a[23]==1) begin alu_y_reg = 8; end
        else if (alu_a[22]==1) begin alu_y_reg = 9; end
        else if (alu_a[21]==1) begin alu_y_reg = 10; end
        else if (alu_a[20]==1) begin alu_y_reg = 11; end
        else if (alu_a[19]==1) begin alu_y_reg = 12; end
        else if (alu_a[18]==1) begin alu_y_reg = 13; end
        else if (alu_a[17]==1) begin alu_y_reg = 14; end
        else if (alu_a[16]==1) begin alu_y_reg = 15; end
        else if (alu_a[15]==1) begin alu_y_reg = 16; end
        else if (alu_a[14]==1) begin alu_y_reg = 17; end
        else if (alu_a[13]==1) begin alu_y_reg = 18; end
        else if (alu_a[12]==1) begin alu_y_reg = 19; end
        else if (alu_a[11]==1) begin alu_y_reg = 20; end
        else if (alu_a[10]==1) begin alu_y_reg = 21; end
        else if (alu_a[9]==1) begin alu_y_reg = 22; end
        else if (alu_a[8]==1) begin alu_y_reg = 23; end
        else if (alu_a[7]==1) begin alu_y_reg = 24; end
        else if (alu_a[6]==1) begin alu_y_reg = 25; end
        else if (alu_a[5]==1) begin alu_y_reg = 26; end
        else if (alu_a[4]==1) begin alu_y_reg = 27; end
        else if (alu_a[3]==1) begin alu_y_reg = 28; end
        else if (alu_a[2]==1) begin alu_y_reg = 29; end
        else if (alu_a[1]==1) begin alu_y_reg = 30; end
        else if (alu_a[0]==1) begin alu_y_reg = 31; end
        else begin
                alu_y_reg = 32;
        end
        end
        
        4'b1111: begin 
                case(alu_b[7:0])
                0: alu_y_reg[7:0] = alu_a[7:0];
                1: alu_y_reg[7:0] = alu_a[15:8];
                2: alu_y_reg[7:0] = alu_a[23:16];
                3: alu_y_reg[7:0] = alu_a[31:24];
                default: alu_y_reg[7:0] = 0;
                endcase

                case(alu_b[15:8])
                0: alu_y_reg[15:8] = alu_a[7:0];
                1: alu_y_reg[15:8] = alu_a[15:8];
                2: alu_y_reg[15:8] = alu_a[23:16];
                3: alu_y_reg[15:8] = alu_a[31:24];
                default: alu_y_reg[15:8] = 0;
                endcase

                case(alu_b[23:16])
                0: alu_y_reg[23:16] = alu_a[7:0];
                1: alu_y_reg[23:16] = alu_a[15:8];
                2: alu_y_reg[23:16] = alu_a[23:16];
                3: alu_y_reg[23:16] = alu_a[31:24];
                default: alu_y_reg[23:16] = 0;
                endcase

                case(alu_b[31:24])
                0: alu_y_reg[31:24] = alu_a[7:0];
                1: alu_y_reg[31:24] = alu_a[15:8];
                2: alu_y_reg[31:24] = alu_a[23:16];
                3: alu_y_reg[31:24] = alu_a[31:24];
                default: alu_y_reg[31:24] = 0;
                endcase
        end
        default: begin alu_y_reg = 32'b0;end
        endcase
end

endmodule
