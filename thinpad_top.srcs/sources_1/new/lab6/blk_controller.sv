module blk_controller(
    input wire clk,
    input wire rst,

    // from wbs mux 
    input wire [31:0] addr_in,
    input wire [31:0] data_in,
    input wire we_in,
    input wire [3:0] sel_in,
    input wire stb_in,
    input wire cyc_in,

    output reg [31:0] data_out,
    output reg ack_out,


    // blk
    output reg blk_we_out,
    output reg [16:0] blk_addr_out,
    output reg [31:0] blk_data_out
);

typedef enum logic [2:0] {
    STATE_INIT = 0,
    STATE_WRITE = 1,
    STATE_DONE = 2
} state_t;

state_t state;

always_ff @(posedge clk) begin
    if (rst) begin
        state <= STATE_INIT;
    end else begin
        case (state)
            STATE_INIT : begin
                if (cyc_in && stb_in && we_in) begin
                    state <= STATE_WRITE;
                end
            end

            STATE_WRITE : begin
                state <= STATE_DONE;
            end

            STATE_DONE : begin
                state <= STATE_INIT;
            end

        endcase
    end
end

always_comb begin
    blk_we_out = 0;
    blk_addr_out = 0;
    blk_data_out = 0;
    data_out = 0;
    ack_out = 0;
    case (state)
        STATE_INIT : begin
        end

        STATE_WRITE : begin
            blk_we_out = 1;
            blk_addr_out = addr_in[16:0];
            blk_data_out = data_in[31:0];
        end

        STATE_DONE : begin
            ack_out = 1;
        end
    endcase
end


endmodule


