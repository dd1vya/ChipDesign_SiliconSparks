`timescale 1ns / 1ps
//============================================================
// Module      : industry_profile
// Description : Live-switchable MSME operating profile. A 3-bit
//               industry_sel picks the full threshold/window
//               operating point for vibration, current AND
//               temperature simultaneously, so the same IP core
//               is reused across verticals without touching RTL.
//
//               Every channel gets a (low, high) band rather
//               than a single ceiling: channels that only care
//               about an upper bound just get their low bound
//               tied to 0, so threshold_detector's band check
//               degenerates to a plain ceiling check for them
//               "for free".
//
//               industry_sel:
//                 000 - Textile loom     (fast-spinning, tight
//                                         vibration tolerance,
//                                         needs a quick-reacting
//                                         filter)
//                 001 - Cold storage     (compressor baseline is
//                                         naturally noisier/more
//                                         vibration-prone; current
//                                         draw is the more telling
//                                         signal for strain, and a
//                                         temperature FLOOR is set
//                                         since running too cold
//                                         means icing risk)
//                 010 - Job-shop / CNC   (heavier machinery, higher
//                                         normal vibration and
//                                         current draw)
//                 011 - General / default
//                 1xx - reserved, falls back to General
//============================================================
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
    output reg  [2:0]             window_sel   // 0:win=1 1:win=2 2:win=4 3:win=8 4:win=16
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
                end
                3'b001: begin // Cold storage
                    vib_thresh_high  <= 12'd300;
                    vib_thresh_low   <= 12'd0;
                    curr_thresh_high <= 12'd150;
                    curr_thresh_low  <= 12'd0;
                    temp_thresh_high <= 12'd80;
                    temp_thresh_low  <= 12'd20;   // floor - too cold means icing risk
                    window_sel       <= 3'd3;    // window = 8 (heavier smoothing)
                end
                3'b010: begin // Job-shop / CNC
                    vib_thresh_high  <= 12'd400;
                    vib_thresh_low   <= 12'd0;
                    curr_thresh_high <= 12'd350;
                    curr_thresh_low  <= 12'd0;
                    temp_thresh_high <= 12'd300;
                    temp_thresh_low  <= 12'd0;
                    window_sel       <= 3'd2;    // window = 4
                end
                default: begin // General / default (011 and reserved 1xx codes)
                    vib_thresh_high  <= 12'd100;
                    vib_thresh_low   <= 12'd0;
                    curr_thresh_high <= 12'd100;
                    curr_thresh_low  <= 12'd0;
                    temp_thresh_high <= 12'd100;
                    temp_thresh_low  <= 12'd0;
                    window_sel       <= 3'd2;    // window = 4
                end
            endcase
        end
    end

endmodule
