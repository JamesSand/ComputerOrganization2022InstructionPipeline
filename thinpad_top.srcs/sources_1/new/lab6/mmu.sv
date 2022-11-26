module mmu (
    input wire clk,
    input wire rst,

    // arbiter
    input wire [31:0] arbiter_addr_in,
    input wire [31:0] arbiter_data_in,
    output reg [31:0] arbiter_data_out,
    input wire arbiter_we_in,
    input wire [3:0] arbiter_sel_in,
    input wire arbiter_stb_in,
    input wire arbiter_cyc_in,
    output reg arbiter_ack_out,
    
    // mux
    output reg [31:0] mux_addr_out,
    output reg [31:0] mux_data_out,
    input wire [31:0] mux_data_in,
    output reg mux_we_out,
    output reg [3:0] mux_sel_out,
    output reg mux_stb_out,
    output reg mux_cyc_out,
    input wire mux_ack_in,

    // mode
    input wire [1:0] mode_in,
    // satp
    input wire [31:0] satp_in
);


// -------------------- decode part begin ---------------
logic satp_mode;
logic [21:0] satp_ppn;
logic page_table_enable;

logic [9:0] vpn_1;
logic [9:0] vpn_2;
logic [11:0] offset;

always_comb begin
    // satp decode
    satp_mode = satp_in[31];
    satp_ppn = satp_in[21:0];

    // page table enable
    if (satp_mode && (mode_in != 2'b11)) begin
        page_table_enable = 1;
    end else begin
        page_table_enable = 0;
    end

    vpn_1 = arbiter_addr_in[31:22];
    vpn_2 = arbiter_addr_in[21:12];
    offset = arbiter_addr_in[11:0];

end

// -------------------- decode part end ---------------


// state machine
typedef enum logic [2:0] {
    STATE_INIT = 0,
    STATE_READ_1_ACTION = 1,
    STATE_READ_1_DONE = 2,
    STATE_READ_2_ACTION = 3,
    STATE_READ_2_DONE = 4,
    STATE_PPN_ACTION = 5,
    STATE_PPN_DONE = 6
} state_p;

state_p page_table_state;

// additional signals
logic [31:0] pte_1;
logic [31:0] pte_2;
logic [11:0] pte_1_ppn_1;
logic [9:0] pte_1_ppn_0;
logic [11:0] pte_2_ppn_1;
logic [9:0] pte_2_ppn_0;

logic [31:0] arbiter_return_data_out;

always_comb begin
    pte_1_ppn_1 = pte_1[31:20];
    pte_1_ppn_0 = pte_1[19:10];
    pte_2_ppn_1 = pte_2[31:20];
    pte_2_ppn_0 = pte_2[19:10];
end

always_ff @ (posedge clk) begin
    if (rst) begin
        page_table_state <= STATE_INIT;
        pte_1 <= 32'b0;
        pte_2 <= 32'b0;
        arbiter_return_data_out <= 32'b0;
    end else begin
        case (page_table_state)
        STATE_INIT: begin
            if (page_table_enable) begin
                pte_1 <= 32'b0;
                pte_2 <= 32'b0;
                arbiter_return_data_out <= 32'b0;
                page_table_state <= STATE_READ_1_ACTION;
            end
        end

        STATE_READ_1_ACTION : begin
            if (mux_ack_in) begin
                // store next table address
                pte_1 <= mux_data_in;
                page_table_state <= STATE_READ_1_DONE;
            end
        end

        STATE_READ_1_DONE : begin
            page_table_state <= STATE_READ_2_ACTION;
        end

        STATE_READ_2_ACTION : begin
            if (mux_ack_in) begin
                // store physical address
                pte_2 <= mux_data_in;
                page_table_state <= STATE_READ_2_DONE;
            end
        end

        STATE_READ_2_DONE : begin
            page_table_state <= STATE_PPN_ACTION;
        end

        STATE_PPN_ACTION : begin
            if (mux_ack_in) begin
                // store real data
                arbiter_return_data_out <= mux_data_in;
                page_table_state <= STATE_PPN_DONE;
            end
        end

        STATE_PPN_DONE : begin
            page_table_state <= STATE_INIT;
        end

        endcase
    end
end

// output signals
always_comb begin
    mux_addr_out = arbiter_addr_in;
    mux_data_out = arbiter_data_in;
    mux_we_out = arbiter_we_in;
    mux_sel_out = arbiter_sel_in;
    mux_stb_out = arbiter_stb_in;
    mux_cyc_out = arbiter_cyc_in;
    arbiter_data_out = mux_data_in;
    arbiter_ack_out = mux_ack_in;
    if (page_table_enable) begin
        case (page_table_state)
        STATE_INIT: begin
            mux_addr_out = 0;
            mux_data_out = 0;
            mux_we_out = 0;
            mux_sel_out = 0;
            mux_stb_out = 0;
            mux_cyc_out = 0;
            arbiter_data_out = 0;
            arbiter_ack_out = 0;
        end
        STATE_READ_1_ACTION : begin
            mux_addr_out = satp_ppn << 12 + vpn_1 << 2;
            mux_data_out = 0;
            mux_we_out = 0; // read
            mux_sel_out = 4'b1111;
            mux_stb_out = 1;
            mux_cyc_out = 1;
            arbiter_ack_out = 0;
            arbiter_data_out = 0;
        end
        STATE_READ_1_DONE : begin
            mux_addr_out = 0;
            mux_data_out = 0;
            mux_we_out = 0;
            mux_sel_out = 0;
            mux_stb_out = 0;
            mux_cyc_out = 0;
            arbiter_ack_out = 0;
            arbiter_data_out = 0;
        end
        STATE_READ_2_ACTION : begin
            mux_addr_out = pte_1_ppn_1 << 22 + pte_1_ppn_0 << 12 + vpn_2 << 2;
            mux_data_out = 0;
            mux_we_out = 0; // read
            mux_sel_out = 4'b1111;
            mux_stb_out = 1;
            mux_cyc_out = 1;
            arbiter_ack_out = 0;
            arbiter_data_out = 0;
        end
        STATE_READ_2_DONE : begin
            mux_addr_out = 0;
            mux_data_out = 0;
            mux_we_out = 0;
            mux_sel_out = 0;
            mux_stb_out = 0;
            mux_cyc_out = 0;
            arbiter_ack_out = 0;
            arbiter_data_out = 0;
        end
        STATE_PPN_ACTION : begin
            mux_addr_out = pte_2_ppn_1 << 22 + pte_2_ppn_0 << 12 + offset;
            mux_data_out = 0;
            mux_we_out = 0; // read
            mux_sel_out = arbiter_sel_in;
            mux_stb_out = 1;
            mux_cyc_out = 1;
            arbiter_ack_out = 0;
            arbiter_data_out = 0;
        end
        STATE_PPN_DONE : begin
            mux_addr_out = 0;
            mux_data_out = 0;
            mux_we_out = 0;
            mux_sel_out = 0;
            mux_stb_out = 0;
            mux_cyc_out = 0;
            arbiter_ack_out = 1;
            arbiter_data_out = arbiter_return_data_out;
        end
        endcase
    end
end
    
endmodule