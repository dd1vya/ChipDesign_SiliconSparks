`timescale 1ns / 1ps
//============================================================
// Module      : moving_avg_filter
// Description : Hardware-efficient configurable moving-average
//               filter. Window size is restricted to powers of
//               two (1,2,4,8,16) so divide-by-N reduces to a
//               cheap right-shift instead of a divider. This is
//               what makes the filter reusable across vibration,
//               temperature and current sensors without redesign.
//
//               UNCHANGED from the original source - instantiated
//               three times in edge_top.v (one per channel) instead
//               of being time-shared through sensor_sel.
//============================================================
module moving_avg_filter #(
    parameter DATA_WIDTH = 12,
    parameter MAX_WINDOW = 16,
    parameter ACC_WIDTH  = DATA_WIDTH + 5   // headroom for sum of 16 samples
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [DATA_WIDTH-1:0]    data_in,
    input  wire                     data_in_valid,
    input  wire [2:0]               window_sel,   // 0..4 -> window = 2^window_sel
                                                    // 0:1  1:2  2:4  3:8  4:16
    output reg  [DATA_WIDTH-1:0]    data_out,
    output reg                      data_out_valid
);
    // Sample history (deepest window supported)
    reg [DATA_WIDTH-1:0] hist [0:MAX_WINDOW-1];
    integer i;
    // Shift new sample into history on every valid input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < MAX_WINDOW; i = i + 1)
                hist[i] <= {DATA_WIDTH{1'b0}};
        end else if (data_in_valid) begin
            hist[0] <= data_in;
            for (i = 1; i < MAX_WINDOW; i = i + 1)
                hist[i] <= hist[i-1];
        end
    end
    // Combinational sum over the selected window
    reg [ACC_WIDTH-1:0] window_sum;
    always @(*) begin
        case (window_sel)
            3'd0: window_sum = hist[0];
            3'd1: window_sum = hist[0] + hist[1];
            3'd2: window_sum = hist[0] + hist[1] + hist[2] + hist[3];
            3'd3: window_sum = hist[0] + hist[1] + hist[2] + hist[3] +
                                hist[4] + hist[5] + hist[6] + hist[7];
            3'd4: window_sum = hist[0] + hist[1] + hist[2]  + hist[3]  +
                                hist[4] + hist[5] + hist[6]  + hist[7]  +
                                hist[8] + hist[9] + hist[10] + hist[11] +
                                hist[12]+ hist[13]+ hist[14] + hist[15];
            default: window_sum = hist[0];
        endcase
    end
    // Average = sum >> window_sel  (divide by 2^window_sel via shift)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out       <= {DATA_WIDTH{1'b0}};
            data_out_valid <= 1'b0;
        end else begin
            data_out       <= window_sum >> window_sel;
            data_out_valid <= data_in_valid;
        end
    end
endmodule
