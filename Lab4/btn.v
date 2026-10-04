`timescale 1ns / 1ps
`default_nettype none

module btn(
    input wire clk,
    input wire btn_c,
    
    output wire rst   
);

(* ASYNC_REG = "TRUE" *) reg [2:0] btn_c_sync = 0;

// FSM for button debouncing
localparam [3:0] IDLE = 4'b0001, BTN_DEBOUNCE = 4'b0010, BTN_C_PRESS = 4'b0100, BTN_WAIT_RELEASE = 4'b1000;
reg [3:0] curr_st = IDLE, next_st;

reg [23:0] debounce_cnt = 0;
reg debounce_done;

assign rst = (curr_st == BTN_C_PRESS) || (curr_st == BTN_WAIT_RELEASE);

// debounce counter
always @(posedge clk) begin
    if (curr_st == BTN_DEBOUNCE) begin
        debounce_cnt <= debounce_cnt + 1'b1;
        if (debounce_cnt == 23'd6_500_500) begin
            debounce_done <= 1'b1;
        end
    end else begin
        debounce_cnt <= 0;
        debounce_done <= 1'b0;
    end
end

// button sync reg
always @(posedge clk) begin
    btn_c_sync <= {btn_c_sync[1], btn_c_sync[0], btn_c};
end

// sequential state storage
always @(posedge clk) begin
    curr_st <= next_st;
end

// combinational next state comp
always @(*) begin
    next_st = curr_st;
    
    case(curr_st)
        IDLE: begin
            if (btn_c_sync[2]) begin
                next_st = BTN_DEBOUNCE;
            end
        end
        BTN_DEBOUNCE: begin
            if (debounce_done) begin
                if (btn_c_sync[2]) begin
                    next_st = BTN_C_PRESS;
                end else begin
                    next_st = IDLE;
                end
            end
        end
        BTN_C_PRESS: begin
            next_st = BTN_WAIT_RELEASE;
        end
        BTN_WAIT_RELEASE: begin
            if (!btn_c_sync[2]) begin
                next_st = IDLE;
            end
        end
    endcase
end
      
endmodule

`default_nettype wire
