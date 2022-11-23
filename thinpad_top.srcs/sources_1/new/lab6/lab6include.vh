`define ALU_OP_BITS        4 

`define ALU_OP_ADD         4'd1
`define ALU_OP_SUB         4'd2
`define ALU_OP_AND         4'd3
`define ALU_OP_OR          4'd4
`define ALU_OP_XOR         4'd5
`define ALU_OP_NOT         4'd6
`define ALU_OP_SLL         4'd7
`define ALU_OP_SRL         4'd8
`define ALU_OP_SRA         4'd9
`define ALU_OP_ROL         4'd10
`define ALU_OP_SETB        4'd11 //for lui
`define ALU_OP_SLTU        4'd12 // for sltu

`define TYPE_R 5'd12
`define TYPE_I 5'd13
`define TYPE_S 5'd14
`define TYPE_B 5'd15
`define TYPE_U 5'd16
`define TYPE_J 5'd17