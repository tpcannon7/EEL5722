`timescale 1ns / 1ps

module seven_segment(
    input wire [3:0] seven_seg_val_in,
    input wire active_anode, // 0 = LD0, 1 = LD1
    output wire [6:0] out,
    output wire [3:0] an
);

// these two are off
assign an[0] = 1'b1;
assign an[1] = 1'b1;

assign an[2] = (active_anode == 1'b0) ? 1'b0 : 1'b1;
assign an[3] = (active_anode == 1'b1) ? 1'b0 : 1'b1;

reg [6:0] seg_out;
assign out = seg_out;

always @(*) begin
    case(seven_seg_val_in)
        4'd0: seg_out = 7'b1000000;
        4'd1: seg_out = 7'b1111001;
        4'd2: seg_out = 7'b0100100;
        4'd3: seg_out = 7'b0110000;
        4'd4: seg_out = 7'b0011001;
        4'd5: seg_out = 7'b0010010;
        4'd6: seg_out = 7'b0000010;
        4'd7: seg_out = 7'b1111000;
        4'd8: seg_out = 7'b0000000;
        4'd9: seg_out = 7'b0010000;
        default: seg_out = 7'b1000000;
    endcase
end



endmodule
