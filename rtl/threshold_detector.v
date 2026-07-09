`timescale 1ns / 1ps
//============================================================
// Module      : threshold_detector
// Description : Compares a filtered sensor reading against a
//               pair of profile-selected bounds (threshold_low,
//               threshold_high) and flags a fault whenever the
//               reading is outside that band.
//
//               Using a band instead of a single ceiling lets
//               one instance of this block cover both "too high"
//               faults (over-current, excess vibration) and "too
//               low" faults (e.g. a cold-storage compressor
//               running too cold - icing risk), purely by how
//               industry_profile sets threshold_low. Channels
//               that only care about an upper bound simply get
//               threshold_low tied to 0 by the profile, and the
//               low check never fires.
//
//               One comparator pair, one register stage - no
//               DSP, no memory.
//============================================================
module threshold_detector #(
    parameter DATA_WIDTH = 12
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire                   data_valid,
    input  wire [DATA_WIDTH-1:0]  threshold_high,
    input  wire [DATA_WIDTH-1:0]  threshold_low,

    output reg                    fault,
    output reg                    normal
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fault  <= 1'b0;
            normal <= 1'b1;
        end else if (data_valid) begin
            fault  <= (data_in > threshold_high) || (data_in < threshold_low);
            normal <= (data_in <= threshold_high) && (data_in >= threshold_low);
        end
    end

endmodule
