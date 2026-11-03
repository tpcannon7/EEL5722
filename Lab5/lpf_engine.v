`timescale 1ns / 1ps
`default_nettype none

module lpf_engine(
    input wire clk,
    input wire rst,
    
    input wire refresh,
    input wire [7:0] mem_din,
    input wire pending_mem_swap,

    output reg [15:0] lpf_addr,
    output wire [7:0] new_pixel,
    output wire pixel_valid,
    output wire lpf_frame_done,
    output wire lpf_busy
);

localparam [2:0] IDLE = 3'b000, READ = 3'b001, SUM = 3'b010, DIV = 3'b011, WRITE = 3'b100;

reg [7:0] lpf_row_cnt, lpf_col_cnt;
wire last_pixel;
assign last_pixel = (lpf_row_cnt == 8'd255) && (lpf_col_cnt == 8'd255);

reg [3:0] neighbor_cnt;
wire upper, lower, left, right;

assign upper = (lpf_row_cnt == 8'd0);
assign lower = (lpf_row_cnt == 8'd255);
assign right = (lpf_col_cnt == 8'd255);
assign left = (lpf_col_cnt == 8'd0);

reg [2:0] curr_st = 0, next_st;

always @(posedge clk) begin
    if (rst) begin
        curr_st <= 0;
    end else begin
        curr_st <= next_st;
    end
end

always @(*) begin
    next_st = curr_st;
    lpf_frame_done = 1'b0;
    case(curr_st)
        IDLE: begin
            if (refresh && !pending_mem_swap) begin
                next_st = READ;
            end
        end
        READ: begin
            if (neighbor_cnt == 4'd9) begin
                next_st = DIV;
            end
        end
        DIV: begin
            next_st = WRITE;
        end
        WRITE: begin
            if (last_pixel) begin
                next_st = IDLE;
                lpf_frame_done = 1'b1;
            end else begin
                next_st = READ;
            end
        end
        default: begin
            next_st = IDLE;
        end
    endcase
end

// image is 256x256, row/col addressing to memory
always @(posedge clk) begin
    if (rst) begin
        lpf_row_cnt <= 0;
        lpf_col_cnt <= 0;
    end else if (curr_st == WRITE) begin
        if (lpf_col_cnt == 8'd255) begin
            lpf_col_cnt <= 0;
            if (lpf_row_cnt == 8'd255) begin
                lpf_row_cnt <= 0;
            end else begin
                lpf_row_cnt <= lpf_row_cnt + 1'b1;
            end
        end else begin
            lpf_col_cnt <= lpf_col_cnt + 1'b1;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        neighbor_cnt <= 0;
    end else if (curr_st == READ) begin
        neighbor_cnt <= neighbor_cnt + 1'b1;
    end else begin
        neighbor_cnt <= 0;
    end
end

// {0 1 2}
// {3 4 5}
// {6 7 8}
// addressing for neighbors + curr_pixel

always @(*) begin
    lpf_addr = 16'h0000;
    if (curr_st == READ) begin
        lpf_addr = {lpf_row_cnt, lpf_col_cnt};
        case(neighbor_cnt)
            4'd0: begin
                if (!upper && !left) begin
                    lpf_addr = {lpf_row_cnt - 1'b1, lpf_col_cnt - 1'b1};
                end
            end
            4'd1: begin
                if (!upper) begin
                    lpf_addr = {lpf_row_cnt - 1'b1, lpf_col_cnt};
                end
            end
            4'd2: begin
                if (!upper && !right) begin
                    lpf_addr = {lpf_row_cnt - 1'b1, lpf_col_cnt + 1'b1};
                end
            end
            4'd3: begin
                if (!left) begin
                    lpf_addr = {lpf_row_cnt, lpf_col_cnt - 1'b1};
                end
            end
            4'd4: begin
                lpf_addr = {lpf_row_cnt, lpf_col_cnt};
            end
            4'd5: begin
                if (!right) begin
                    lpf_addr = {lpf_row_cnt, lpf_col_cnt + 1'b1};
                end
            end
            4'd6: begin
                if (!lower && !left) begin
                    lpf_addr = {lpf_row_cnt + 1'b1, lpf_col_cnt - 1'b1};
                end
            end
            4'd7: begin
                if (!lower) begin
                    lpf_addr = {lpf_row_cnt + 1'b1, lpf_col_cnt};
                end
            end
            4'd8: begin
                if (!lower && !right) begin
                    lpf_addr = {lpf_row_cnt + 1'b1, lpf_col_cnt + 1'b1};
                end
            end
            default: begin
                lpf_addr = {lpf_row_cnt, lpf_col_cnt};
            end
        endcase
    end else if (curr_st == WRITE) begin
        lpf_addr = {lpf_row_cnt, lpf_col_cnt};
    end
end

reg [16:0] lpf_acc = 0;

always @(posedge clk) begin
    if (rst) begin
        lpf_acc <= 0;
    end else if (curr_st == READ && neighbor_cnt >= 1) begin
        lpf_acc <= lpf_acc + mem_din;
    end else if (curr_st == IDLE) begin
        lpf_acc <= 0;
    end
end

reg [23:0] lpf_res = 0;

always @(posedge clk) begin
    if (rst) begin
        lpf_res <= 0;
    end else if (curr_st == DIV) begin
        lpf_res <= lpf_acc * 6'd57;
    end
end

assign new_pixel = (curr_st == WRITE) ? lpf_res[16:9] : 8'h00;
assign pixel_valid = (curr_st == WRITE);
assign lpf_busy = (curr_st != IDLE);

endmodule

`default_nettype wire
