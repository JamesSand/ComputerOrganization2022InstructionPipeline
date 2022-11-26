`default_nettype none

module lab6_top (
    input wire clk_50M,     // 50MHz 时钟输入
    input wire clk_11M0592, // 11.0592MHz 时钟输入（备用，可不用）

    input wire push_btn,  // BTN5 按钮�?关，带消抖电路，按下时为 1
    input wire reset_btn, // BTN6 复位按钮，带消抖电路，按下时�? 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4，按钮开关，按下时为 1
    input  wire [31:0] dip_sw,     // 32 位拨码开关，拨到“ON”时�? 1
    output wire [15:0] leds,       // 16 �? LED，输出时 1 点亮
    output wire [ 7:0] dpy0,       // 数码管低位信号，包括小数点，输出 1 点亮
    output wire [ 7:0] dpy1,       // 数码管高位信号，包括小数点，输出 1 点亮

    // CPLD 串口控制器信�?
    output wire uart_rdn,        // 读串口信号，低有�?
    output wire uart_wrn,        // 写串口信号，低有�?
    input  wire uart_dataready,  // 串口数据准备�?
    input  wire uart_tbre,       // 发�?�数据标�?
    input  wire uart_tsre,       // 数据发�?�完毕标�?

    // BaseRAM 信号
    inout wire [31:0] base_ram_data,  // BaseRAM 数据，低 8 位与 CPLD 串口控制器共�?
    output wire [19:0] base_ram_addr,  // BaseRAM 地址
    output wire [3:0] base_ram_be_n,  // BaseRAM 字节使能，低有效。如果不使用字节使能，请保持�? 0
    output wire base_ram_ce_n,  // BaseRAM 片�?�，低有�?
    output wire base_ram_oe_n,  // BaseRAM 读使能，低有�?
    output wire base_ram_we_n,  // BaseRAM 写使能，低有�?

    // ExtRAM 信号
    inout wire [31:0] ext_ram_data,  // ExtRAM 数据
    output wire [19:0] ext_ram_addr,  // ExtRAM 地址
    output wire [3:0] ext_ram_be_n,  // ExtRAM 字节使能，低有效。如果不使用字节使能，请保持�? 0
    output wire ext_ram_ce_n,  // ExtRAM 片�?�，低有�?
    output wire ext_ram_oe_n,  // ExtRAM 读使能，低有�?
    output wire ext_ram_we_n,  // ExtRAM 写使能，低有�?

    // 直连串口信号
    output wire txd,  // 直连串口发�?�端
    input  wire rxd,  // 直连串口接收�?

    // Flash 存储器信号，参�?? JS28F640 芯片手册
    output wire [22:0] flash_a,  // Flash 地址，a0 仅在 8bit 模式有效�?16bit 模式无意�?
    inout wire [15:0] flash_d,  // Flash 数据
    output wire flash_rp_n,  // Flash 复位信号，低有效
    output wire flash_vpen,  // Flash 写保护信号，低电平时不能擦除、烧�?
    output wire flash_ce_n,  // Flash 片�?�信号，低有�?
    output wire flash_oe_n,  // Flash 读使能信号，低有�?
    output wire flash_we_n,  // Flash 写使能信号，低有�?
    output wire flash_byte_n, // Flash 8bit 模式选择，低有效。在使用 flash �? 16 位模式时请设�? 1

    // USB 控制器信号，参�?? SL811 芯片手册
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB 数据线与网络控制器的 dm9k_sd[7:0] 共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // 网络控制器信号，参�?? DM9000A 芯片手册
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // 图像输出信号
    output wire [2:0] video_red,    // 红色像素�?3 �?
    output wire [2:0] video_green,  // 绿色像素�?3 �?
    output wire [1:0] video_blue,   // 蓝色像素�?2 �?
    output wire       video_hsync,  // 行同步（水平同步）信�?
    output wire       video_vsync,  // 场同步（垂直同步）信�?
    output wire       video_clk,    // 像素时钟输出
    output wire       video_de      // 行数据有效信号，用于区分消隐�?
);

  /* =========== Demo code begin =========== */

  // PLL 分频示例
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // 外部时钟输入
      // Clock out ports
      .clk_out1(clk_10M),  // 时钟输出 1，频率在 IP 配置界面中设�?
      .clk_out2(clk_20M),  // 时钟输出 2，频率在 IP 配置界面中设�?
      // Status and control signals
      .reset(reset_btn),  // PLL 复位输入
      .locked(locked)  // PLL 锁定指示输出�?"1"表示时钟稳定�?
                       // 后级电路复位信号应当由它生成（见下）
  );

  logic reset_of_clk10M;
  // 异步复位，同步释放，�? locked 信号转为后级电路的复�? reset_of_clk10M
  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end

  /* =========== Demo code end =========== */

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_10M;
  assign sys_rst = reset_of_clk10M;

  // 本实验不使用 CPLD 串口，禁用防止�?�线冲突
  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  /* =========== Lab5 Master begin =========== */
  // Lab5 Master => Wishbone MUX (Slave)

  // mmu signal
  logic        mmu_cyc_o;
  logic        mmu_stb_o;
  logic        mmu_ack_i;
  logic [31:0] mmu_adr_o;
  logic [31:0] mmu_dat_o;
  logic [31:0] mmu_dat_i;
  logic [ 3:0] mmu_sel_o;
  logic        mmu_we_o;
  logic [1:0]  mmu_mode;
  logic [31:0] mmu_satp;


  logic        wbm_cyc_o;
  logic        wbm_stb_o;
  logic        wbm_ack_i;
  logic [31:0] wbm_adr_o;
  logic [31:0] wbm_dat_o;
  logic [31:0] wbm_dat_i;
  logic [ 3:0] wbm_sel_o;
  logic        wbm_we_o;

  logic        if_wbm_cyc_o;
  logic        if_wbm_stb_o;
  logic        if_wbm_ack_i;
  logic [31:0] if_wbm_adr_o;
  logic [31:0] if_wbm_dat_o;
  logic [31:0] if_wbm_dat_i;
  logic [ 3:0] if_wbm_sel_o;
  logic        if_wbm_we_o;

  logic        mem_wbm_cyc_o;
  logic        mem_wbm_stb_o;
  logic        mem_wbm_ack_i;
  logic [31:0] mem_wbm_adr_o;
  logic [31:0] mem_wbm_dat_o;
  logic [31:0] mem_wbm_dat_i;
  logic [ 3:0] mem_wbm_sel_o;
  logic        mem_wbm_we_o;

  logic [31:0] imm_gen_o;
  logic [4:0] imm_gen_type;
  logic [31:0] imm_gen_i;

  logic [31:0] alu_a, alu_b, alu_y;
  logic [3:0] alu_op;

  logic [31:0] if_alu_a, if_alu_b, if_alu_y;
  logic [3:0] if_alu_op;

  logic [4:0] rf_raddr_a, rf_raddr_b, rf_waddr;
  logic [31:0] rf_rdata_b, rf_rdata_a, rf_wdata; 
  logic rf_we;

  logic [11:0] csr_raddr_a, csr_raddr_b, csr_waddr, csr_waddr_exp;
  logic [31:0] csr_rdata_b, csr_rdata_a, csr_wdata, csr_wdata_exp; 
  logic csr_we, csr_we_exp;

  logic mtime_exceed;
  logic time_interupt;

  wb_arbiter_2 #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32),
    .SELECT_WIDTH(4),
    .ARB_TYPE_ROUND_ROBIN(0),
    .ARB_LSB_HIGH_PRIORITY(1)
  ) u_wb_arbiter2 (
    .clk(sys_clk),
    .rst(sys_rst),

    .wbm0_adr_i(if_wbm_adr_o),
    .wbm0_dat_i(if_wbm_dat_o),
    .wbm0_dat_o(if_wbm_dat_i),
    .wbm0_we_i(if_wbm_we_o),
    .wbm0_sel_i(if_wbm_sel_o),
    .wbm0_stb_i(if_wbm_stb_o),
    .wbm0_ack_o(if_wbm_ack_i),
    .wbm0_err_o(),
    .wbm0_rty_o(),
    .wbm0_cyc_i(if_wbm_cyc_o),

    .wbm1_adr_i(mem_wbm_adr_o),
    .wbm1_dat_i(mem_wbm_dat_o),
    .wbm1_dat_o(mem_wbm_dat_i),
    .wbm1_we_i(mem_wbm_we_o),
    .wbm1_sel_i(mem_wbm_sel_o),
    .wbm1_stb_i(mem_wbm_stb_o),
    .wbm1_ack_o(mem_wbm_ack_i),
    .wbm1_err_o(),
    .wbm1_rty_o(),
    .wbm1_cyc_i(mem_wbm_cyc_o),

    .wbs_adr_o(mmu_adr_o),
    .wbs_dat_i(mmu_dat_i),
    .wbs_dat_o(mmu_dat_o),
    .wbs_we_o (mmu_we_o),
    .wbs_sel_o(mmu_sel_o),
    .wbs_stb_o(mmu_stb_o),
    .wbs_ack_i(mmu_ack_i),
    .wbs_err_i('0),
    .wbs_rty_i('0),
    .wbs_cyc_o(mmu_cyc_o)
  );

  mmu u_mmu (
    .clk(sys_clk),
    .rst(sys_rst),

    // arbiter
    .arbiter_addr_in(mmu_adr_o),
    .arbiter_data_in(mmu_dat_o),
    .arbiter_data_out(mmu_dat_i),
    .arbiter_we_in(mmu_we_o),
    .arbiter_sel_in(mmu_sel_o),
    .arbiter_stb_in(mmu_stb_o),
    .arbiter_cyc_in(mmu_cyc_o),
    .arbiter_ack_out(mmu_ack_i),

    // mux
    .mux_addr_out(wbm_adr_o),
    .mux_data_out(wbm_dat_o),
    .mux_data_in(wbm_dat_i),
    .mux_we_out(wbm_we_o),
    .mux_sel_out(wbm_sel_o),
    .mux_stb_out(wbm_stb_o),
    .mux_cyc_out(wbm_cyc_o),
    .mux_ack_in(wbm_ack_i),

    // mode
    .mode_in(mmu_mode),
    // satp
    .satp_in(mmu_satp)
  );

  pipeline_master #(
      .ADDR_WIDTH(32),
      .DATA_WIDTH(32)
  ) u_lab6_master (
      .leds(leds),
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // wishbone master
      .if_wb_cyc_o(if_wbm_cyc_o),
      .if_wb_stb_o(if_wbm_stb_o),
      .if_wb_ack_i(if_wbm_ack_i),
      .if_wb_adr_o(if_wbm_adr_o),
      .if_wb_dat_o(if_wbm_dat_o),
      .if_wb_dat_i(if_wbm_dat_i),
      .if_wb_sel_o(if_wbm_sel_o),
      .if_wb_we_o(if_wbm_we_o),

      .mem_wb_cyc_o(mem_wbm_cyc_o),
      .mem_wb_stb_o(mem_wbm_stb_o),
      .mem_wb_ack_i(mem_wbm_ack_i),
      .mem_wb_adr_o(mem_wbm_adr_o),
      .mem_wb_dat_o(mem_wbm_dat_o),
      .mem_wb_dat_i(mem_wbm_dat_i),
      .mem_wb_sel_o(mem_wbm_sel_o),
      .mem_wb_we_o(mem_wbm_we_o),

      // 连接 ALU 模块的信�???
      .alu_a(alu_a),
      .alu_b(alu_b),
      .alu_op(alu_op),
      .alu_y(alu_y),
      .if_alu_a(if_alu_a),
      .if_alu_b(if_alu_b),
      .if_alu_op(if_alu_op),
      .if_alu_y(if_alu_y),

    //imm generator
      .imm_gen_o(imm_gen_o),
      .imm_gen_type_o(imm_gen_type),
      .imm_gen_i(imm_gen_i),

      // 连接寄存器堆模块的信�???
    .rf_raddr_a(rf_raddr_a),
    .rf_rdata_a(rf_rdata_a),
    .rf_raddr_b(rf_raddr_b),
    .rf_rdata_b(rf_rdata_b),
    .rf_waddr(rf_waddr),
    .rf_wdata(rf_wdata),
    .rf_we(rf_we),

    // csrfile
    .csr_raddr_a(csr_raddr_a),
    .csr_rdata_a(csr_rdata_a),
    .csr_raddr_b(csr_raddr_b),
    .csr_rdata_b(csr_rdata_b),
    .csr_waddr(csr_waddr),
    .csr_wdata(csr_wdata),
    .csr_we(csr_we),

    // mtime
    .time_interupt(time_interupt),
    .csr_waddr_exp(csr_waddr_exp),
    .csr_wdata_exp(csr_wdata_exp),
    .csr_we_exp(csr_we_exp),

    // mmu
    .mode_out(mmu_mode)
  );


    imm_gen u_imm_gen (
        .imm_gen_i(imm_gen_o),
        .imm_gen_type_i(imm_gen_type),
        .imm_gen_o(imm_gen_i)
    );

    alu32 u_alu(
    .reset(sys_rst),
    .alu_a(alu_a),
    .alu_b(alu_b),
    .alu_op(alu_op),
    .alu_y_reg(alu_y)
    );

    alu32 u_if_alu(
        .reset(sys_rst),
        .alu_a(if_alu_a),
        .alu_b(if_alu_b),
        .alu_op(if_alu_op),
        .alu_y_reg(if_alu_y)
    );

    regfile32 u_regfile(
.clk(sys_clk),
.reset(sys_rst),
.waddr(rf_waddr),
.wdata(rf_wdata),
.we(rf_we),
.raddr_a(rf_raddr_a),
.rdata_a(rf_rdata_a),
.raddr_b(rf_raddr_b),
.rdata_b(rf_rdata_b)
);

  csrfile32 u_csr(
    //.leds(leds),
    .clk(sys_clk),
    .reset(sys_rst),
    .waddr(csr_waddr),
    .wdata(csr_wdata),
    .we(csr_we),
    .waddr_exp(csr_waddr_exp),
    .wdata_exp(csr_wdata_exp),
    .we_exp(csr_we_exp),
    .raddr_a(csr_raddr_a),
    .rdata_a(csr_rdata_a),
    .raddr_b(csr_raddr_b),
    .rdata_b(csr_rdata_b),
    .mtime_exceed_i(mtime_exceed),
    .time_interupt(time_interupt),

    .satp_out(mmu_satp)
  );
  /* =========== Lab5 Master end =========== */

  /* =========== Lab5 MUX begin =========== */
  // Wishbone MUX (Masters) => bus slaves
  logic wbs0_cyc_o;
  logic wbs0_stb_o;
  logic wbs0_ack_i;
  logic [31:0] wbs0_adr_o;
  logic [31:0] wbs0_dat_o;
  logic [31:0] wbs0_dat_i;
  logic [3:0] wbs0_sel_o;
  logic wbs0_we_o;

  logic wbs1_cyc_o;
  logic wbs1_stb_o;
  logic wbs1_ack_i;
  logic [31:0] wbs1_adr_o;
  logic [31:0] wbs1_dat_o;
  logic [31:0] wbs1_dat_i;
  logic [3:0] wbs1_sel_o;
  logic wbs1_we_o;

  logic wbs2_cyc_o;
  logic wbs2_stb_o;
  logic wbs2_ack_i;
  logic [31:0] wbs2_adr_o;
  logic [31:0] wbs2_dat_o;
  logic [31:0] wbs2_dat_i;
  logic [3:0] wbs2_sel_o;
  logic wbs2_we_o;

  logic wbs3_cyc_o;
  logic wbs3_stb_o;
  logic wbs3_ack_i;
  logic [31:0] wbs3_adr_o;
  logic [31:0] wbs3_dat_o;
  logic [31:0] wbs3_dat_i;
  logic [3:0] wbs3_sel_o;
  logic wbs3_we_o;

  wb_mux_4 wb_mux (
      .clk(sys_clk),
      .rst(sys_rst),

      // Master interface (to Lab5 master)
      .wbm_adr_i(wbm_adr_o),
      .wbm_dat_i(wbm_dat_o),
      .wbm_dat_o(wbm_dat_i),
      .wbm_we_i (wbm_we_o),
      .wbm_sel_i(wbm_sel_o),
      .wbm_stb_i(wbm_stb_o),
      .wbm_ack_o(wbm_ack_i),
      .wbm_err_o(),
      .wbm_rty_o(),
      .wbm_cyc_i(wbm_cyc_o),

      // Slave interface 0 (to BaseRAM controller)
      // Address range: 0x8000_0000 ~ 0x803F_FFFF
      .wbs0_addr    (32'h8000_0000),
      .wbs0_addr_msk(32'hFFC0_0000),

      .wbs0_adr_o(wbs0_adr_o),
      .wbs0_dat_i(wbs0_dat_i),
      .wbs0_dat_o(wbs0_dat_o),
      .wbs0_we_o (wbs0_we_o),
      .wbs0_sel_o(wbs0_sel_o),
      .wbs0_stb_o(wbs0_stb_o),
      .wbs0_ack_i(wbs0_ack_i),
      .wbs0_err_i('0),
      .wbs0_rty_i('0),
      .wbs0_cyc_o(wbs0_cyc_o),

      // Slave interface 1 (to ExtRAM controller)
      // Address range: 0x8040_0000 ~ 0x807F_FFFF
      .wbs1_addr    (32'h8040_0000),
      .wbs1_addr_msk(32'hFFC0_0000),

      .wbs1_adr_o(wbs1_adr_o),
      .wbs1_dat_i(wbs1_dat_i),
      .wbs1_dat_o(wbs1_dat_o),
      .wbs1_we_o (wbs1_we_o),
      .wbs1_sel_o(wbs1_sel_o),
      .wbs1_stb_o(wbs1_stb_o),
      .wbs1_ack_i(wbs1_ack_i),
      .wbs1_err_i('0),
      .wbs1_rty_i('0),
      .wbs1_cyc_o(wbs1_cyc_o),

      // Slave interface 2 (to UART controller)
      // Address range: 0x1000_0000 ~ 0x1000_FFFF
      .wbs2_addr    (32'h1000_0000),
      .wbs2_addr_msk(32'hFFFF_0000),

      .wbs2_adr_o(wbs2_adr_o),
      .wbs2_dat_i(wbs2_dat_i),
      .wbs2_dat_o(wbs2_dat_o),
      .wbs2_we_o (wbs2_we_o),
      .wbs2_sel_o(wbs2_sel_o),
      .wbs2_stb_o(wbs2_stb_o),
      .wbs2_ack_i(wbs2_ack_i),
      .wbs2_err_i('0),
      .wbs2_rty_i('0),
      .wbs2_cyc_o(wbs2_cyc_o),

      // Slave interface 3 (to UART controller)
      // Address range: 0x0200_0000 ~ 0x0200_FFFF
      .wbs3_addr    (32'h0200_0000),
      .wbs3_addr_msk(32'hFFFF_0000),

      .wbs3_adr_o(wbs3_adr_o),
      .wbs3_dat_i(wbs3_dat_i),
      .wbs3_dat_o(wbs3_dat_o),
      .wbs3_we_o (wbs3_we_o),
      .wbs3_sel_o(wbs3_sel_o),
      .wbs3_stb_o(wbs3_stb_o),
      .wbs3_ack_i(wbs3_ack_i),
      .wbs3_err_i('0),
      .wbs3_rty_i('0),
      .wbs3_cyc_o(wbs3_cyc_o)
  );

  /* =========== Lab5 MUX end =========== */

  /* =========== Lab5 Slaves begin =========== */
  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_base (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs0_cyc_o),
      .wb_stb_i(wbs0_stb_o),
      .wb_ack_o(wbs0_ack_i),
      .wb_adr_i(wbs0_adr_o),
      .wb_dat_i(wbs0_dat_o),
      .wb_dat_o(wbs0_dat_i),
      .wb_sel_i(wbs0_sel_o),
      .wb_we_i (wbs0_we_o),

      // To SRAM chip
      .sram_addr(base_ram_addr),
      .sram_data(base_ram_data),
      .sram_ce_n(base_ram_ce_n),
      .sram_oe_n(base_ram_oe_n),
      .sram_we_n(base_ram_we_n),
      .sram_be_n(base_ram_be_n)
  );

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_ext (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs1_cyc_o),
      .wb_stb_i(wbs1_stb_o),
      .wb_ack_o(wbs1_ack_i),
      .wb_adr_i(wbs1_adr_o),
      .wb_dat_i(wbs1_dat_o),
      .wb_dat_o(wbs1_dat_i),
      .wb_sel_i(wbs1_sel_o),
      .wb_we_i (wbs1_we_o),

      // To SRAM chip
      .sram_addr(ext_ram_addr),
      .sram_data(ext_ram_data),
      .sram_ce_n(ext_ram_ce_n),
      .sram_oe_n(ext_ram_oe_n),
      .sram_we_n(ext_ram_we_n),
      .sram_be_n(ext_ram_be_n)
  );

  // 串口控制器模�?
  // NOTE: 如果修改系统时钟频率，也�?要修改此处的时钟频率参数
  uart_controller #(
      .CLK_FREQ(10_000_000),
      .BAUD    (115200)
  ) uart_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .wb_cyc_i(wbs2_cyc_o),
      .wb_stb_i(wbs2_stb_o),
      .wb_ack_o(wbs2_ack_i),
      .wb_adr_i(wbs2_adr_o),
      .wb_dat_i(wbs2_dat_o),
      .wb_dat_o(wbs2_dat_i),
      .wb_sel_i(wbs2_sel_o),
      .wb_we_i (wbs2_we_o),

      // to UART pins
      .uart_txd_o(txd),
      .uart_rxd_i(rxd)
  );

  // 时钟中断控制器模�?
  mtime_controller mtime_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .wb_cyc_i(wbs3_cyc_o),
      .wb_stb_i(wbs3_stb_o),
      .wb_ack_o(wbs3_ack_i),
      .wb_adr_i(wbs3_adr_o),
      .wb_dat_i(wbs3_dat_o),
      .wb_dat_o(wbs3_dat_i),
      .wb_sel_i(wbs3_sel_o),
      .wb_we_i (wbs3_we_o),

      // 时钟中断信号
      .mtime_exceed_o(mtime_exceed)
      
  );

  /* =========== Lab5 Slaves end =========== */

endmodule
