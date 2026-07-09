`timescale 1ns / 1ps
//============================================================
// Module      : confidence_engine
// Description : Lightweight scoring alternative to a hard AND
//               of fault flags. Each contributing signal adds a
//               WEIGHT to a running score:
//                 vibration fault   : + vib_weight
//                 current fault     : + curr_weight
//                 temperature fault : + temp_weight
//                 rising trend      : + trend_weight
//
//               A fault is "confirmed" once the total score
//               clears confirm_thresh. The weights and the
//               threshold are now INPUTS rather than fixed
//               parameters - industry_profile.v drives them per
//               industry_sel, so e.g. Cold Storage can weight
//               temperature as heavily as vibration, while
//               Textile/Job-shop keep vibration+current as the
//               dominant pair. Still just comparators/adders -
//               no multiplier, no memory, no processor.
//
//               sensor_agreement_count separately reports how
//               many of the three physical channels are
//               currently faulting (0-3), regardless of trend
//               or weighting, so the analytics output can show
//               "how many sensors agree" as its own number.
//============================================================
module confidence_engine (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        fault_vib,
    input  wire        fault_curr,
    input  wire        fault_temp,
    input  wire        trend_rising,

    // Per-industry scoring parameters (from industry_profile)
    input  wire [2:0]  vib_weight,
    input  wire [2:0]  curr_weight,
    input  wire [2:0]  temp_weight,
    input  wire [2:0]  trend_weight,
    input  wire [3:0]  confirm_thresh,

    output reg  [3:0]  confidence_score,       // 0..15 headroom (typical max ~6-8)
    output reg  [1:0]  sensor_agreement_count, // 0..3 sensors currently faulting
    output reg         confirmed_fault
);

    wire [3:0] score_comb =
          (fault_vib    ? vib_weight   : 3'd0)
        + (fault_curr   ? curr_weight  : 3'd0)
        + (fault_temp   ? temp_weight  : 3'd0)
        + (trend_rising ? trend_weight : 3'd0);

    wire [1:0] agree_comb = fault_vib + fault_curr + fault_temp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            confidence_score       <= 4'd0;
            sensor_agreement_count <= 2'd0;
            confirmed_fault        <= 1'b0;
        end else begin
            confidence_score       <= score_comb;
            sensor_agreement_count <= agree_comb;
            confirmed_fault        <= (score_comb >= confirm_thresh);
        end
    end

endmodule
