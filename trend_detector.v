`timescale 1ns / 1ps
//============================================================
// Module      : trend_detector
// Description : Lightweight predictive indicator. Compares the
//               current moving-average sample against the
//               previous one and reports rising / stable /
//               falling. A small DEADBAND keeps ordinary sensor
//               jitter from being reported as a trend - only a
//               change bigger than the deadband between two
//               consecutive filtered samples counts as a real
//               move.
//
//               This gives the confidence engine predictive
//               information ("things are trending up") before
//               any threshold is actually crossed.
//
//               Comparator-only hardware: one subtraction-sized
//               comparison against a small constant, no
//               multiplier, no divider, no memory beyond a single
//               register holding the previous average.
//============================================================
module trend_detector #(
    parameter DATA_WIDTH = 12,
    parameter DEADBAND   = 2
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire                   data_valid,

    output reg                    rising,
    output reg                    stable,
    output reg                    falling
);

    reg [DATA_WIDTH-1:0] prev_avg;
    reg                  have_prev;

    // Widen by one bit so "+ DEADBAND" can never wrap around the
    // top of the range and produce a false comparison result.
    wire [DATA_WIDTH:0] data_ext = {1'b0, data_in};
    wire [DATA_WIDTH:0] prev_ext = {1'b0, prev_avg};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_avg  <= {DATA_WIDTH{1'b0}};
            have_prev <= 1'b0;
            rising    <= 1'b0;
            stable    <= 1'b1;
            falling   <= 1'b0;
        end else if (data_valid) begin
            if (!have_prev) begin
                // Nothing to compare against yet on the very first sample
                rising    <= 1'b0;
                stable    <= 1'b1;
                falling   <= 1'b0;
                have_prev <= 1'b1;
            end else if (data_ext > prev_ext + DEADBAND) begin
                rising  <= 1'b1;
                stable  <= 1'b0;
                falling <= 1'b0;
            end else if (prev_ext > data_ext + DEADBAND) begin
                rising  <= 1'b0;
                stable  <= 1'b0;
                falling <= 1'b1;
            end else begin
                rising  <= 1'b0;
                stable  <= 1'b1;
                falling <= 1'b0;
            end
            prev_avg <= data_in;
        end
    end

endmodule
