`timescale 1ns / 1ps
`default_nettype none

module vga_driver (
    input wire [2:0] color,
    input wire clk,
    input wire rst,
    
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue,
    
    output wire h_sync,
    output wire v_sync
);
    // pixel intervals for each horizontal portion
    localparam H_VISIBLE = 10'd640;
    localparam H_FRONT = 10'd16;
    localparam H_SYNC_PULSE = 10'd96;
    localparam H_BACK = 10'd48;
    localparam H_PIXELS = H_VISIBLE + H_FRONT + H_SYNC_PULSE + H_BACK;
    
    // pixel intervals for each vertical portion
    localparam V_VISIBLE = 10'd480;
    localparam V_FRONT = 10'd10;
    localparam V_SYNC_PULSE = 10'd2;
    localparam V_BACK = 10'd33;
    localparam V_PIXELS = V_VISIBLE + V_FRONT + V_SYNC_PULSE + V_BACK;

    // hex codes for the colors, each 4-bit RGB channel
    localparam BLACK = 12'h000;
    localparam WHITE = 12'hFFF;
    localparam RED = 12'hF00;
    localparam GREEN = 12'h0F0;
    localparam BLUE = 12'h00F;
    localparam YELLOW = 12'hFF0;
    localparam CYAN = 12'h0FF;
    localparam MAGENTA = 12'hF0F;
    
    reg [3:0] vga_red_r, vga_green_r, vga_blue_r;
    wire active_region;
    
    // wire <- reg so we can use case statement on VGA color decoder
    assign {vga_red, vga_green, vga_blue} = active_region ? {vga_red_r, vga_green_r, vga_blue_r} : BLACK;
    
    always @(*) begin
        case(color)
            3'b000: {vga_red_r, vga_green_r, vga_blue_r} = BLACK;
            3'b001: {vga_red_r, vga_green_r, vga_blue_r} = WHITE;
            3'b010: {vga_red_r, vga_green_r, vga_blue_r} = RED;
            3'b011: {vga_red_r, vga_green_r, vga_blue_r} = GREEN;
            3'b100: {vga_red_r, vga_green_r, vga_blue_r} = BLUE;
            3'b101: {vga_red_r, vga_green_r, vga_blue_r} = YELLOW;
            3'b110: {vga_red_r, vga_green_r, vga_blue_r} = CYAN;
            3'b111: {vga_red_r, vga_green_r, vga_blue_r} = MAGENTA;
            default: {vga_red_r, vga_green_r, vga_blue_r} = BLACK;
        endcase
    end
    
    reg [1:0] pixel_clk_div = 2'b00;
    wire pixel_tick;
    
    assign pixel_tick = (pixel_clk_div == 2'd3);
    
    // 25 MHz clock divider derived from 100 MHz clock
    always @(posedge clk) begin
        pixel_clk_div <= pixel_clk_div + 1'b1;
    end
    
    reg [$clog2(H_PIXELS):0] h_sync_cnt = 0;
    reg [$clog2(V_PIXELS):0] v_sync_cnt = 0;
    
    // active region and h/vsync signals
    assign active_region = (h_sync_cnt < H_VISIBLE) && (v_sync_cnt < V_VISIBLE);
    
    assign h_sync = ~((h_sync_cnt > (H_VISIBLE + H_FRONT - 1)) && (h_sync_cnt < (H_VISIBLE + H_FRONT + H_SYNC_PULSE)));
    
    assign v_sync = ~((v_sync_cnt > (V_VISIBLE + V_FRONT - 1)) && (v_sync_cnt < (V_VISIBLE + V_FRONT + V_SYNC_PULSE)));
    
    // increment h_sync when we finish one pixel (one clock cycle)
    always @(posedge clk) begin
        if (rst) begin
            h_sync_cnt <= 0;
        end else if (pixel_tick) begin
            if (h_sync_cnt == H_PIXELS - 1) begin
                h_sync_cnt <= 0;
            end else begin
                h_sync_cnt <= h_sync_cnt + 1'b1;
            end
        end
    end
    
    // increment v_sync when we finish an entire row
    always @(posedge clk) begin
        if (rst) begin
            v_sync_cnt <= 0;
        end else if (pixel_tick && h_sync_cnt == H_PIXELS - 1) begin
            if (v_sync_cnt == V_PIXELS - 1) begin
                v_sync_cnt <= 0;
            end else begin
                v_sync_cnt <= v_sync_cnt + 1'b1;
            end
        end
    end
    
endmodule
`default_nettype wire
