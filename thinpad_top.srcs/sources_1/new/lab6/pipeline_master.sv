

`include "lab6include.vh"

module pipeline_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    output reg [15:0] leds,
    input wire clk_i,
    input wire rst_i,

 
    //if wishbone master内存�???????????
    output reg if_wb_cyc_o=0,
    output reg if_wb_stb_o=0,
    input wire if_wb_ack_i,
    output reg [ADDR_WIDTH-1:0] if_wb_adr_o,
    output reg [DATA_WIDTH-1:0] if_wb_dat_o,
    input wire [DATA_WIDTH-1:0] if_wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] if_wb_sel_o,
    output reg if_wb_we_o=0,

    //mem wishbone master内存�???????????
    output reg mem_wb_cyc_o=0,
    output reg mem_wb_stb_o=0,
    input wire mem_wb_ack_i,
    output reg [ADDR_WIDTH-1:0] mem_wb_adr_o,
    output reg [DATA_WIDTH-1:0] mem_wb_dat_o,
    input wire [DATA_WIDTH-1:0] mem_wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] mem_wb_sel_o,
    output reg mem_wb_we_o=0,

    // 连接 ALU 模块的信�???????????
    output reg  [31:0] alu_a,
    output reg  [31:0] alu_b,
    output reg  [ 3:0] alu_op,
    input  wire [31:0] alu_y,

    //if 阶段 PC+4 连接 ALU 模块的信�???????????
    output reg  [31:0] if_alu_a,
    output reg  [31:0] if_alu_b,
    output reg  [ 3:0] if_alu_op,
    input  wire [31:0] if_alu_y,

    //连接寄存器堆信号
    output reg  [4:0]  rf_raddr_a,
    input  wire [31:0] rf_rdata_a,
    output reg  [4:0]  rf_raddr_b,
    input  wire [31:0] rf_rdata_b,
    output reg  [4:0]  rf_waddr,
    output reg  [31:0] rf_wdata,
    output reg  rf_we=0,

    //: 写immgen的模�???????????
    output reg [31:0] imm_gen_o,
    output reg [4:0] imm_gen_type_o,
    input wire [31:0] imm_gen_i,

    // csr reg file
    output reg  [11:0]  csr_raddr_a,
    input  wire [31:0] csr_rdata_a,
    output reg  [11:0]  csr_raddr_b,
    input  wire [31:0] csr_rdata_b,
    output reg  [11:0]  csr_waddr,
    output reg  [31:0] csr_wdata,
    output reg  csr_we=0,
    output reg  [11:0]  csr_waddr_exp,
    output reg  [31:0] csr_wdata_exp,
    output reg  csr_we_exp=0,

    // mtime
    input  wire mtime_exceed_i
);

// state_if 生成的信�???????????
reg if_stall_i,if_stall_o,if_flush_i,if_flush_o;
reg [31:0]  if_id_id_pc_now_reg;
reg [31:0]  if_pc_reg;
reg [31:0]  if_id_id_inst_reg;

// state_id 生成的信�???????????
reg id_stall_i,id_stall_o,id_flush_i,id_flush_o;
reg [31:0]  id_exe_if_branch_addr_reg;
reg id_exe_if_branch_reg;
reg id_exe_id_branchequ;
reg id_exe_exe_isjump_reg;

reg [31:0]  id_exe_exe_alu_a_reg;
reg [31:0]  id_exe_exe_alu_b_reg;
reg [3:0]   id_exe_exe_alu_op_reg;

reg have_rs1,have_rs2;

reg         id_exe_mem_wb_cyc_reg;
reg         id_exe_mem_wb_stb_reg;
reg         id_exe_mem_wb_we_reg;
reg [3:0]   id_exe_mem_wb_sel_reg;
reg [31:0]  id_exe_mem_wb_dat_reg;
reg id_exe_mem_load_reg,id_exe_mem_store_reg;

reg id_exe_wb_rf_we_reg;
reg [4:0]   id_exe_wb_rf_waddr_reg;
reg [31:0]  id_exe_wb_rf_wdata_reg;
reg id_exe_exe_rfstorealuy_reg; // 在wb阶段寄存器是否存alu计算结果

reg [4:0] id_exe_rd_reg;

// for csr
reg id_exe_wb_csr_we_reg;
reg [11:0]   id_exe_wb_csr_waddr_reg;
reg [31:0]  id_exe_wb_csr_wdata_reg; 
reg id_exe_exe_csrstorealuy_reg;

reg id_exe_exe_exceptionoccur_reg;
reg [31:0] id_exe_exe_exception_pc_reg;
reg [31:0] id_exe_exe_exception_mcause_reg;


// state_exe 生成的信�???????????
reg exe_stall_i,exe_stall_o,exe_flush_i,exe_flush_o;
reg [31:0]  exe_if_if_branch_addr_reg;
reg exe_if_if_branch_successornot_reg,exe_if_if_branch_compcompute;

reg         exe_mem_mem_wb_cyc_reg;
reg         exe_mem_mem_wb_stb_reg;
reg         exe_mem_mem_wb_we_reg;
reg [3:0]   exe_mem_mem_wb_sel_reg;
reg [31:0]  exe_mem_mem_wb_dat_reg,exe_mem_mem_wb_adr_reg;
reg exe_mem_mem_load_reg,exe_mem_mem_store_reg;

reg [31:0] exe_mem_wb_rf_wdata_reg;
reg [4:0] exe_mem_wb_rf_waddr_reg;
reg exe_mem_wb_rf_we_reg;

reg [4:0] exe_mem_rd_reg;

// for csr
reg [31:0] exe_mem_wb_csr_wdata_reg;
reg [11:0] exe_mem_wb_csr_waddr_reg;
reg exe_mem_wb_csr_we_reg;

reg [2:0] mode_reg;//00U,11M
reg exe_exceptionprocessup_reg;
reg [31:0] exe_exception_pc_reg;
reg [31:0] exe_exception_mcause_reg;

//mem
reg mem_stall_i,mem_stall_o,mem_flush_i,mem_flush_o;
reg [31:0] mem_wb_wb_rf_wdata_start_reg;
reg [4:0] mem_wb_wb_rf_waddr_start_reg;
reg mem_wb_wb_rf_we_start_reg;
reg [31:0] mem_wb_wb_rf_wdata_ack_reg;
reg [4:0] mem_wb_wb_rf_waddr_ack_reg;
reg mem_wb_wb_rf_we_ack_reg;

reg [4:0] mem_wb_rd_ack_reg;
reg [4:0] mem_wb_rd_start_reg;

// for csr
reg [31:0] mem_wb_wb_csr_wdata_reg;
reg [11:0] mem_wb_wb_csr_waddr_reg;
reg mem_wb_wb_csr_we_reg;


//信号和always执行逻辑的分割线


// state_if
always_ff @ (posedge clk_i) begin
    if (rst_i) begin
        if_pc_reg <= 32'h80000000;
        if_id_id_pc_now_reg <= 32'h80000000;
        if_id_id_inst_reg <= 0;
        if_wb_stb_o <= 1'b0;
        if_wb_cyc_o <= 1'b0;
        if_wb_we_o <= 0;
    end else if (if_stall_i) begin
        //if_wb_stb_o <= 1'b0;
        //if_wb_cyc_o <= 1'b0;
        if (exe_if_if_branch_compcompute) begin
            if_id_id_inst_reg <= 0;
            if (exe_if_if_branch_successornot_reg) begin
                if_pc_reg <= exe_if_if_branch_addr_reg;
            end
        end
    end else if (if_flush_i) begin
        //if_pc_reg <= 32'h80000000;
        //if_id_id_pc_now_reg <= 32'h80000000;
        if_id_id_inst_reg <= 0;
        //if_wb_stb_o <= 1'b0;
        //if_wb_cyc_o <= 1'b0;
    end else begin
        if_id_id_pc_now_reg <= if_pc_reg;
        if (if_wb_ack_i) begin//多周期读�?
            if_id_id_inst_reg <= if_wb_dat_i;
            if_pc_reg <= if_alu_y;//branch
            if_wb_stb_o <= 1'b0;
            if_wb_cyc_o <= 1'b0;
            if_wb_we_o <= 0;
        end
        else begin//if constantly read
            if_wb_stb_o <= 1'b1;
            if_wb_cyc_o <= 1'b1;
            if_wb_we_o <= 0;
            if_id_id_inst_reg <= 0;
        end
    end
end
always_comb begin
    if_stall_o = if_wb_stb_o;

    if_wb_adr_o = if_pc_reg;
    if_wb_sel_o = 4'b1111;
    if (if_id_id_inst_reg[6:0] == 7'b1100011 || if_id_id_inst_reg[6:0] == 7'b1101111) begin // beq bne jal
        if_alu_a = if_id_id_pc_now_reg;
        if_alu_b = imm_gen_i;
        if_alu_op = `ALU_OP_ADD;
        if_flush_o = 1;
    end else if (if_id_id_inst_reg[6:0] == 7'b1100111) begin // jalr
        if_alu_a = rf_rdata_a;
        if_alu_b = imm_gen_i;
        if_alu_op = `ALU_OP_ADD;
        if_flush_o = 1;
    end else begin
        if_alu_a = if_pc_reg;
        if_alu_b = 32'h0000_0004;
        if_alu_op =`ALU_OP_ADD;
        if_flush_o = 0;
    end
end


// state_id
always_ff @ (posedge clk_i) begin
    if (rst_i) begin
        id_exe_if_branch_reg <= 0;
        //id_exe_if_branch_addr_reg <= 0;
        id_exe_exe_alu_a_reg <= 0;
        id_exe_exe_alu_b_reg <= 0;
        id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
        id_exe_mem_wb_cyc_reg <= 0;
        id_exe_mem_wb_stb_reg <= 0;
        id_exe_mem_wb_we_reg <= 0;
        id_exe_mem_load_reg <= 0;
        id_exe_mem_store_reg <= 0;
        id_exe_wb_csr_we_reg <= 0;
        id_exe_wb_csr_waddr_reg <= 0;
        id_exe_wb_rf_we_reg <= 0;
        id_exe_rd_reg <= 0;
        id_exe_exe_exceptionoccur_reg<=0;
    end else if (id_stall_i) begin
    end else if (id_flush_i) begin
        id_exe_if_branch_reg <= 0;
        //id_exe_if_branch_addr_reg <= 0;
        id_exe_exe_alu_a_reg <= 0;
        id_exe_exe_alu_b_reg <= 0;
        id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
        id_exe_mem_wb_cyc_reg <= 0;
        id_exe_mem_wb_stb_reg <= 0;
        id_exe_mem_wb_we_reg <= 0;
        id_exe_mem_load_reg <= 0;
        id_exe_mem_store_reg <= 0;
        id_exe_wb_csr_we_reg <= 0;
        id_exe_wb_csr_waddr_reg <= 0;
        id_exe_wb_rf_we_reg <= 0;
        id_exe_rd_reg <= 0;
        id_exe_exe_exceptionoccur_reg<=0;
    end else begin
        // instruction analysis here begin 
        if (if_id_id_inst_reg[6:0] == 7'b1110011 && if_id_id_inst_reg[14:12] == 3'b000 && if_id_id_inst_reg[31:20] == 1) begin //ebreak
            id_exe_if_branch_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b0;
            id_exe_wb_rf_waddr_reg <= 0;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_rfstorealuy_reg <= 1'b0;
            id_exe_rd_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;

            id_exe_exe_exception_pc_reg <= if_id_id_pc_now_reg;
            id_exe_exe_exception_mcause_reg <= 3;//breakpoint
            id_exe_exe_exceptionoccur_reg<=1;
        end else if (if_id_id_inst_reg[6:0] == 7'b1110011 && if_id_id_inst_reg[14:12] == 3'b000 && if_id_id_inst_reg[31:20] == 0) begin //ecall
            id_exe_if_branch_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b0;
            id_exe_wb_rf_waddr_reg <= 0;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_rfstorealuy_reg <= 1'b0;
            id_exe_rd_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;

            id_exe_exe_exception_pc_reg <= if_id_id_pc_now_reg;
            if (mode_reg == 0) begin
                id_exe_exe_exception_mcause_reg <= 8;//environment call from U mode
            end else begin
                id_exe_exe_exception_mcause_reg <= 11;//environment call from M mode
            end
            id_exe_exe_exceptionoccur_reg<=1;
        end
        // csr instructions
        else if(if_id_id_inst_reg[6:0] == 7'b1110011 && if_id_id_inst_reg[14:12] == 3'b001) begin // csrrw
            id_exe_if_branch_reg <= 0;

            // write rd
            id_exe_wb_rf_we_reg <= 1'b1; // write reg back
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7]; // rd register in instruction
            id_exe_exe_rfstorealuy_reg <= 1'b0; // donot restore from alu
            id_exe_wb_rf_wdata_reg <= csr_rdata_a;

            // close wishbone signal in wb stage
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;

            // write csr
            id_exe_wb_csr_we_reg <= 1'b1;
            id_exe_exe_csrstorealuy_reg <= 1'b0; // donot read from aluy 
            id_exe_wb_csr_wdata_reg <= rf_rdata_a;
            id_exe_wb_csr_waddr_reg <= if_id_id_inst_reg[31:20];

            // we donot care alu here
            id_exe_rd_reg <= if_id_id_inst_reg[11:7]; // rd reg again

            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b1110011 && if_id_id_inst_reg[14:12] == 3'b010) begin // csrrs
            // csrrs, set corresponding position as 1
            id_exe_if_branch_reg <= 0;

            // write rd
            id_exe_wb_rf_we_reg <= 1'b1; // write reg back
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7]; // rd register in instruction
            id_exe_exe_rfstorealuy_reg <= 1'b0; // donot restore from alu
            id_exe_wb_rf_wdata_reg <= csr_rdata_a;

            // close wishbone signal in wb stage
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;

            // write csr
            id_exe_wb_csr_we_reg <= 1'b1;
            id_exe_exe_csrstorealuy_reg <= 1'b1; // read from alu_y
            id_exe_wb_csr_waddr_reg <= if_id_id_inst_reg[31:20];

            // alu stage
            id_exe_exe_alu_a_reg <= csr_rdata_a;
            id_exe_exe_alu_b_reg <= rf_rdata_a;
            id_exe_exe_alu_op_reg <= `ALU_OP_CSRS;

            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            
            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b1110011 && if_id_id_inst_reg[14:12] == 3'b011) begin // csrrc
            // csrrc set the corresponding position 0
            id_exe_if_branch_reg <= 0;

            // write rd
            id_exe_wb_rf_we_reg <= 1'b1; // write reg back
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7]; // rd register in instruction
            id_exe_exe_rfstorealuy_reg <= 1'b0; // donot restore from alu
            id_exe_wb_rf_wdata_reg <= csr_rdata_a;

            // close wishbone signal in wb stage
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;

            // write csr
            id_exe_wb_csr_we_reg <= 1'b1;
            id_exe_exe_csrstorealuy_reg <= 1'b1; // read from alu_y
            id_exe_wb_csr_waddr_reg <= if_id_id_inst_reg[31:20];

            // alu stage
            id_exe_exe_alu_a_reg <= csr_rdata_a;
            id_exe_exe_alu_b_reg <= rf_rdata_a;
            id_exe_exe_alu_op_reg <= `ALU_OP_CSRC;
            
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];

            
            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b0110111) begin  // lui
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_wb_rf_wdata_reg <= imm_gen_i;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_rfstorealuy_reg <= 1'b0;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b0010111) begin // auipc
            // if_id_id_inst_reg[6:0] is opcode
            id_exe_if_branch_reg <= 0; // not a branch instruction
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1; // write reg in wb stage
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7]; // wb stage reg addr
            id_exe_exe_rfstorealuy_reg <= 1'b1;  // rf store from alu y !!!

            // close wishbone signal in wb stage
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;

            // alu stage
            id_exe_exe_alu_a_reg <= if_id_id_pc_now_reg;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7]; // what is this !!!

            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b1100011 && if_id_id_inst_reg[14:12] == 3'b000) begin // beq
            id_exe_if_branch_reg <= 1;
            id_exe_if_branch_addr_reg <= if_alu_y;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= rf_rdata_b;
            id_exe_exe_alu_op_reg <= `ALU_OP_SUB;
            id_exe_mem_wb_cyc_reg <= 0;
            id_exe_mem_wb_stb_reg <= 0;
            id_exe_mem_wb_we_reg <= 0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 0;
            id_exe_wb_rf_waddr_reg <= 0;
            id_exe_exe_rfstorealuy_reg <= 0;
            id_exe_rd_reg <= 0;
            id_exe_id_branchequ <= 1;
            id_exe_exe_isjump_reg <= 0;
            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b1100011 && if_id_id_inst_reg[14:12] == 3'b001) begin // bne
            id_exe_if_branch_reg <= 1;
            id_exe_if_branch_addr_reg <= if_alu_y;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= rf_rdata_b;
            id_exe_exe_alu_op_reg <= `ALU_OP_SUB;
            id_exe_mem_wb_cyc_reg <= 0;
            id_exe_mem_wb_stb_reg <= 0;
            id_exe_mem_wb_we_reg <= 0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 0;
            id_exe_wb_rf_waddr_reg <= 0;
            id_exe_exe_rfstorealuy_reg <= 0;
            id_exe_rd_reg <= 0;
            id_exe_id_branchequ <= 0;
            id_exe_exe_isjump_reg <= 0;
            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b1101111) begin // jal
            id_exe_if_branch_reg <= 1;
            id_exe_if_branch_addr_reg <= if_alu_y;
            id_exe_exe_alu_a_reg <= if_id_id_pc_now_reg;
            id_exe_exe_alu_b_reg <= 32'h0000_0004;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_mem_wb_cyc_reg <= 0;
            id_exe_mem_wb_stb_reg <= 0;
            id_exe_mem_wb_we_reg <= 0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_id_branchequ <= 0;
            id_exe_exe_isjump_reg <= 1;
            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b1100111) begin // jalr
            id_exe_if_branch_reg <= 1;
            id_exe_if_branch_addr_reg <= if_alu_y;
            id_exe_exe_alu_a_reg <= if_id_id_pc_now_reg;
            id_exe_exe_alu_b_reg <= 32'h0000_0004;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_mem_wb_cyc_reg <= 0;
            id_exe_mem_wb_stb_reg <= 0;
            id_exe_mem_wb_we_reg <= 0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_id_branchequ <= 0;
            id_exe_exe_isjump_reg <= 1;
            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b0000011 && if_id_id_inst_reg[14:12] == 3'b000) begin // lb
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b0;
            id_exe_mem_wb_cyc_reg <= 1'b1;
            id_exe_mem_wb_stb_reg <= 1'b1;
            id_exe_mem_wb_sel_reg <= 4'b0001;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 1;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if (if_id_id_inst_reg[6:0] == 7'b0000011 && if_id_id_inst_reg[14:12] == 3'b010) begin // lw
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b0;
            id_exe_mem_wb_cyc_reg <= 1'b1;
            id_exe_mem_wb_stb_reg <= 1'b1;
            id_exe_mem_wb_sel_reg <= 4'b1111;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 1;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0100011) && (if_id_id_inst_reg[14:12] == 3'b000)) begin // sb
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b0;
            id_exe_wb_rf_waddr_reg <= 0;
            id_exe_exe_rfstorealuy_reg <= 1'b0;
            id_exe_mem_wb_cyc_reg <= 1'b1;
            id_exe_mem_wb_stb_reg <= 1'b1;
            id_exe_mem_wb_sel_reg <= 4'b0001;
            id_exe_mem_wb_we_reg <= 1'b1;
            id_exe_mem_wb_dat_reg <= rf_rdata_b;
            id_exe_mem_store_reg <= 1'b1;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_rd_reg <= 0;
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0100011) && (if_id_id_inst_reg[14:12] == 3'b010)) begin // sw
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b0;
            id_exe_wb_rf_waddr_reg <= 0;
            id_exe_exe_rfstorealuy_reg <= 1'b0;
            id_exe_mem_wb_cyc_reg <= 1'b1;
            id_exe_mem_wb_stb_reg <= 1'b1;
            id_exe_mem_wb_sel_reg <= 4'b1111;
            id_exe_mem_wb_we_reg <= 1'b1;
            id_exe_mem_wb_dat_reg <= rf_rdata_b;
            id_exe_mem_store_reg <= 1'b1;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_rd_reg <= 0;
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0010011) && (if_id_id_inst_reg[14:12] == 3'b000)) begin // addi
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0010011) && (if_id_id_inst_reg[14:12] == 3'b111)) begin // andi
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_AND;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0010011) && (if_id_id_inst_reg[14:12] == 3'b001)) begin // slli
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_SLL;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0010011) && (if_id_id_inst_reg[14:12] == 3'b101)) begin // srli
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_SRL;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0010011) && (if_id_id_inst_reg[14:12] == 3'b110)) begin // ori
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= imm_gen_i;
            id_exe_exe_alu_op_reg <= `ALU_OP_OR;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if((if_id_id_inst_reg[6:0] == 7'b0110011) && (if_id_id_inst_reg[14:12] == 3'b011)) begin // sltu
            id_exe_if_branch_reg <= 0; // not a branch command
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1; // write back register
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1; // we do need to restore from alu_y
            id_exe_mem_wb_cyc_reg <= 1'b0; // do not read from wishbone
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 1'b0;
            id_exe_exe_alu_a_reg <= rf_rdata_a; // rs1
            id_exe_exe_alu_b_reg <= rf_rdata_b; // rs2
            id_exe_exe_alu_op_reg <= `ALU_OP_AND;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7]; // some magic reg by plf
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0110011) && (if_id_id_inst_reg[14:12] == 3'b111)) begin // and
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= rf_rdata_b;
            id_exe_exe_alu_op_reg <= `ALU_OP_AND;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0110011) && (if_id_id_inst_reg[14:12] == 3'b000)) begin // add
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= rf_rdata_b;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0110011) && (if_id_id_inst_reg[14:12] == 3'b110)) begin // or
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= rf_rdata_b;
            id_exe_exe_alu_op_reg <= `ALU_OP_OR;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else if ((if_id_id_inst_reg[6:0] == 7'b0110011) && (if_id_id_inst_reg[14:12] == 3'b100)) begin // xor
            id_exe_if_branch_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 1'b1;
            id_exe_wb_rf_waddr_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_rfstorealuy_reg <= 1'b1;
            id_exe_mem_wb_cyc_reg <= 1'b0;
            id_exe_mem_wb_stb_reg <= 1'b0;
            id_exe_mem_wb_we_reg <= 1'b0;
            id_exe_mem_store_reg <= 1'b0;
            id_exe_mem_load_reg <= 0;
            id_exe_exe_alu_a_reg <= rf_rdata_a;
            id_exe_exe_alu_b_reg <= rf_rdata_b;
            id_exe_exe_alu_op_reg <= `ALU_OP_XOR;
            id_exe_rd_reg <= if_id_id_inst_reg[11:7];
            id_exe_exe_exceptionoccur_reg<=0;
        end else begin 
            id_exe_if_branch_reg <= 0;
            id_exe_exe_alu_a_reg <= 0;
            id_exe_exe_alu_b_reg <= 0;
            id_exe_exe_alu_op_reg <= `ALU_OP_ADD;
            id_exe_mem_wb_cyc_reg <= 0;
            id_exe_mem_wb_stb_reg <= 0;
            id_exe_mem_wb_we_reg <= 0;
            id_exe_mem_load_reg <= 0;
            id_exe_mem_store_reg <= 0;
            id_exe_wb_csr_we_reg <= 1'b0;
            id_exe_wb_csr_waddr_reg <= 0;
            id_exe_wb_rf_we_reg <= 0;
            id_exe_wb_rf_waddr_reg <= 0;
            id_exe_rd_reg <= 0;
            id_exe_exe_exceptionoccur_reg<=0;
        end
    end
end

// state_id comb
always_comb begin
    // we add the crs addr here
    // TODO: if rd is x0, we should not do the read operation
    csr_raddr_a = if_id_id_inst_reg[31 : 20]; // we only use one csr read function here

    rf_raddr_a = if_id_id_inst_reg[19:15]; // rs1
    rf_raddr_b = if_id_id_inst_reg[24:20]; // rs2
    imm_gen_o = if_id_id_inst_reg;

    if (if_id_id_inst_reg[6:0] == 7'b1110011) begin // csrrw, csrrs, csrrc,ecall,ebreak
        imm_gen_type_o = `TYPE_CSR;
        have_rs1 = 1;
        have_rs2 = 0;
    end else if (if_id_id_inst_reg[6:0] == 7'b0110111) begin  // lui
        imm_gen_type_o = `TYPE_U;
        have_rs1 = 0;
        have_rs2 = 0;
    end else if (if_id_id_inst_reg[6:0] == 7'b0010111) begin // auipc
        imm_gen_type_o = `TYPE_U;
        have_rs1 = 0;
        have_rs2 = 0;
    end else if (if_id_id_inst_reg[6:0] == 7'b1100011) begin // beq bne
        imm_gen_type_o = `TYPE_B;
        have_rs1 = 1;
        have_rs2 = 1;
    end else if (if_id_id_inst_reg[6:0] == 7'b1101111) begin // jal
        imm_gen_type_o = `TYPE_J;
        have_rs1 = 0;
        have_rs2 = 0;
    end else if (if_id_id_inst_reg[6:0] == 7'b1100111) begin // jalr
        imm_gen_type_o = `TYPE_I;
        have_rs1 = 1;
        have_rs2 = 0;
    end else if (if_id_id_inst_reg[6:0] == 7'b0000011) begin // lb lw
        imm_gen_type_o = `TYPE_I;
        have_rs1 = 1;
        have_rs2 = 0;
    end else if (if_id_id_inst_reg[6:0] == 7'b0100011) begin // sb sw
        imm_gen_type_o = `TYPE_S;
        have_rs1 = 1;
        have_rs2 = 1;
    end else if (if_id_id_inst_reg[6:0] == 7'b0010011) begin // addi andi slli srli ori
        imm_gen_type_o = `TYPE_I;
        have_rs1 = 1;
        have_rs2 = 0;
    end else if (if_id_id_inst_reg[6:0] == 7'b0110011) begin // add and or xor
        imm_gen_type_o = `TYPE_R;
        have_rs1 = 1;
        have_rs2 = 1;
    end else begin
        imm_gen_type_o = `TYPE_R;
        have_rs1 = 0;
        have_rs2 = 0;
    end
    id_stall_o = 0;
    if ((id_exe_rd_reg == if_id_id_inst_reg[19:15] && if_id_id_inst_reg[19:15] != 0 && have_rs1)||
    (id_exe_rd_reg == if_id_id_inst_reg[24:20] && if_id_id_inst_reg[24:20] != 0 && have_rs2)||
    (exe_mem_rd_reg == if_id_id_inst_reg[19:15] && if_id_id_inst_reg[19:15] != 0 && have_rs1)||
    (exe_mem_rd_reg == if_id_id_inst_reg[24:20] && if_id_id_inst_reg[24:20] != 0 && have_rs2)||
    (mem_wb_rd_ack_reg == if_id_id_inst_reg[19:15] && if_id_id_inst_reg[19:15] != 0 && have_rs1)||
    (mem_wb_rd_ack_reg == if_id_id_inst_reg[24:20] && if_id_id_inst_reg[24:20] != 0 && have_rs2)||
    (imm_gen_type_o == `TYPE_CSR && if_id_id_inst_reg[31:20] != 0 && if_id_id_inst_reg[31:20] == id_exe_wb_csr_waddr_reg)||
    (imm_gen_type_o == `TYPE_CSR && if_id_id_inst_reg[31:20] != 0 && if_id_id_inst_reg[31:20] == exe_mem_wb_csr_waddr_reg)||
    (imm_gen_type_o == `TYPE_CSR && if_id_id_inst_reg[31:20] != 0 && if_id_id_inst_reg[31:20] == mem_wb_wb_csr_waddr_reg)) begin
        id_stall_o = 1;
    end
end


// state_exe
always_ff @ (posedge clk_i) begin
    if (rst_i) begin
        exe_mem_mem_wb_cyc_reg <= 0;
        exe_mem_mem_wb_stb_reg <= 0;
        exe_mem_mem_wb_we_reg <= 0;
        exe_mem_mem_load_reg <= 0;
        exe_mem_mem_store_reg <= 0;
        exe_mem_wb_csr_we_reg <= 0;
        exe_mem_wb_csr_waddr_reg <= 0;
        exe_mem_wb_rf_we_reg <= 0;
        exe_mem_rd_reg <= 0;
        exe_if_if_branch_successornot_reg <= 0;
        exe_if_if_branch_compcompute <= 0;
        mode_reg <= 2'b11;
        exe_exceptionprocessup_reg<=0;
    end else if (exe_stall_i) begin
    end else if (exe_flush_i) begin
        exe_mem_mem_wb_cyc_reg <= 0;
        exe_mem_mem_wb_stb_reg <= 0;
        exe_mem_mem_wb_we_reg <= 0;
        exe_mem_mem_load_reg <= 0;
        exe_mem_mem_store_reg <= 0;
        exe_mem_wb_rf_we_reg <= 0;
        exe_mem_wb_csr_we_reg <= 0;
        exe_mem_wb_csr_waddr_reg <= 0;
        exe_mem_rd_reg <= 0;
        exe_if_if_branch_successornot_reg  <= 0;
        exe_if_if_branch_compcompute <= 0;
    end else begin
        if (id_exe_exe_exceptionoccur_reg) begin//注意暂停流水线没写,暂停流水线没有测试
        exe_exceptionprocessup_reg <= 1;
        exe_exception_mcause_reg <= id_exe_exe_exception_mcause_reg;
        exe_exception_pc_reg <= id_exe_exe_exception_pc_reg;
    end

        if (id_exe_if_branch_reg)begin
            if (id_exe_exe_isjump_reg) begin
                exe_if_if_branch_successornot_reg <= 1;
            end else if (id_exe_id_branchequ) begin
                exe_if_if_branch_successornot_reg <=  (alu_y == 0);
            end else begin
                exe_if_if_branch_successornot_reg <=  (alu_y != 0);
            end
            exe_if_if_branch_compcompute <= 1;
            exe_if_if_branch_addr_reg <=  id_exe_if_branch_addr_reg;
            // if (alu_y == 0)begin
            //     if_pc_reg <=  id_exe_if_branch_addr_reg;
            // end
            // if_id_id_inst_reg <= 0;
        end else begin
            exe_if_if_branch_successornot_reg  <= 0;
            exe_if_if_branch_compcompute <= 0;
        end
        exe_mem_wb_rf_we_reg <= id_exe_wb_rf_we_reg;
        exe_mem_wb_rf_waddr_reg <= id_exe_wb_rf_waddr_reg;

        // for csr
        exe_mem_wb_csr_we_reg <= id_exe_wb_csr_we_reg;
        exe_mem_wb_csr_waddr_reg <= id_exe_wb_csr_waddr_reg;

        exe_mem_rd_reg <= id_exe_rd_reg; // pass it to next stage
        if (id_exe_exe_rfstorealuy_reg) begin   // 要将alu计算结果放进寄存器堆的情�???????????
            exe_mem_wb_rf_wdata_reg <= alu_y;
        end else begin
            exe_mem_wb_rf_wdata_reg <= id_exe_wb_rf_wdata_reg;
        end

        // csr special
        if (id_exe_exe_csrstorealuy_reg) begin   // choose if store to csr from alu_y
            exe_mem_wb_csr_wdata_reg <= alu_y;
        end else begin
            exe_mem_wb_csr_wdata_reg <= id_exe_wb_csr_wdata_reg;
        end

        exe_mem_mem_load_reg <= id_exe_mem_load_reg;
        exe_mem_mem_store_reg <= id_exe_mem_store_reg;
        exe_mem_mem_wb_cyc_reg <= id_exe_mem_wb_cyc_reg;
        exe_mem_mem_wb_stb_reg <= id_exe_mem_wb_stb_reg;
        exe_mem_mem_wb_we_reg <= id_exe_mem_wb_we_reg;
        // exe_mem_mem_wb_sel_reg <= id_exe_mem_wb_sel_reg;
        exe_mem_mem_wb_dat_reg <= id_exe_mem_wb_dat_reg;
        if (id_exe_mem_load_reg||id_exe_mem_store_reg) begin
            exe_mem_mem_wb_adr_reg <= alu_y;
            if (id_exe_mem_wb_sel_reg == 4'b1111) begin
                exe_mem_mem_wb_sel_reg <= id_exe_mem_wb_sel_reg;
            end else begin
                case(alu_y[1:0])
                    2'b00 : exe_mem_mem_wb_sel_reg<=4'b0001;
                    2'b01 : exe_mem_mem_wb_sel_reg<=4'b0010;
                    2'b10 : exe_mem_mem_wb_sel_reg<=4'b0100;
                    2'b11 : exe_mem_mem_wb_sel_reg<=4'b1000;
                    default:exe_mem_mem_wb_sel_reg<=0;
                endcase
            end
        end
    end
end

always_comb begin
    alu_a = id_exe_exe_alu_a_reg;
    alu_b = id_exe_exe_alu_b_reg;
    alu_op = id_exe_exe_alu_op_reg;
    if(exe_exceptionprocessup_reg) begin
        exe_flush_o = 1;
    end else begin
        exe_flush_o = 0;
    end
end

typedef enum logic [3:0] {
    STATE_INIT = 0,
    STATE_W_mepc=1,
    STATE_W_mcause=2,
    STATE_W_mstatus=3
} state_exp;

always_ff @ (posedge clk_i ) begin
    if(rst_i) begin
        state_exp <= STATE_INIT;
        csr_we_exp <= 0;
    end else if (exe_exceptionprocessup_reg) begin
        case(state_exp)
        STATE_INIT: begin
            if (if_wb_stb_o==0 && mem_wb_stb_o==0) begin
                state_exp <= STATE_W_mepc;
                csr_we_exp <= 1;
                csr_waddr_exp <= 12'h341;
                csr_wdata_exp <= id_exe_exe_exception_pc_reg;
            end
        end
        STATE_W_mepc: begin
            state_exp <= STATE_W_mcause;
            csr_we_exp <= 1;
            csr_waddr_exp <= 12'h342;
            csr_wdata_exp <= id_exe_exe_exception_mcause_reg;
        end
        STATE_W_mcause: begin
            state_exp <= STATE_W_mstatus;
            csr_we_exp <= 1;
            csr_waddr_exp <= 12'h300;
            csr_wdata_exp <= {19'b0,mode_reg,11'b0};
        end
        STATE_W_mstatus: begin
            state_exp <= STATE_INIT;
            csr_we_exp <= 0;//没写完
        end
        endcase
    end
end

//mem
always_ff @ (posedge clk_i) begin
    if (rst_i) begin
        mem_wb_wb_rf_we_ack_reg <= 0;
        mem_wb_wb_csr_we_reg <= 0;
        mem_wb_wb_csr_waddr_reg <= 0;
        mem_wb_cyc_o <= 0;
        mem_wb_stb_o <= 0;
        mem_wb_we_o <= 0;
        mem_wb_rd_ack_reg <= 0;
    end else if (mem_stall_i) begin
    end else if (mem_flush_i) begin
        mem_wb_wb_csr_we_reg <= 0;
        mem_wb_wb_csr_waddr_reg <= 0;
        mem_wb_wb_rf_we_ack_reg <= 0;
        mem_wb_rd_ack_reg <= 0;
    end else begin
        if (exe_mem_mem_load_reg == 0 && exe_mem_mem_store_reg == 0 && mem_wb_stb_o == 0)begin
            mem_wb_wb_rf_waddr_ack_reg <= exe_mem_wb_rf_waddr_reg;
            mem_wb_wb_rf_wdata_ack_reg <= exe_mem_wb_rf_wdata_reg;
            mem_wb_wb_rf_we_ack_reg <= exe_mem_wb_rf_we_reg;
            mem_wb_rd_ack_reg <= exe_mem_rd_reg; // this is the case donot need mem, and here we pass it again, seems that we will not pass it later. So what does it use for !!!
            // mem_wb_cyc_o <= 0;
            // mem_wb_stb_o <= 0;
            // mem_wb_we_o <= 0;

            // for csr
            mem_wb_wb_csr_waddr_reg <= exe_mem_wb_csr_waddr_reg;
            mem_wb_wb_csr_wdata_reg <= exe_mem_wb_csr_wdata_reg;
            mem_wb_wb_csr_we_reg <= exe_mem_wb_csr_we_reg;
            
            
            // TODO deal with data conflict
        end
        else begin
            if (mem_wb_ack_i) begin
                mem_wb_cyc_o <= 0;
                mem_wb_stb_o <= 0;
                mem_wb_we_o <= 0;
                // mem_wb_wb_rf_wdata_ack_reg <= mem_wb_wb_rf_wdata_start_reg;
                mem_wb_wb_rf_waddr_ack_reg <= mem_wb_wb_rf_waddr_start_reg;
                mem_wb_wb_rf_we_ack_reg <= mem_wb_wb_rf_we_start_reg;
                mem_wb_rd_ack_reg <= mem_wb_rd_start_reg;
                if (mem_wb_sel_o==4'b0001)begin
                    mem_wb_wb_rf_wdata_ack_reg <= {{24{mem_wb_dat_i[7]}},mem_wb_dat_i[7:0]};//lb
                end else if (mem_wb_sel_o == 4'b0010) begin
                    mem_wb_wb_rf_wdata_ack_reg <= {{24{mem_wb_dat_i[15]}},mem_wb_dat_i[15:8]};//lb
                end else if (mem_wb_sel_o == 4'b0100) begin
                    mem_wb_wb_rf_wdata_ack_reg <= {{24{mem_wb_dat_i[23]}},mem_wb_dat_i[23:16]};//lb
                end else if (mem_wb_sel_o == 4'b1000) begin
                    mem_wb_wb_rf_wdata_ack_reg <= {{24{mem_wb_dat_i[31]}},mem_wb_dat_i[31:24]};//lb
                end else begin//lw
                    mem_wb_wb_rf_wdata_ack_reg <= mem_wb_dat_i;
                end
            end else begin
                mem_wb_cyc_o <= exe_mem_mem_wb_cyc_reg;
                mem_wb_stb_o <= exe_mem_mem_wb_stb_reg;
                mem_wb_we_o <= exe_mem_mem_wb_we_reg;
                mem_wb_wb_rf_we_ack_reg <= 0;
                mem_wb_wb_rf_waddr_start_reg <= exe_mem_wb_rf_waddr_reg;
                mem_wb_wb_rf_we_start_reg <= exe_mem_wb_rf_we_reg;
                mem_wb_wb_rf_wdata_ack_reg <= mem_wb_wb_rf_wdata_start_reg;
                mem_wb_rd_start_reg <= exe_mem_rd_reg;
                mem_wb_wb_csr_we_reg <= 0;
                mem_wb_wb_csr_waddr_reg <= 0;
            end
        end
    end
end
always_comb begin
    mem_stall_o = mem_wb_stb_o;
    mem_wb_sel_o = exe_mem_mem_wb_sel_reg;
    mem_wb_dat_o = exe_mem_mem_wb_dat_reg;
    mem_wb_adr_o = exe_mem_mem_wb_adr_reg;
end


//wb
always_ff @ (posedge clk_i) begin
  end
always_comb begin

    csr_we = mem_wb_wb_csr_we_reg;
    csr_waddr = mem_wb_wb_csr_waddr_reg;
    csr_wdata = mem_wb_wb_csr_wdata_reg;

    rf_we = mem_wb_wb_rf_we_ack_reg;
    rf_waddr = mem_wb_wb_rf_waddr_ack_reg;
    rf_wdata = mem_wb_wb_rf_wdata_ack_reg;
end




stall_controller u_controller (
    .if_stall_i(if_stall_i),
    .if_stall_o(if_stall_o),
    .if_flush_i(if_flush_i),
    .if_flush_o(if_flush_o),
    
    .id_stall_i(id_stall_i),
    .id_stall_o(id_stall_o),
    .id_flush_i(id_flush_i),
    .id_flush_o(id_flush_o),

    .exe_stall_i(exe_stall_i),
    .exe_stall_o(exe_stall_o),
    .exe_flush_i(exe_flush_i),
    .exe_flush_o(exe_flush_o),

    .mem_stall_i(mem_stall_i),
    .mem_stall_o(mem_stall_o),
    .mem_flush_i(mem_flush_i),
    .mem_flush_o(mem_flush_o),

    .if_wb_ack_i(if_wb_ack_i),
    .if_wb_stb_o(if_wb_stb_o),
    .mem_wb_ack_i(mem_wb_ack_i),
    .mem_wb_stb_o(mem_wb_stb_o)
);

endmodule