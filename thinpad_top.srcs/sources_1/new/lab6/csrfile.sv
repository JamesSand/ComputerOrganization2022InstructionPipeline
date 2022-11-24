module csrfile32(
input wire clk,
input wire reset,
input wire[11:0] waddr,
input wire[31:0] wdata,
input wire we,
input wire[11:0] raddr_a,
output reg[31:0] rdata_a,
input wire[11:0] raddr_b,
output reg[31:0] rdata_b
);

reg [31:0] mtvec;//0x305
reg [31:0] mscratch;//0x340
reg [31:0] mepc;//0x341 由于是32位机器 所以最低两位一直是0
reg [31:0] mcause;//0x342
reg [31:0] mstatus;//0x300 只有12:11的MPP[1:0]有用，别的都是0
reg [31:0] mie;//0x304 只有7的MTIE有用
reg [31:0] mip;//0x344 只有7的MTIP有用

always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
        mtvec <= 0;
        mscratch <= 0;
        mepc <= 0;
        mcause <= 0; 
        mstatus <= 0;
        mie <= 0;
        mip <= 0;
    end else if (we) begin
        case(waddr)
        12'h305: mtvec <= wdata;
        12'h340: mscratch <= wdata;
        12'h341: mepc[31:2] <= wdata[31:2];
        12'h342: mcause <= wdata;
        12'h300: mstatus[12:11] <= wdata[12:11];
        12'h304: mie[7] <= wdata[7];
        12'h344: mip[7] <= wdata[7];
        endcase
    end
end

always_comb begin
    case(raddr_a)
    12'h305: rdata_a = mtvec;
    12'h340: rdata_a = mscratch;
    12'h341: rdata_a = mepc;
    12'h342: rdata_a = mcause;
    12'h300: rdata_a = mstatus;
    12'h304: rdata_a = mie;
    12'h344: rdata_a = mip;
    default: rdata_a = 0;
    endcase
end

endmodule