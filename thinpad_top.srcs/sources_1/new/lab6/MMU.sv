
module mmu(
    input wire clk,
    input wire rst,

    input wire [31:0] arbiter_addr_i,
    input wire [31:0] arbiter_data_i,
    output reg [31:0] arbiter_data_o,
    input wire arbiter_we_i,
    input wire arbiter_sel_i,
    input wire arbiter_stb_i,
    input wire arbiter_cyc_i,
    output reg arbiter_ack_o,

    output reg [31:0] mux_addr_o,
    input wire [31:0] mux_data_i,
    output reg [31:0] mux_data_o,
    output reg mux_we_o,
    output reg mux_sel_o,
    output reg mux_stb_o,
    output reg mux_cyc_o,
    input wire mux_ack_i,

    input wire [1:0] mode, // mode which running on the processor
    input wire [31:0] satp // assgin satp direcrly from csr file
);

logic [9:0] vpn_1;
logic [9:0] vpn_2;
logic [11:0] offset;
logic [19:0] satp_ppn; // ignore 2 left side, table1 base
logic [19:0] pte_ppn; // ignore 2 left side, table2 base
logic [31:0] ppn;

logic [31:0] mux_data_reg;

// rename input signals
always_comb begin
    vpn_1 = arbiter_addr_i[31:22];
    vpn_2 = arbiter_addr_i[21:12];
    offset = arbiter_addr_i[11:0];
    satp_ppn = satp[19:0];
end

typedef enum logic [3:0] {
    STATE_INIT = 0,
    STATE_READ_TABLE_1 = 1,
    STATE_READ_1_DONE = 2,
    STATE_READ_TABLE_2 = 3,
    STATE_READ_2_DONE = 4,
    STATE_ACTION_PPN = 5,
    STATE_PPN_DONE = 6,
    STATE_MACHINE_ACTION = 7,
    STATE_MACHINE_DONE = 8
} state_p;
state_p state_page;

always_ff @(posedge clk) begin
    if(rst) begin
        // clean siganals to arbiter
        arbiter_data_o <= 32'h0;
        arbiter_ack_o <= 1'b0;
        // clean signals to mux
        mux_addr_o <= 32'h0;
        mux_data_o <= 32'h0;
        mux_we_o <= 1'b0;
        mux_sel_o <= 1'b0;
        mux_stb_o <= 1'b0;
        mux_cyc_o <= 1'b0;
        // reset state
        state_page <= STATE_INIT;
        // reset ppn
        pte_ppn <= 20'h0;
        ppn <= 20'h0;
        // reset reg
        mux_data_reg <= 32'h0;
    end else begin
        case (state_page)
            STATE_INIT: begin
                if (arbiter_cyc_i) begin
                    if (mode == 2'b00) begin // user mode
                        state_page <= STATE_READ_TABLE_1;
                    end else begin // machine mode and other modes
                        state_page <= STATE_MACHINE_ACTION;
                    end
                end
            end
            STATE_MACHINE_ACTION : begin
                if (mux_ack_i) begin
                    state_page <= STATE_INIT;
                    // retrun mux data to arbiter
                    mux_data_reg <= mux_data_i;
                end
            end
            STATE_MACHINE_DONE : begin
                state_page <= STATE_INIT;
            end
            STATE_READ_TABLE_1: begin
                if (mux_ack_i) begin
                    state_page <= STATE_READ_1_DONE;
                    // pte is ready
                    pte_ppn <= mux_data_i[29:10];
                end
            end
            STATE_READ_1_DONE : begin
                state_page <= STATE_READ_TABLE_2;
            end
            STATE_READ_TABLE_2: begin
                if (mux_ack_i) begin
                    state_page <= STATE_READ_2_DONE;
                    // ppn is ready
                    ppn <= mux_data_i;
                end
            end
            STATE_READ_2_DONE : begin
                state_page <= STATE_ACTION_PPN;
            end
            STATE_ACTION_PPN: begin
                if (mux_ack_i) begin
                    state_page <= STATE_PPN_DONE;
                    // real data is ready
                    mux_data_reg <= mux_data_i;
                end
            end
            STATE_PPN_DONE : begin
                state_page <= STATE_INIT;
            end
        endcase
    end
end

// state machine combine
always_comb begin
    // clean all signals
    mux_addr_o = 32'h0;
    mux_data_o = 32'h0;
    mux_we_o = 1'b0;
    mux_sel_o = 1'b0;
    mux_stb_o = 1'b0;
    mux_cyc_o = 1'b0;
    arbiter_data_o = 32'h0;
    arbiter_ack_o = 1'b0;

    case (state_page) 
        // STATE INIT empty
        STATE_MACHINE_ACTION : begin
            mux_addr_o = arbiter_addr_i;
            mux_data_o = arbiter_data_i;
            mux_we_o = arbiter_we_i;
            mux_sel_o = arbiter_sel_i;
            mux_stb_o = arbiter_stb_i;
            mux_cyc_o = arbiter_cyc_i;
        end
        STATE_MACHINE_DONE : begin
            arbiter_data_o = mux_data_reg;
            arbiter_ack_o = 1'b1;
        end
        STATE_READ_TABLE_1 : begin
            mux_addr_o = {satp_ppn, vpn_1, 2'b00}; // len satp ppn = 20, len vpn1 = 10, len offset = 2
            mux_we_o = 1'b0; // 0 for read
            mux_sel_o = 4'b1111;
            mux_stb_o = 1'b1;
            mux_cyc_o = 1'b1;
        end
        // STATE_READ_1_DONE 
        STATE_READ_TABLE_2 : begin
            mux_addr_o = {pte_ppn, vpn_2, 2'b00}; // len satp ppn = 20, len vpn2 = 10, len offset = 2
            mux_we_o = 1'b0; // 0 for read
            mux_sel_o = 4'b1111;
            mux_stb_o = 1'b1;
            mux_cyc_o = 1'b1;
        end
        // STATE_READ_2_DONE 
        STATE_ACTION_PPN : begin
            mux_addr_o = ppn; // len ppn = 32
            mux_we_o = arbiter_we_i; // 0 for read
            mux_sel_o = arbiter_sel_i;
            mux_stb_o = 1'b1;
            mux_cyc_o = 1'b1;
        end
        STATE_PPN_DONE : begin
            arbiter_data_o = mux_data_reg;
            arbiter_ack_o = 1'b1;
        end
    endcase
end

    
endmodule
