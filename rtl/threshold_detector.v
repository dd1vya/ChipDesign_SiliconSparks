`timescale 1ns / 1ps
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
