`include "lab6include.vh"

module stall_controller(
    input wire if_stall_o, 
    input wire if_flush_o,
    output reg if_flush_i,
    output reg if_stall_i,

    input wire id_stall_o, 
    input wire id_flush_o,
    output reg id_flush_i,
    output reg id_stall_i,

    input wire exe_stall_o, 
    input wire exe_flush_o,
    output reg exe_flush_i,
    output reg exe_stall_i,

    input wire mem_stall_o, 
    input wire mem_flush_o,
    output reg mem_flush_i,
    output reg mem_stall_i,

    input wire if_wb_ack_i,
    input wire if_wb_stb_o,
    input wire mem_wb_ack_i,
    input wire mem_wb_stb_o
);

// if
always_comb begin
    if (if_wb_ack_i) begin
        if_flush_i = 0;
        if_stall_i = 0;
    end else if (if_stall_o) begin
        if_stall_i = 0;
        if_flush_i = 1;
    end else if (mem_stall_o || id_stall_o) begin
        if_stall_i = 1;
        if_flush_i = 0;
    end else if (if_flush_o) begin
        if_stall_i = 1;
        if_flush_i = 0;
    end else begin
        if_flush_i = 0;
        if_stall_i = 0;
    end
end

// id
always_comb begin
    if (mem_stall_o) begin
        id_stall_i = 1;
        id_flush_i = 0;
    end else if (id_stall_o) begin
        id_stall_i = 0;
        id_flush_i = 1;
    end else begin
        id_stall_i = 0;
        id_flush_i = 0;
    end
end

// exe
always_comb begin
    if (mem_stall_o) begin
        exe_stall_i = 1;
        exe_flush_i = 0;
    end else begin
        exe_stall_i = 0;
        exe_flush_i = 0;
    end
end

// mem
always_comb begin
    if (mem_wb_ack_i) begin
        mem_stall_i = 0;
        mem_flush_i = 0;
    end else if (mem_stall_o) begin
        mem_stall_i = 0;
        mem_flush_i = 1;
    end else if (if_stall_o) begin
        mem_stall_i = 0;
        mem_flush_i = 0;
    end else begin
        mem_stall_i = 0;
        mem_flush_i = 0;
    end
end

endmodule