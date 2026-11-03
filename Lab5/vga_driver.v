`default_nettype none

module vga_driver (
    input wire clk,
    input wire rst,
    
    input wire [7:0] pixel,
    
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue,
    
    output wire h_sync,
    output wire v_sync,
    
    output wire frame_done,
    output [15:0] vga_mem_addr
);

// pixel intervals for each horizontal portion
localparam H_VISIBLE = 640;
localparam H_FRONT = 16;
localparam H_SYNC_PULSE = 6;
localparam H_BACK = 48;
localparam H_PIXELS = H_VISIBLE + H_FRONT + H_SYNC_PULSE + H_BACK;

// pixel intervals for each vertical portion
localparam V_VISIBLE = 480;
localparam V_FRONT = 10;
localparam V_SYNC_PULSE = 2;
localparam V_BACK = 33;
localparam V_PIXELS = V_VISIBLE + V_FRONT + V_SYNC_PULSE + V_BACK;

// hex codes for the colors, each 4-bit RGB channel
localparam [11:0] BLACK = 12'h000;
localparam [11:0] WHITE = 12'hFFF;

wire active_region, image_region;

reg [1:0] pixel_clk_div = 2'b00;
wire pixel_tick;

assign pixel_tick = (pixel_clk_div == 2'd3);

// 25 MHz clock divider derived from 100 MHz clock
always @(posedge clk) begin
    pixel_clk_div <= pixel_clk_div + 1'b1;
end

reg [$clog2(H_PIXELS)-1:0] h_sync_cnt = 0;
reg [$clog2(V_PIXELS)-1:0] v_sync_cnt = 0;

// active region and h/vsync signals
assign active_region = (h_sync_cnt < H_VISIBLE) && (v_sync_cnt < V_VISIBLE);
// fix this if it doesnt work
assign image_region = ((h_sync_cnt < 10'd448) && h_sync_cnt > 10'd191) && ((v_sync_cnt > 10'd111) && (v_sync_cnt < 10'd368));

assign h_sync = ~((h_sync_cnt > (H_VISIBLE + H_FRONT - 1)) && (h_sync_cnt < (H_VISIBLE + H_FRONT + H_SYNC_PULSE)));

assign v_sync = ~((v_sync_cnt > (V_VISIBLE + V_FRONT - 1)) && (v_sync_cnt < (V_VISIBLE + V_FRONT + V_SYNC_PULSE)));

// increment v_sync/h_sync counters (horiz/vertical pixel counters)
always @(posedge clk) begin
    if (rst) begin
        h_sync_cnt <= 0;
        v_sync_cnt <= 0;
    end else if (pixel_tick) begin
        if (h_sync_cnt == H_PIXELS - 1) begin
            h_sync_cnt <= 0;
            if (v_sync_cnt == V_PIXELS - 1) begin
                v_sync_cnt <= 0;
            end else begin
                v_sync_cnt <= v_sync_cnt + 1'b1;
            end
        end else begin
            h_sync_cnt <= h_sync_cnt + 1'b1;
        end
    end
end

wire [7:0] image_col, image_row;
assign image_col = h_sync_cnt - 192;
assign image_row = v_sync_cnt - 112;

assign frame_done = pixel_tick && (h_sync_cnt == H_PIXELS - 1) && (v_sync_cnt == V_PIXELS - 1);

assign vga_mem_addr = {image_row, image_col};

assign {vga_red, vga_green, vga_blue} = image_region ? {pixel[7:4], pixel[7:4], pixel[7:4]} : BLACK;

endmodule

`default_nettype wire
