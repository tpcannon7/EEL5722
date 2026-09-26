`timescale 1ns / 1ps
`default_nettype none

module ps2_top (
    input wire clk,
    input wire btnC,
    input wire PS2Clk,
    input wire PS2Data,
    
    output wire [15:0] led
);

wire rst;

// ps/2 keyboard rx
ps2_keyboard ps2_kb (
    .clk(clk),
    .rst(rst),
    .ps2_clk(PS2Clk),
    .ps2_d(PS2Data),
    .led(led)
);

// button debounce handler
btn_debounce db (
    .clk(clk),
    .btn_c(btnC),
    
    .rst(rst)
);

endmodule

`default_nettype wire