`timescale 1ns / 1ps
module industry_profile #(
    parameter DATA_WIDTH = 12
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [2:0]             industry_sel,

    output reg  [DATA_WIDTH-1:0]  vib_thresh_high,
    output reg  [DATA_WIDTH-1:0]  vib_thresh_low,
    output reg  [DATA_WIDTH-1:0]  curr_thresh_high,
    output reg  [DATA_WIDTH-1:0]  curr_thresh_low,
    output reg  [DATA_WIDTH-1:0]  temp_thresh_high,
    output reg  [DATA_WIDTH-1:0]  temp_thresh_low,
    output reg  [2:0]             window_sel,   // 0:win=1 1:win=2 2:win=4 3:win=8 4:win=16

    // Confidence-engine scoring parameters, per industry
    output reg  [2:0]             vib_weight,
    output reg  [2:0]             curr_weight,
    output reg  [2:0]             temp_weight,
    output reg  [2:0]             trend_weight,
    output reg  [3:0]             confirm_thresh
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset into the general/default profile
            vib_thresh_high  <= 12'd100;
            vib_thresh_low   <= 12'd0;
            curr_thresh_high <= 12'd100;
            curr_thresh_low  <= 12'd0;
            temp_thresh_high <= 12'd100;
            temp_thresh_low  <= 12'd0;
            window_sel       <= 3'd2;        // window = 4
            vib_weight       <= 3'd2;
            curr_weight      <= 3'd2;
            temp_weight      <= 3'd1;
            trend_weight     <= 3'd1;
            confirm_thresh   <= 4'd4;
        end else begin
            case (industry_sel)
                3'b000: begin // Textile loom
                    vib_thresh_high  <= 12'd150;
                    vib_thresh_low   <= 12'd0;
                    curr_thresh_high <= 12'd250;
                    curr_thresh_low  <= 12'd0;
                    temp_thresh_high <= 12'd200;
                    temp_thresh_low  <= 12'd0;
                    window_sel       <= 3'd1;    // window = 2 (fast reaction)

                    vib_weight       <= 3'd2;
                    curr_weight      <= 3'd2;
                    temp_weight      <= 3'd1;
                    trend_weight     <= 3'd1;
                    confirm_thresh   <= 4'd4;    // vib+curr alone confirms
                end
                3'b001: begin // Cold storage
                    vib_thresh_high  <= 12'd300;
                    vib_thresh_low   <= 12'd0;
                    curr_thresh_high <= 12'd150;
                    curr_thresh_low  <= 12'd0;
                    temp_thresh_high <= 12'd80;
                    temp_thresh_low  <= 12'd20;   // floor - too cold means icing risk
                    window_sel       <= 3'd3;    // window = 8 
                    
                    vib_weight       <= 3'd1;
                    curr_weight      <= 3'd2;
                    temp_weight      <= 3'd2;
                    trend_weight     <= 3'd1;
                    confirm_thresh   <= 4'd4;    // curr+temp alone confirms
                end
                3'b010: begin // Job-shop / CNC
                    vib_thresh_high  <= 12'd400;
                    vib_thresh_low   <= 12'd0;
                    curr_thresh_high <= 12'd350;
                    curr_thresh_low  <= 12'd0;
                    temp_thresh_high <= 12'd300;
                    temp_thresh_low  <= 12'd0;
                    window_sel       <= 3'd2;    // window = 4
                    vib_weight       <= 3'd2;
                    curr_weight      <= 3'd2;
                    temp_weight      <= 3'd1;
                    trend_weight     <= 3'd1;
                    confirm_thresh   <= 4'd4;
                end
                default: begin 
                    vib_thresh_high  <= 12'd100;
                    vib_thresh_low   <= 12'd0;
                    curr_thresh_high <= 12'd100;
                    curr_thresh_low  <= 12'd0;
                    temp_thresh_high <= 12'd100;
                    temp_thresh_low  <= 12'd0;
                    window_sel       <= 3'd2;    // window = 4
                    vib_weight       <= 3'd2;
                    curr_weight      <= 3'd2;
                    temp_weight      <= 3'd1;
                    trend_weight     <= 3'd1;
                    confirm_thresh   <= 4'd4;
                end
            endcase
        end
    end

endmodule
