`timescale 1ns / 1ps
`default_nettype none

module memory_handler(
    input wire clk,
    input wire rst,
    
    input wire [15:0] lpf_addr, 
    input wire lpf_pixel_valid,
    input wire [7:0] lpf_new_pixel,
    output reg [7:0] lpf_req_pixel,

    input wire [15:0] vga_addr,
    output reg [7:0] vga_out_pixel,
    
    input wire vga_frame_done,
    input wire lpf_frame_done,

    input wire active_read_buf
);

wire [7:0] dout_buf0_a, dout_buf0_b, dout_buf1_a, dout_buf1_b;

wire we_buf0_b = (active_read_buf == 1'b1) ? lpf_pixel_valid : 1'b0;
wire we_buf1_b = (active_read_buf == 1'b0) ? lpf_pixel_valid : 1'b0;

assign vga_out_pixel = active_read_buf ? dout_buf1_a : dout_buf0_a;
assign lpf_req_pixel = active_read_buf ? dout_buf1_b : dout_buf0_b;

block_mem buf0 (
    // port a vga
    .clka  (clk),
    .addra (vga_addr),
    .dina  (8'd0),
    .douta (dout_buf0_a),
    .wea   (1'b0),
    // port b lpf
    .clkb  (clk),
    .addrb (lpf_addr),
    .dinb  (lpf_new_pixel),
    .doutb (dout_buf0_b),
    .web   (we_buf0_b)
);

block_mem buf1 (
    // port a vga
    .clka  (clk),
    .addra (vga_addr),
    .dina  (8'd0),
    .douta (dout_buf1_a),
    .wea   (1'b0),
    // port b lpf
    .clkb  (clk),
    .addrb (lpf_addr),
    .dinb  (lpf_new_pixel),
    .doutb (dout_buf1_b),
    .web   (we_buf1_b)
);

endmodule

`default_nettype wire
