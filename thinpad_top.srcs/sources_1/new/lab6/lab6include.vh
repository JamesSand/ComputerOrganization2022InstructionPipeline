`define ALU_OP_BITS        4 

`define ALU_OP_ADD         4'd1
`define ALU_OP_SUB         4'd2
`define ALU_OP_AND         4'd3
`define ALU_OP_OR          4'd4
`define ALU_OP_XOR         4'd5
`define ALU_OP_NOT         4'd6
`define ALU_OP_SLL         4'd7
`define ALU_OP_SRL         4'd8
`define ALU_OP_PCNT         4'd9
`define ALU_OP_CLZ        4'd10
`define ALU_OP_SBSET        4'd11 //for sbset
`define ALU_OP_SLTU        4'd12 // for sltu
`define ALU_OP_CSRS        4'd13 // for csrrs
`define ALU_OP_CSRC        4'd14 // for csrrc
`define ALU_OP_XP 4'd15 // for xperm8



`define TYPE_R 5'd16
`define TYPE_I 5'd17
`define TYPE_S 5'd18
`define TYPE_B 5'd19
`define TYPE_U 5'd20
`define TYPE_J 5'd21
`define TYPE_CSR 5'd22
