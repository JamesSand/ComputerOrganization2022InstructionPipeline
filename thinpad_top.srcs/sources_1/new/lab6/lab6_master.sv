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

`define TYPE_R 5'd12
`define TYPE_I 5'd13
`define TYPE_S 5'd14
`define TYPE_B 5'd15
`define TYPE_U 5'd16
`define TYPE_J 5'd17
module lab6_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    output reg [15:0] leds,
    input wire clk_i,
    input wire rst_i,

    // TODO: 添加�??要的控制信号，例如按键开关？
 
    // wishbone master内存，分为if和men两个
    output reg wb_cyc_o=0,
    output reg wb_stb_o=0,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o=0,

    // 连接 ALU 模块的信�??
    output reg  [31:0] alu_a,
    output reg  [31:0] alu_b,
    output reg  [ 3:0] alu_op,
    input  wire [31:0] alu_y,

    //连接寄存器堆信号
    output reg  [4:0]  rf_raddr_a,
    input  wire [31:0] rf_rdata_a,
    output reg  [4:0]  rf_raddr_b,
    input  wire [31:0] rf_rdata_b,
    output reg  [4:0]  rf_waddr,
    output reg  [31:0] rf_wdata,
    output reg  rf_we=0,

    //TODO: 写immgen的模�?
    output reg [31:0] imm_gen_o,
    output reg [4:0] imm_gen_type_o,
    input wire [31:0] imm_gen_i
);

  // TODO: 实现实验 5 的内�??+串口 Master
typedef enum logic [3:0] {
    STATE_INIT = 0,
    STATE_IF = 1,
    STATE_ID = 2,
    STATE_EXE = 3,
    STATE_MEM = 4,
    STATE_WB = 5
} state_t;

state_t state;

reg [31:0] pc_reg;
reg [31:0] pc_now_reg;
reg [31:0] inst_reg;
reg [31:0] op1_reg;
reg [31:0] op2_reg;
reg [31:0] rf_wb_reg;
reg [31:0] wb_adr_reg;
reg [31:0] wb_dat_reg;
reg [31:0] branch_adr_reg;

// initial begin


always_comb begin
  imm_gen_o = inst_reg;
  if (inst_reg[6:0] == 7'b0010011 
  || inst_reg[6:0] == 7'b0000011) begin
    imm_gen_type_o = `TYPE_I;
  end
  else if (inst_reg[6:0] == 7'b1100011) begin//beq
    imm_gen_type_o = `TYPE_B;
  end
  else if (inst_reg[6:0] == 7'b0110111) begin//lui
    imm_gen_type_o = `TYPE_U;
  end
  else if (inst_reg[6:0] == 7'b0100011) begin//sw sb
    imm_gen_type_o = `TYPE_S;
  end
  else begin
    imm_gen_type_o = 0;
  end
  rf_raddr_a = inst_reg[19:15];
  rf_raddr_b = inst_reg[24:20];
  leds[3:0] = state;
  leds[15] = rst_i;
end

always_comb begin 
  case(state)
    STATE_IF: begin
      wb_adr_o = pc_reg;
      wb_dat_o = 0;
      wb_stb_o = 1;//读取行为
      wb_cyc_o = 1;
      wb_sel_o = 4'b1111;
      wb_we_o = 0;
      alu_a = pc_reg;
      alu_b = 32'h00000004;
      alu_op = `ALU_OP_ADD;
      rf_we = 0;
      rf_wdata = 0;
      rf_waddr = 0;
    end
    STATE_ID: begin
      wb_adr_o = 0;
      wb_dat_o = 0;
      wb_stb_o = 0;//无关
      wb_cyc_o = 0;
      wb_sel_o = 4'b1111;
      wb_we_o = 0;
      if (inst_reg[6:0] == 7'b1100011) begin//beq
        alu_a = pc_now_reg;
        alu_b = imm_gen_i;
        alu_op = `ALU_OP_ADD;
      end
      else begin
      alu_a = 0;
      alu_b = 0;
      alu_op = `ALU_OP_ADD;
      end
      rf_we = 0;
      rf_wdata = 0;
      rf_waddr = 0;
    end
    STATE_EXE: begin
      wb_adr_o = 0;
      wb_dat_o = 0;
      wb_stb_o = 0;//无关
      wb_cyc_o = 0;
      wb_sel_o = 4'b1111;
      wb_we_o = 0;
      alu_a = op1_reg;
      alu_b = op2_reg;
      if (inst_reg[6:0] == 7'b0010011 && inst_reg[14:12] == 3'b000) begin//addi
        alu_op = `ALU_OP_ADD;
      end
      else if (inst_reg[6:0] == 7'b0010011 && inst_reg[14:12] == 3'b111) begin//andi
        alu_op = `ALU_OP_AND;
      end
      else if (inst_reg[6:0] == 7'b0110011) begin//add
        alu_op = `ALU_OP_ADD;
      end
      else if (inst_reg[6:0] == 7'b0000011) begin//lb
        alu_op = `ALU_OP_ADD;
      end
      else if (inst_reg[6:0] == 7'b0100011) begin//sb sw
        alu_op = `ALU_OP_ADD;
      end
      else if (inst_reg[6:0] == 7'b1100011) begin//beq
        alu_op = `ALU_OP_SUB;
      end
      else begin
        alu_op = `ALU_OP_ADD;
      end
      rf_we = 0;
      rf_wdata = 0;
      rf_waddr = 0;
      // branch_adr_reg = 0;
    end
    STATE_MEM: begin
      wb_adr_o = wb_adr_reg;
      wb_stb_o = 1;//无关
      wb_cyc_o = 1;
      if (inst_reg[6:0] == 7'b0000011) begin//lb
        wb_sel_o = 4'b0001;
        wb_we_o = 0;
        wb_dat_o = 0;
      end
      else if (inst_reg[6:0] == 7'b0100011) begin//sb sw
        wb_dat_o = wb_dat_reg;
        wb_we_o = 1;
        if (inst_reg[14:12] == 3'b000) begin //sb
          wb_sel_o = 4'b0001;
        end
        else begin //sw
          wb_sel_o = 4'b1111;
        end
      end
      else begin
        wb_dat_o = 0;
        wb_sel_o = 4'b1111;
        wb_we_o = 0;
      end
      alu_a = 0;
      alu_b = 0;
      alu_op = `ALU_OP_ADD;
      rf_we = 0;
      rf_wdata = 0;
      rf_waddr = 0;
      // branch_adr_reg = 0;
    end
    STATE_WB: begin
      wb_adr_o = 0;
      wb_dat_o = 0;
      wb_stb_o = 0;//无关
      wb_cyc_o = 0;
      wb_sel_o = 4'b1111;
      wb_we_o = 0;
      alu_a = 0;
      alu_b = 0;
      alu_op = `ALU_OP_ADD;
      if (inst_reg[6:0] == 7'b0100011) begin//sb sw
       rf_we = 0;
      rf_wdata = 0;
      rf_waddr = 0;
      end
      else begin
      rf_we = 1;
      rf_wdata = rf_wb_reg;
      rf_waddr = inst_reg[11:7];
      end
      // branch_adr_reg = 0;
    end
    default: begin
      wb_adr_o = 0;
      wb_dat_o = 0;
      wb_stb_o = 0;//读取行为
      wb_cyc_o = 0;
      wb_sel_o = 4'b1111;
      wb_we_o = 0;
      alu_a = 0;
      alu_b = 0;
      alu_op = 0;
      rf_we = 0;
      rf_wdata = 0;
      rf_waddr = 0;
      // branch_adr_reg = 0;
    end
  endcase
end


always_ff @ (posedge clk_i) begin
  if (rst_i) begin
    state <= STATE_IF;
    pc_reg <= 32'h80000000;
  end
  else begin
    case(state)
    STATE_INIT: begin
      state <= STATE_INIT;
    end 
    STATE_IF: begin
      inst_reg <= wb_dat_i;
      pc_now_reg <= pc_reg;
      if (wb_ack_i) begin
        pc_reg <= alu_y;
        state <= STATE_ID;
      end
    end
    STATE_ID: begin
      if (inst_reg[6:0] == 7'b0010011 
      || inst_reg[6:0] == 7'b0000011) begin//addi 与 andi 与lb 
        op1_reg <= rf_rdata_a;
        op2_reg <= imm_gen_i;
      end
      else if (inst_reg[6:0] == 7'b0100011) begin//sb sw
        op1_reg <= rf_rdata_a;
        op2_reg <= imm_gen_i;
        wb_dat_reg <= rf_rdata_b;
      end
      else if (inst_reg[6:0] == 7'b0110011) begin//add
        op1_reg <= rf_rdata_a;
        op2_reg <= rf_rdata_b;
      end
      else if (inst_reg[6:0] == 7'b0110111) begin //lui
        op1_reg <= 0;
        op2_reg <= 0;
      end
      else if (inst_reg[6:0] == 7'b1100011) begin//beq
        op1_reg <= rf_rdata_a;
        op2_reg <= rf_rdata_b;
        branch_adr_reg <= alu_y;
      end
      state <= STATE_EXE;
    end
    STATE_EXE: begin
      if (inst_reg[6:0] == 7'b0010011) begin//addi 与 andi
        rf_wb_reg <= alu_y;
        state <= STATE_WB;
      end
      else if (inst_reg[6:0] == 7'b0110011) begin//add
        rf_wb_reg <= alu_y;
        state <= STATE_WB;
      end
      else if (inst_reg[6:0] == 7'b0000011) begin//lb
        wb_adr_reg <= alu_y;
        state <= STATE_MEM;
      end
      else if (inst_reg[6:0] == 7'b0110111) begin //lui
        rf_wb_reg <= imm_gen_i;
        state <= STATE_WB;
      end
      else if (inst_reg[6:0] == 7'b0100011) begin // sb sw
        wb_adr_reg <= alu_y;
        state <= STATE_MEM;
      end
      else if (inst_reg[6:0] == 7'b1100011) begin//beq
        if (alu_y == 0) begin
          pc_reg <= branch_adr_reg;
        end
        state <= STATE_IF;
      end
      else begin
        state <= STATE_IF;//修改TODO:
      end
    end
    STATE_MEM: begin
      if (wb_ack_i) begin
        if (inst_reg[6:0] == 7'b0000011) begin//lb
          rf_wb_reg <= {{24{wb_dat_i[7]}},wb_dat_i[7:0]};
          state <= STATE_WB;
        end
        else begin
          state <= STATE_WB;
        end
      end
    end
    STATE_WB: begin
      state <= STATE_IF;
    end
    endcase
  end
end
endmodule
