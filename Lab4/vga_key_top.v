`timescale 1ns / 1ps
`default_nettype none

module vga_key_top(
    input wire clk,
    
    input wire btnC,
    
    input wire PS2Clk,
    input wire PS2Data,
    
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    
    output wire Vsync,
    output wire Hsync,
    
    output wire [15:0] led
);

wire [3:0] key_press;
wire rst;

// button debounce module
btn btn (
    .clk(clk),
    .btn_c(btnC),
    .rst(rst)
);

// ps/2 keyboard module
ps2_keyboard key (
    .clk(clk),
    .rst(rst),
    .ps2_clk(PS2Clk),
    .ps2_d(PS2Data),
    .key_press(key_press),
    .led(led)
);

// vga driver + font ROM instantiation module
vga vga (
    .clk(clk),
    .rst(rst),
    .vga_red(vgaRed),
    .vga_green(vgaGreen),
    .vga_blue(vgaBlue),
    .v_sync(Vsync),
    .h_sync(Hsync),
    .key_press(key_press)
);
    
endmodule

`default_nettype wire
