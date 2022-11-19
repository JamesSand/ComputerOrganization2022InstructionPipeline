module controller (
    input wire clk,
    input wire reset,

    // 连接寄存器堆模块的信�?
    output reg  [4:0]  rf_raddr_a,
    input  wire [15:0] rf_rdata_a,
    output reg  [4:0]  rf_raddr_b,
    input  wire [15:0] rf_rdata_b,
    output reg  [4:0]  rf_waddr,
    output reg  [15:0] rf_wdata,
    output reg  rf_we,

    // 连接 ALU 模块的信�?
    output reg  [15:0] alu_a,
    output reg  [15:0] alu_b,
    output reg  [ 3:0] alu_op,
    input  wire [15:0] alu_y,

    // 控制信号
    input  wire        step,    // 用户按键状�?�脉�?
    input  wire [31:0] dip_sw,  // 32 位拨码开关状�?
    output reg  [15:0] leds
);
    
  logic [31:0] inst_reg;  // 指令寄存�?

  // 组合逻辑，解析指令中的常用部分，依赖于有效的 inst_reg �?
  logic is_rtype, is_itype, is_peek, is_poke;
  logic [15:0] imm;
  logic [4:0] rd, rs1, rs2;
  logic [3:0] opcode;

  always_comb begin
    is_rtype = (inst_reg[2:0] == 3'b001);
    is_itype = (inst_reg[2:0] == 3'b010);
    is_peek = is_itype && (inst_reg[6:3] == 4'b0010);
    is_poke = is_itype && (inst_reg[6:3] == 4'b0001);

    imm = inst_reg[31:16];
    rd = inst_reg[11:7];
    rs1 = inst_reg[19:15];
    rs2 = inst_reg[24:20];
    opcode = inst_reg[6:3];

    alu_a = rf_rdata_a;
    alu_b = rf_rdata_b;
    alu_op = opcode;

    rf_waddr = rd;
    rf_wdata = inst_reg[31:16];
  end

  // 使用枚举定义状�?�列表，数据类型�? logic [3:0]
  typedef enum logic [3:0] {
    ST_INIT,
    ST_DECODE,
    ST_CALC,
    ST_READ_REG,
    ST_WRITE_REG,
    ST_POST_WRITE1,
    ST_POST_WRITE2,
    ST_POST_WRITE3
  } state_t;

  // 状�?�机当前状�?�寄存器
  state_t state;

  // 状�?�机逻辑
  always_ff @(posedge clk) begin
    if (reset) begin
      // TODO: 复位各个输出信号
      inst_reg <= 32'b0;
      state <= ST_INIT;
      rf_raddr_a <= 5'b0;
      rf_raddr_b <= 5'b0;
      //rf_waddr <= 5'b0;
      //rf_wdata <= 16'b0;
      rf_we <= 1'b0;
      //alu_a <= 16'b0;
      //alu_b <= 16'b0;
      //alu_op <= 4'b0;
      leds <= 16'b0;
    end else begin
      case (state)
        ST_INIT: begin
            rf_we <= 1'b0;
          if (step) begin
            inst_reg <= dip_sw;
            state <= ST_DECODE;
          end
        end

        ST_DECODE: begin
          if (is_rtype) begin
            // 把寄存器地址交给寄存器堆，读取操作数
            rf_raddr_a <= rs1;
            rf_raddr_b <= rs2;
            state <= ST_CALC;
          end else if (is_itype) begin
            // TODO: 其他指令的处�?
            if (is_peek) begin
                state <= ST_READ_REG;
                rf_raddr_a <= rd;
            end
            else if (is_poke) begin
                state <= ST_WRITE_REG;
            end
            else begin
                state <= ST_INIT;
            end
          end else begin
            // 未知指令，回到初始状�?
            state <= ST_INIT;
          end
        end

        

        ST_CALC: begin
         //TODO: 区分时序，如何确认自己得到的ALU结果是对的时序，没有延时
          // TODO: 将数据交�? ALU，并�? ALU 获取结果
          inst_reg[31:16] <= alu_y;
          state <= ST_WRITE_REG;
          
        end


        ST_POST_WRITE1: begin
          state <= ST_POST_WRITE2;
        end

        ST_POST_WRITE2: begin
          state <= ST_POST_WRITE3;
          rf_we <= 1'b0;
        end

        ST_POST_WRITE1: begin
          state <= ST_INIT;
        end

        ST_WRITE_REG: begin
          // TODO: 将结果存入寄存器
          rf_we <= 1'b1;
          state <= ST_INIT;
        end

        

        ST_READ_REG: begin
          // TODO: 将数据从寄存器中读出，存�? leds
          state <= ST_INIT;
          leds <= rf_rdata_a;
        end

        default: begin
          state <= ST_INIT;
        end
      endcase
    end
  end
endmodule