`timescale 1ns / 1ps
//============================================================
// Module      : confidence_engine
// Description : Lightweight scoring alternative to a hard AND
//               of fault flags. Each contributing signal adds a
//               fixed weight to a running score:
//                 vibration fault   : +2
//                 current fault     : +2
//                 temperature fault : +1
//                 rising trend      : +1
//               (max possible score = 6)
//
//               A fault is "confirmed" once the total score
//               clears CONFIRM_THRESHOLD. Because the weights are
//               fixed small integers, the whole block is just
//               comparators, adders and a small case/mux - no
//               multiplier, no memory, no processor.
//
//               sensor_agreement_count separately reports how
//               many of the three physical channels are
//               currently faulting (0-3), regardless of trend,
//               so the analytics output can show "how many
//               sensors agree" as its own number.
//============================================================
module confidence_engine #(
    parameter CONFIRM_THRESHOLD = 4   // out of a max possible score of 6
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        fault_vib,
    input  wire        fault_curr,
    input  wire        fault_temp,
    input  wire        trend_rising,

    output reg  [3:0]  confidence_score,       // 0..6
    output reg  [1:0]  sensor_agreement_count, // 0..3 sensors currently faulting
    output reg         confirmed_fault
);

    wire [3:0] score_comb =
          (fault_vib    ? 4'd2 : 4'd0)
        + (fault_curr   ? 4'd2 : 4'd0)
        + (fault_temp   ? 4'd1 : 4'd0)
        + (trend_rising ? 4'd1 : 4'd0);

    wire [1:0] agree_comb = fault_vib + fault_curr + fault_temp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            confidence_score       <= 4'd0;
            sensor_agreement_count <= 2'd0;
            confirmed_fault        <= 1'b0;
        end else begin
            confidence_score       <= score_comb;
            sensor_agreement_count <= agree_comb;
            confirmed_fault        <= (score_comb >= CONFIRM_THRESHOLD);
        end
    end

endmodule
