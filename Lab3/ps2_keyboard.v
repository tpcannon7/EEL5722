`timescale 1ns / 1ps
`default_nettype none

module ps2_keyboard(
    input wire clk,
    input wire rst,
    
    input wire ps2_clk,
    input wire ps2_d,
    
    output wire [15:0] led
);

(* ASYNC_REG = "TRUE" *) reg [2:0] ps2_d_sync = 0, ps2_clk_sync = 0;

// detect falling edge of ps/2 clk from sync registers
wire ps2_clk_falling;

assign ps2_clk_falling = ((ps2_clk_sync[2] == 1'b1) && (ps2_clk_sync[1] == 1'b0));

reg [3:0] bit_cnt = 0;
reg [7:0] scan_code = 0;
reg parity_bit = 0;
reg start = 0, done = 0;

wire parity_check;
// odd parity check; 1's across scan_code and parity bit must be odd
assign parity_check = ((^scan_code ^ parity_bit) == 1'b1);

// ps/2 data/clk sync regs
always @(posedge clk) begin
    ps2_d_sync <= {ps2_d_sync[1], ps2_d_sync[0], ps2_d};
    ps2_clk_sync <= {ps2_clk_sync[1], ps2_clk_sync[0], ps2_clk};
end

// bit counterfor ps/2 packet
always @(posedge clk) begin
    if (rst) begin
        bit_cnt <= 0;
        done <= 0;
        start <= 0;
    end else if (ps2_clk_falling) begin
        if (bit_cnt == 4'd0 && ps2_d_sync[2] == 1'b0) begin
            start <= 1'b1;
            bit_cnt <= bit_cnt + 1'b1;
            done <= 1'b0;
        end else if (bit_cnt == 4'd10 && ps2_d_sync[2] == 1'b1) begin
            bit_cnt <= 0;
            start <= 1'b0;
            done <= 1'b1;
        end else if (start == 1'b1) begin
           bit_cnt <= bit_cnt + 1'b1;
        end
    end
end

// scan code and parity bit storage
always @(posedge clk) begin
    if (rst) begin
        scan_code <= 0;
        parity_bit <= 0;
    end else if (ps2_clk_falling) begin
        if (start) begin
            if (bit_cnt <= 4'd8) begin
                scan_code <= {ps2_d_sync[2], scan_code[7:1]};
            end else if (bit_cnt == 4'd9) begin
                parity_bit <= ps2_d_sync[2];
            end
        end
    end
end

reg [15:0] led_decode;
assign led = done ? led_decode : 16'h0000;

// decode scan code into LED output
always @(*) begin
    led_decode = 16'h0000;
    if (done && parity_check) begin
        case(scan_code)
            8'h45: led_decode = 16'h0000;
            8'h16: led_decode = 16'h0001;
            8'h1E: led_decode = 16'h0002;
            8'h26: led_decode = 16'h0003;
            8'h25: led_decode = 16'h0004;
            8'h2E: led_decode = 16'h0005;
            8'h36: led_decode = 16'h0006;
            8'h3D: led_decode = 16'h0007;
            8'h3E: led_decode = 16'h0008;
            8'h46: led_decode = 16'h0009;
            default: led_decode = 16'hFFFF; 
        endcase
    end
end

endmodule

`default_nettype wire
