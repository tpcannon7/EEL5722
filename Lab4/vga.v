`default_nettype none

module vga (
    input wire clk,
    input wire rst,
    
    input wire [3:0] key_press,
    
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

wire [6:0] font_addr;
wire [7:0] font_row;

reg [7:0] curr_font_row;
reg [3:0] curr_key_press;

blk_mem_gen_0 font_rom (
    .clka(clk),
    .ena(1'b1),
    .addra(font_addr),
    .douta(font_row)
);

wire active_region, inside_char;

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
assign inside_char = (h_sync_cnt < 8) && (v_sync_cnt < 8);

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
// capture key press at end of every full vga frame
always @(posedge clk) begin
    if (rst) begin
        v_sync_cnt <= 0;
        curr_key_press <= 4'd15;
    end else if (pixel_tick && h_sync_cnt == H_PIXELS - 1) begin
        if (v_sync_cnt == V_PIXELS - 1) begin
            v_sync_cnt <= 0;
            curr_key_press <= key_press;
        end else begin
            v_sync_cnt <= v_sync_cnt + 1'b1;
        end
    end
end

// address to font BRAM
assign font_addr = {curr_key_press, v_sync_cnt[2:0]};

// draw necessary pixels from font BRAM data, black if = 0, white = 1 per byte/row
assign {vga_red, vga_green, vga_blue} = !inside_char ? BLACK : 
                                        font_row[4'd7 - h_sync_cnt[2:0]] == 1'b1 ? WHITE : BLACK;

endmodule

`default_nettype wire