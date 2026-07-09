`timescale 1ns / 1ps
module analytics_output #(
    parameter TS_WIDTH   = 32,
    parameter BUS_WIDTH  = TS_WIDTH + 4 + 7 + 2 + 2 + 1 + 3  // ts+conf+health+agree+trend+fault+profile
)(
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire [TS_WIDTH-1:0]    timestamp_in,
    input  wire [3:0]             confidence_score,
    input  wire [1:0]             sensor_agreement_count,
    input  wire                   confirmed_fault,
    input  wire                   trend_rising,
    input  wire                   trend_stable,
    input  wire                   trend_falling,
    input  wire [2:0]             industry_sel,
    input  wire                   data_valid,

    output reg  [TS_WIDTH-1:0]    timestamp_out,
    output reg  [3:0]             confidence_score_out,
    output reg  [6:0]             health_score,        // 0..100
    output reg  [1:0]             sensor_agreement_out,
    output reg  [1:0]             trend_status,        // 00 stable 01 rising 10 falling
    output reg                    confirmed_fault_out,
    output reg  [2:0]             industry_sel_out,
    output reg                    analytics_valid,

    output wire [BUS_WIDTH-1:0]   analytics_bus
);

    localparam [1:0] TREND_STABLE  = 2'b00,
                      TREND_RISING  = 2'b01,
                      TREND_FALLING = 2'b10;

    reg [6:0] health_lut;
    always @(*) begin
        case (confidence_score)
            4'd0:    health_lut = 7'd100;
            4'd1:    health_lut = 7'd85;
            4'd2:    health_lut = 7'd70;
            4'd3:    health_lut = 7'd55;
            4'd4:    health_lut = 7'd40;
            4'd5:    health_lut = 7'd20;
            default: health_lut = 7'd0;   // score 6 - worst case
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp_out         <= {TS_WIDTH{1'b0}};
            confidence_score_out  <= 4'd0;
            health_score          <= 7'd100;
            sensor_agreement_out  <= 2'd0;
            trend_status          <= TREND_STABLE;
            confirmed_fault_out   <= 1'b0;
            industry_sel_out      <= 3'd0;
            analytics_valid       <= 1'b0;
        end else if (data_valid) begin
            timestamp_out         <= timestamp_in;
            confidence_score_out  <= confidence_score;
            health_score          <= health_lut;
            sensor_agreement_out  <= sensor_agreement_count;
            trend_status          <= trend_rising  ? TREND_RISING  :
                                      trend_falling ? TREND_FALLING :
                                                       TREND_STABLE;
            confirmed_fault_out   <= confirmed_fault;
            industry_sel_out      <= industry_sel;
            analytics_valid       <= 1'b1;
        end else begin
            analytics_valid       <= 1'b0;
        end
    end

    assign analytics_bus = {timestamp_out, confidence_score_out, health_score,
                             sensor_agreement_out, trend_status,
                             confirmed_fault_out, industry_sel_out};

endmodule
