`default_nettype none

module ps2_keyboard (
    input wire clk,
    input wire rst,
    
    input wire ps2_clk,
    input wire ps2_d,

    input wire lpf_ps2_busy,
    
    output wire [15:0] led,
    output wire zero_press
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

// bit counter for ps/2 packet
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

reg zero_press_reg, zero_press_next;
assign zero_press = zero_press_reg;

reg [3:0] led_cnt, led_cnt_next;
assign led = done ? {12'h000, led_cnt} : 16'h0000;

// store if '1' if 0 key was pressed
always @(posedge clk) begin
    if (rst) begin
        zero_press_reg <= 0;
    end else begin
        zero_press_reg <= zero_press_next;
    end
end

// led counter to track number of LPF triggers
always @(posedge clk) begin
    if (rst) begin
        led_cnt <= 0;
    end else if (!lpf_ps2_busy) begin
        led_cnt <= led_cnt_next;
    end
end

// detect '0' to trigger LPF, incremenet led_cnt every filter call
always @(*) begin
    led_cnt_next = led_cnt;
    zero_press_next = 1'b0;
    if (done && parity_check) begin
        case(scan_code)
            8'h45: begin
                led_cnt_next = led_cnt + 1'b1;
                zero_press_next = 1'b1;
            end
            default: begin
                led_cnt_next = led_cnt;
                zero_press_next = 1'b0;
            end
        endcase
    end
end

endmodule

`default_nettype wire
