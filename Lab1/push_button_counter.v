`timescale 1ns / 1ps
`default_nettype none 

module push_button_counter(
    input wire clk,
    input wire [2:0] btn, // btn[0] = C(enter), btn[1] = U(pper), btn[2] = L(ower)
    
    output wire [6:0] sev_seg_out,
    output wire [3:0] an
);

reg [1:0] btnC_sync, btnU_sync, btnL_sync;

always @(posedge clk) begin
    if (rst) begin
        btnC_sync <= 0;
        btnU_sync <= 0;
        btnL_sync <= 0;
    end else begin
        btnC_sync[0] <= btn[0];
        btnC_sync[1] <= btnC_sync[0];
        
        btnU_sync[0] <= btn[1];
        btnU_sync[1] <= btnU_sync[0];
        
        btnL_sync[0] <= btn[2];
        btnL_sync[1] <= btnL_sync[0];
    end
end

reg [1:0] active_btn;
always @(posedge clk) begin
    if (!btn_busy) begin
        if (btnC_sync[1]) begin
            active_btn <= 2'd1;
        end else if (btnU_sync[1]) begin
            active_btn <= 2'd2;
        end else if (btnL_sync[1]) begin
            active_btn <= 2'd3;
        end else begin
            active_btn <= 2'd0;
        end
    end else begin
        active_btn <= active_btn;
    end
end

reg [22:0] debounce_cnt;
reg btn_busy;
reg [2:0] btn_out;
reg no_change;

always @(posedge clk) begin
    if (active_btn != 2'd0) begin
        btn_busy <= 1'b1;
        debounce_cnt <= debounce_cnt + 1'b1;
        if (debounce_cnt == 23'd6500000) begin
            if (btn_out == {btnL_sync[1], btnU_sync[1], btnC_sync[1]}) begin
                no_change <= 1'b1;
            end else begin
                btn_out <= {btnL_sync[1], btnU_sync[1], btnC_sync[1]};
                no_change <= 1'b0;
            end
            btn_busy <= 1'b0;
        end
    end else begin
        btn_busy <= 1'b0;
        debounce_cnt <= 0;
        btn_out <= 0;
        no_change <= 1'b0;
    end
end

reg [3:0] seg0, seg1;
reg [3:0] seg0_next, seg1_next;
wire [3:0] seg_in;
reg rst;

always @(posedge clk) begin
    if (rst) begin
        seg0 <= 0;
        seg1 <= 0;
    end else if (!no_change && !btn_busy) begin
        seg0 <= seg0_next;
        seg1 <= seg1_next;
    end
end

always @(*) begin
    rst = 1'b0;
    seg0_next = seg0;
    seg1_next = seg1;
    
    case(btn_out)
        3'b001: rst = 1'b1;
        3'b010: begin
            if (seg1 == 4'd9) begin
                seg1_next = 4'd0;
            end else begin
                seg1_next = seg1 + 1'b1;
            end
        end
        3'b100: begin
            if (seg0 == 4'd9) begin
                seg0_next = 4'd0;
                if (seg1 == 4'd9) begin
                    seg1_next = 4'd0;
                end else begin
                    seg1_next = seg1 + 1'b1;
                end
            end else begin
                seg0_next = seg0 + 1'b1;
            end
        end
        default: begin
            seg1_next = seg1;
            seg0_next = seg0;
            rst = 1'b0;
        end
    endcase
end

reg [15:0] disp_refresh_cnt;
wire refresh;

// 2khz refresh
assign refresh = (disp_refresh_cnt == 16'd50000);

always @(posedge clk) begin
    if (rst) begin
        disp_refresh_cnt <= 0;
    end else if (disp_refresh_cnt == 16'd50000) begin
        disp_refresh_cnt <= 0;
    end else begin
        disp_refresh_cnt <= disp_refresh_cnt + 1'b1;
    end
end

reg active_disp;
always @(posedge clk) begin
    if (rst) begin
        active_disp <= 0;
    end else if (refresh && active_disp == 1'b0) begin
        active_disp <= 1'b1;
    end else if (refresh && active_disp == 1'b1) begin
        active_disp <= 1'b0;
    end
end

assign seg_in = (active_disp == 1'b0) ? seg0 : seg1;

seven_segment disp (
    .seven_seg_val_in(seg_in),
    .active_anode(active_disp),
    .out(sev_seg_out),
    .an(an)
);

endmodule

`default_nettype wire
