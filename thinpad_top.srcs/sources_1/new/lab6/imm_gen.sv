`define TYPE_R 5'd16
`define TYPE_I 5'd17
`define TYPE_S 5'd18
`define TYPE_B 5'd19
`define TYPE_U 5'd20
`define TYPE_J 5'd21
`define TYPE_CSR 5'd22

module imm_gen(
    input wire [31:0] imm_gen_i,
    input wire [4:0] imm_gen_type_i,
    output reg [31:0] imm_gen_o
);

always_comb begin
    imm_gen_o = 0;
    casez(imm_gen_type_i)
    `TYPE_I: begin
        imm_gen_o = {{20{imm_gen_i[31]}},imm_gen_i[31:20]};
    end
    `TYPE_U: begin 
        imm_gen_o[31:12] = imm_gen_i[31:12];
    end
    `TYPE_B: begin
        imm_gen_o[31:1] = {{19{imm_gen_i[31]}},imm_gen_i[31],imm_gen_i[7],imm_gen_i[30:25],imm_gen_i[11:8]};
    end
    `TYPE_S: begin
        imm_gen_o = {{20{imm_gen_i[31]}},imm_gen_i[31:25],imm_gen_i[11:7]};
    end
    `TYPE_J: begin
        imm_gen_o[31:1] = {{11{imm_gen_i[31]}},imm_gen_i[31],imm_gen_i[19:12], imm_gen_i[20], imm_gen_i[30:21]};
    end

    `TYPE_CSR: begin
        // csr instruction has only 5 bits
        imm_gen_o[4:0] = imm_gen_i[19:15]; // imm_gen_ 19:16 stands for uimm (rs1)
    end

    default: imm_gen_o = 0;
    endcase
end


endmodule