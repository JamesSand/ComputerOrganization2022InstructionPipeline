module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n,
    output reg sram_oe_n,
    output reg sram_we_n,
    output reg [SRAM_BYTES-1:0] sram_be_n
);

  // TODO: 实现 SRAM 控制器
  typedef enum logic [2:0] {
    STATE_IDLE = 0,
    STATE_READ = 1,
    STATE_READ_2 = 2,
    STATE_WRITE = 3,
    STATE_WRITE_2 = 4,
    STATE_WRITE_3 = 5,
    STATE_DONE = 6
} state_t;

state_t state;

reg [31:0] sram_data_i_comb;
reg [31:0] sram_data_o_comb;
wire sram_data_t_comb;
reg sram_data_t_reg;

assign sram_data = sram_data_t_comb ? 32'bz : sram_data_o_comb;
assign sram_data_i_comb = sram_data;
assign sram_data_t_comb = sram_data_t_reg;

always_ff @ (posedge clk_i) begin
    if (rst_i) begin
        state <= STATE_IDLE;
        wb_ack_o <= 0;
        sram_ce_n <= 1;
        sram_oe_n <= 1;
        sram_we_n <= 1;
        sram_be_n <= 0;
    end else begin
        case (state)
            STATE_IDLE: begin
                wb_ack_o <= 0;
                if (wb_stb_i && wb_cyc_i) begin
                    if (wb_we_i) begin
                        state <= STATE_WRITE;
                        sram_addr <= wb_adr_i/4;//[:2];//除以4
                        sram_oe_n <= 1;
                        sram_ce_n <= 0;
                        sram_we_n <= 1;
                        sram_be_n <= ~wb_sel_i;//计算字节
                        sram_data_t_reg <= 1;
                    end else begin
                        state <= STATE_READ;
                        sram_addr <= wb_adr_i/4;//[:2];//除以4，截取
                        sram_oe_n <= 0;
                        sram_ce_n <= 0;
                        sram_we_n <= 1;
                        sram_be_n = 32'b0;//计算字节
                        sram_data_t_reg <= 1;
                    end
                end
            end
            STATE_DONE: begin
              state <= STATE_IDLE;
              wb_ack_o <=  0;
            end

            STATE_READ: begin
                state <= STATE_READ_2;
            end
            STATE_READ_2: begin
              state <= STATE_DONE;
              wb_dat_o <= sram_data_i_comb;
              wb_ack_o <=  1;
              sram_ce_n <= 1;
              sram_oe_n <= 1;
            end

            STATE_WRITE: begin
              state <= STATE_WRITE_2;
              sram_we_n <= 0;
              sram_data_t_reg <= 0;
              sram_data_o_comb[7:0] <= sram_be_n[0]?sram_data_i_comb[7:0]:wb_dat_i[7:0];
              sram_data_o_comb[15:8] <= sram_be_n[1]?sram_data_i_comb[15:8]:wb_dat_i[15:8];
              sram_data_o_comb[23:16] <= sram_be_n[2]?sram_data_i_comb[23:16]:wb_dat_i[23:16];
              sram_data_o_comb[31:24] <= sram_be_n[3]?sram_data_i_comb[31:24]:wb_dat_i[31:24];
            end
            STATE_WRITE_2: begin
              state <= STATE_WRITE_3;
              sram_we_n <= 1;
              sram_data_t_reg <= 1;
            end
            STATE_WRITE_3: begin
              state <= STATE_DONE;
              wb_ack_o <=  1;
              sram_ce_n <= 1;
            end
            // ...
        endcase
    end
end

endmodule
