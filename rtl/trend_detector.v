`timescale 1ns / 1ps
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
