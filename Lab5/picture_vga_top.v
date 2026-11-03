`default_nettype none

module picture_vga_top (
    input wire clk,
    
    input wire btnC,
    
    input wire PS2Clk,
    input wire PS2Data,
    
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    
    output wire Hsync,
    output wire Vsync,
    output wire [15:0] led
);

wire rst;
wire zero_press;
wire lpf_ps2_busy;

btn btn(
    .clk(clk),
    .btn_c(btnC),
    .rst(rst)
);

ps2_keyboard kb (
    .clk(clk),
    .rst(rst),
    .ps2_clk(PS2Clk),
    .ps2_d(PS2Data),
    .led(led),
    .zero_press(zero_press),
    .lpf_ps2_busy(lpf_ps2_busy)
);

vga_lpf_top vga_lpf (
    .clk(clk),
    .rst(rst),
    .vga_red(vgaRed),
    .vga_green(vgaGreen),
    .vga_blue(vgaBlue),
    .h_sync(Hsync),
    .v_sync(Vsync),
    .zero_press(zero_press),
    .lpf_ps2_busy(lpf_ps2_busy)
);

endmodule

`default_nettype wire
