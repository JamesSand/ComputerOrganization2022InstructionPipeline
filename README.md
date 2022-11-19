Thinpad 模板工程
---------------

工程包含示例代码和所有引脚约束，可以直接编译。

代码中包含中文注释，编码为utf-8，在Windows版Vivado下可能出现乱码问题。  
请用别的代码编辑器打开文件，并将编码改为GBK。
// state_if 生成的信�??????????
reg if_stall_i,if_stall_o,if_flush_i,if_flush_o;
reg [31:0]  if_id_id_pc_now_reg;
reg [31:0]  if_pc_reg;
reg [31:0]  if_id_id_inst_reg;

// state_id 生成的信�??????????
reg id_stall_i,id_stall_o,id_flush_i,id_flush_o;
reg [31:0]  id_exe_if_branch_addr_reg;
reg id_exe_if_branch_reg;

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


// state_exe 生成的信�??????????
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

//mem
reg mem_stall_i,mem_stall_o,mem_flush_i,mem_flush_o;
reg [31:0] mem_wb_wb_rf_wdata_reg;
reg [4:0] mem_wb_wb_rf_waddr_reg;
reg mem_wb_wb_rf_we_reg;

reg [4:0] mem_wb_rd_reg;
