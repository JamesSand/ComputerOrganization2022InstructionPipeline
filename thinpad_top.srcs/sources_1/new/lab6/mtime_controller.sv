module mtime_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
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

    // mtime exceeded signal
    output reg mtime_exceed_o
);

    reg [63:0] mtime_reg;
    reg [63:0] mtime_cmp_reg;
    reg [63:0] mtime_counter_reg;

    typedef enum logic {
        STATE_IDLE = 0,
        STATE_ACTION = 1
    } state_t;
    state_t state;  

    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            state <= STATE_IDLE;
            mtime_reg <= 0;
            mtime_cmp_reg <= 0;
            mtime_counter_reg <= 64'b0;
            wb_ack_o <= 0;
            wb_dat_o <= 0;
            mtime_exceed_o <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin

                    // mtime/mtimecmp read/write
                    if (wb_cyc_i && wb_stb_i) begin
                        if (wb_we_i) begin
                            if (wb_adr_i == 32'h0200_BFF8) begin  // mtime low 32
                                mtime_reg[31:0] <= wb_dat_i;
                            end else if (wb_adr_i == 32'h0200_BFFc) begin // mtime high 32
                                mtime_reg[63:32] <= wb_dat_i;
                            end else if (wb_adr_i == 32'h0200_4000) begin // mtimecmp low 32
                                mtime_cmp_reg[31:0] <= wb_dat_i;
                            end else if (wb_adr_i == 32'h0200_4004) begin // mtimecmp high 32
                                mtime_cmp_reg[63:32] <= wb_dat_i;
                            end
                        end else begin
                            if (wb_adr_i == 32'h0200_BFF8) begin  // mtime low 32
                                wb_dat_o <= mtime_reg[31:0];
                            end else if (wb_adr_i == 32'h0200_BFFc) begin // mtime high 32
                                wb_dat_o <= mtime_reg[63:32];
                            end else if (wb_adr_i == 32'h0200_4000) begin // mtimecmp low 32
                                wb_dat_o <= mtime_cmp_reg[31:0];
                            end else if (wb_adr_i == 32'h0200_4004) begin // mtimecmp high 32
                                wb_dat_o <= mtime_cmp_reg[63:32];
                            end
                        end
                        wb_ack_o <= 1;
                        state <= STATE_ACTION;
                    end 

                    // timer
                    else if (mtime_cmp_reg > 0) begin
                        if (mtime_reg >= mtime_cmp_reg) begin
                            mtime_exceed_o <= 1;
                        end else if (mtime_counter_reg == 64'd9) begin
                            mtime_counter_reg <= 64'b0;
                            mtime_reg <= mtime_reg + 64'b1;
                        end else begin
                            mtime_exceed_o <= 0;
                            mtime_counter_reg <= mtime_counter_reg + 64'b1;
                        end
                    end
                end

                STATE_ACTION: begin
                    wb_ack_o <= 0;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
