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

logic satp_mode;
logic [21:0] satp_ppn;
logic page_table_enable;

always_comb begin
    // satp decode
    satp_mode = satp_in[31];
    satp_ppn = satp_in[21:0];
end


// for test
always_comb begin
    mux_addr_out = arbiter_addr_in;
    mux_data_out = arbiter_data_in;
    mux_we_out = arbiter_we_in;
    mux_sel_out = arbiter_sel_in;
    mux_stb_out = arbiter_stb_in;
    mux_cyc_out = arbiter_cyc_in;
    arbiter_data_out = mux_data_in;
    arbiter_ack_out = mux_ack_in;
end
    
endmodule