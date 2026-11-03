`timescale 1ns / 1ps
`default_nettype none

module vga_lpf_top(
    input wire clk,
    input wire rst,
    
    input wire zero_press,
    
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue,
    
    output wire h_sync,
    output wire v_sync,

    output wire lpf_ps2_busy
);

wire [7:0] lpf_new_pixel, mem_lpf_din, mem_vga_pixel;
wire [15:0] lpf_mem_addr, vga_mem_addr;

wire vga_frame_done, lpf_pixel_valid, lpf_frame_done, lpf_busy;
assign lpf_ps2_busy = lpf_busy;

reg zero_press_last = 1'b0, mem_active_read_buf = 1'b0, swap_buf_next = 1'b0;
wire zero_press_pulse;
assign zero_press_pulse = zero_press && !zero_press_last;


always @(posedge clk) begin
    if (rst) begin
        zero_press_last <= 1'b0;
    end else begin
        zero_press_last <= zero_press;
    end
end

always @(posedge clk) begin
    if (rst) begin
        mem_active_read_buf <= 1'b0;
        swap_buf_next <= 1'b0;
    end else begin
        if (lpf_frame_done) begin
            swap_buf_next <= 1'b1;
        end else if (swap_buf_next && vga_frame_done) begin
            mem_active_read_buf <= ~mem_active_read_buf;
            swap_buf_next <= 1'b0;
        end
    end
end

memory_handler mem (
    .clk(clk),
    .rst(rst),
    .lpf_addr(lpf_mem_addr),
    .vga_addr(vga_mem_addr),
    .lpf_pixel_valid(lpf_pixel_valid),
    .lpf_new_pixel(lpf_new_pixel),
    .lpf_req_pixel(mem_lpf_din),
    .vga_out_pixel(mem_vga_pixel),
    .vga_frame_done(vga_frame_done),
    .lpf_frame_done(lpf_frame_done),
    .active_read_buf(mem_active_read_buf)
);

lpf_engine lpf (
    .clk(clk),
    .rst(rst),
    .refresh(zero_press_pulse),
    .new_pixel(lpf_new_pixel),
    .lpf_addr(lpf_mem_addr),
    .mem_din(mem_lpf_din),
    .pixel_valid(lpf_pixel_valid),
    .lpf_frame_done(lpf_frame_done),
    .pending_mem_swap(swap_buf_next),
    .lpf_busy(lpf_busy)
);

vga_driver vga (
    .clk(clk),
    .rst(rst),
    .vga_red(vga_red),
    .vga_green(vga_green),
    .vga_blue(vga_blue),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .frame_done(vga_frame_done),
    .vga_mem_addr(vga_mem_addr),
    .pixel(mem_vga_pixel)
);
    
endmodule

`default_nettype wire
