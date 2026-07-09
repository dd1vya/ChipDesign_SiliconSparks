`timescale 1ns / 1ps
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

    output reg  [3:0]  confidence_score,       // 0..15 headroom 
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
