module TLB (
    input wire clk,
    input wire rst,

    input wire [20:0] tlb_vpn_i,
    input wire [20:0] tlb_ppn_i,
    input wire tlb_we_i,
    output reg [20:0] tlb_ppn_o,
    output reg tlb_hit_o,
    
    input wire clear_i
);

reg [19:0] TLB_vpn_table_reg[0:15];
reg [19:0] TLB_ppn_table_reg[0:15];
reg [3:0] TLB_current_top;
integer i, j;

// read
always_comb begin
    tlb_ppn_o = 20'b0;
    tlb_hit_o = 1'b0;
    for (i = 0; i < 16; i++) begin
        if (tlb_vpn_i == TLB_vpn_table_reg[i]) begin
            tlb_ppn_o = TLB_ppn_table_reg[i];
            tlb_hit_o = 1'b1;
        end
    end
end


// write
always_ff @ (posedge clk) begin
    if (rst || clear_i) begin
        for (j = 0; j < 16; j++) begin
            TLB_vpn_table_reg[j] <= 20'b0;
            TLB_ppn_table_reg[j] <= 20'b0;
        end
        TLB_current_top <= 4'b0;
    end else if (tlb_we_i) begin
        TLB_vpn_table_reg[TLB_current_top] <= tlb_vpn_i;
        TLB_ppn_table_reg[TLB_current_top] <= tlb_ppn_i;
        if (TLB_current_top == 4'b1111) TLB_current_top <= TLB_current_top + 4'b1;
        else TLB_current_top <= TLB_current_top + 4'b1;
    end
end

endmodule