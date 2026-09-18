`timescale 1ns / 1ps
`default_nettype none

module vga_top(
    input wire clk,
    input wire btnU,
    input wire btnC,
    
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    
    output wire Vsync,
    output wire Hsync
);

    reg [2:0] btnU_sync = 3'b000, btnC_sync = 3'b000;
    
    always @(posedge clk) begin
        btnU_sync[0] <= btnU;
        btnU_sync[1] <= btnU_sync[0];
        btnU_sync[2] <= btnU_sync[1];
        
        btnC_sync[0] <= btnC;
        btnC_sync[1] <= btnC_sync[0];
        btnC_sync[2] <= btnC_sync[1];
    end
    
    localparam [3:0] IDLE = 4'b0000, BTN_DEBOUNCE = 4'b0001, BTNC_PRESS = 4'b0010, BTNU_PRESS = 4'b0011, BTN_WAIT_RELEASE = 4'b1111;
    reg [3:0] curr_st = IDLE, next_st = IDLE;
    
    (* keep = "true" *) reg [22:0] debounce_cnt = 0;
    wire btn_busy = (curr_st == BTN_DEBOUNCE);
    reg [1:0] btn_prev = 0;
    reg btn_change = 0;
    reg debounce_done = 0;
    
    always @(posedge clk) begin
            curr_st <= next_st;
    end
    
    always @(*) begin
        next_st = curr_st;
        case(curr_st)
            IDLE: begin
                if (btn_prev != {btnU_sync[2], btnC_sync[2]}) begin
                    next_st = BTN_DEBOUNCE;
                end
            end
            BTN_DEBOUNCE: begin
                if (debounce_done) begin
                    if (btn_change) begin
                        if (btnC_sync[2]) begin
                            next_st = BTNC_PRESS;
                        end else if (btnU_sync[2]) begin
                            next_st = BTNU_PRESS;
                        end
                    end else begin
                        next_st = IDLE;
                    end
                end
            end
            BTNU_PRESS: begin
                next_st = BTN_WAIT_RELEASE;
            end
            BTNC_PRESS: begin
                next_st = BTN_WAIT_RELEASE;
            end
            BTN_WAIT_RELEASE: begin
                if (!btnC_sync[2] && !btnU_sync[2]) begin
                    next_st = IDLE;
                end
            end
        endcase
    end
    
    always @(posedge clk) begin
        if (curr_st == BTN_DEBOUNCE) begin
            debounce_cnt <= debounce_cnt + 1'b1;
            
            if (debounce_cnt == 23'd6_500_000) begin
                debounce_done <= 1'b1;
                if (btn_prev != {btnU_sync[2], btnC_sync[2]}) begin
                    btn_prev <= {btnU_sync[2], btnC_sync[2]};
                    btn_change <= 1'b1;
                end else begin
                    btn_change <= 1'b0;
                end
            end
        end else begin
            btn_prev <= 2'b00;
            debounce_cnt <= 0;
            btn_change <= 1'b0;
            debounce_done <= 1'b0;
        end
    end

    reg [2:0] color = 0;
    wire rst, increment_color;
    
    assign increment_color = (curr_st == BTNU_PRESS);
    assign rst = (curr_st == BTNC_PRESS);
    
    always @(posedge clk) begin
        if (rst) begin
            color <= 3'b000;
        end else if (increment_color) begin
            color <= color + 1'b1;
        end
    end

    vga_driver vga (
        .color(color),
        .rst(rst),
        .clk(clk),
        .vga_red(vgaRed),
        .vga_green(vgaGreen),
        .vga_blue(vgaBlue),
        .h_sync(Hsync),
        .v_sync(Vsync)
    );
    
endmodule
`default_nettype wire
