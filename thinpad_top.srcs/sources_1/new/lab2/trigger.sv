module trigger(
input wire clk,
input wire push_btn,
input wire reset,
output wire trigger
);

reg pre_push;
reg reg_trigger;
always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
        pre_push <=1'b0;
        reg_trigger <= 1'b0;
    end
    else if (push_btn != pre_push) begin
        pre_push <= push_btn;
        if (push_btn == 1'b1) begin
            reg_trigger <= 1'b1;
        end
        else begin
            reg_trigger <= 1'b0;
        end
    end
    else begin
        reg_trigger <= 1'b0;
    end
end
assign trigger = reg_trigger;

endmodule
