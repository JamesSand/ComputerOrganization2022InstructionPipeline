module lab5_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // TODO: 添加�?要的控制信号，例如按键开关？
    input wire [31:0] dip_sw,
    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

  // TODO: 实现实验 5 的内�?+串口 Master
typedef enum logic [3:0] {
    STATE_IDLE = 0,
    STATE_READ_WAIT_ACTION = 1,
    STATE_READ_WAIT_CHECK = 2,
    STATE_READ_DATA_ACTION = 3,
    STATE_READ_DATA_DONE = 4,
    STATE_WRITE_SRAM_ACTION = 5,
    STATE_WRITE_SRAM_DONE = 6,
    STATE_WRITE_WAIT_ACTION = 7,
    STATE_WRITE_WAIT_CHECK = 9,
    STATE_WRITE_DATA_ACTION = 10,
    STATE_WRITE_DATA_DONE = 11
} state_t;

state_t state;

reg [31:0] addr;
reg [31:0] data;
reg [31:0] data_s;
reg [4:0] count;

always_ff @ (posedge clk_i) begin
  if (rst_i) begin
    state <= STATE_IDLE;
    addr <= dip_sw;
    count <= 0;
  end
  else begin
    case(state) 
      STATE_IDLE: begin
        //�?么信号是启动信号
        wb_stb_o <= 1;
        wb_cyc_o <= 1;
        wb_we_o <= 0;
        wb_adr_o <= 32'h10000005;
        wb_sel_o <= 32'h00000001;
        state <= STATE_READ_WAIT_ACTION;
        count <= count + 1;
      end
      
      STATE_READ_WAIT_ACTION: begin
        if (wb_ack_i == 1) begin
          state <= STATE_READ_WAIT_CHECK;
          wb_stb_o <= 0;
          wb_cyc_o <= 0;
          wb_we_o <= 0;
          data_s <= wb_dat_i;
        end
      end
      STATE_READ_WAIT_CHECK: begin
        if (data_s[0] == 1) begin
          state <= STATE_READ_DATA_ACTION;
          wb_stb_o <= 1;
          wb_cyc_o <= 1;
          wb_we_o <= 0;
          wb_adr_o <= 32'h10000000;
          wb_sel_o <= 32'h00000001;//怎么只读�?个字�?
        end
        else begin
          state <= STATE_READ_WAIT_ACTION;
          wb_stb_o <= 1;
          wb_cyc_o <= 1;
          wb_we_o <= 0;
        end
      end
      STATE_READ_DATA_ACTION: begin
        if (wb_ack_i == 1) begin
          state <= STATE_READ_DATA_DONE;
          wb_stb_o <= 0;
          wb_cyc_o <= 0;
          data <= wb_dat_i;
        end
      end
      STATE_READ_DATA_DONE: begin
        state <= STATE_WRITE_SRAM_ACTION;
        wb_stb_o <= 1;
        wb_cyc_o <= 1;
        wb_we_o <= 1;
        wb_adr_o <= addr;
        wb_dat_o <= data[7:0];
        wb_sel_o <= 32'h00000001;
      end

      STATE_WRITE_SRAM_ACTION: begin
        if (wb_ack_i == 1) begin
          state <= STATE_WRITE_SRAM_DONE;
          wb_stb_o <= 0;
          wb_cyc_o <= 0;
        end
      end
      STATE_WRITE_SRAM_DONE: begin
        state <= STATE_WRITE_WAIT_ACTION;
        wb_stb_o <= 1;
        wb_cyc_o <= 1;
        wb_we_o <= 0;
        wb_adr_o <= 32'h10000005;
        wb_sel_o <= 32'h00000001;
        addr <= addr + 4;
      end

      STATE_WRITE_WAIT_ACTION: begin
        if (wb_ack_i == 1) begin
          state <= STATE_WRITE_WAIT_CHECK;
          wb_stb_o <= 0;
          wb_cyc_o <= 0;
          data_s <= wb_dat_i;
        end
      end
      STATE_WRITE_WAIT_CHECK: begin
        if (data_s[5] == 1) begin
          state <= STATE_WRITE_DATA_ACTION;
          wb_stb_o <= 1;
          wb_cyc_o <= 1;
          wb_we_o <= 1;
          wb_adr_o <= 32'h10000000;
          wb_dat_o <= data[7:0];
          wb_sel_o <= 32'h00000001;
        end
        else begin
          state <= STATE_WRITE_WAIT_ACTION;
          wb_stb_o <= 1;
          wb_cyc_o <= 1;
          wb_we_o <= 0;
        end
      end
      STATE_WRITE_DATA_ACTION: begin
        if (wb_ack_i == 1) begin
          state <= STATE_WRITE_DATA_DONE;
          wb_stb_o <= 0;
          wb_cyc_o <= 0;
        end
      end
      STATE_WRITE_DATA_DONE: begin
        if (count < 10) begin
          state <= STATE_IDLE;
        end
      end
    endcase
  end
end
endmodule
