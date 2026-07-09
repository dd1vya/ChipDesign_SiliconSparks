`timescale 1ns / 1ps
module seven_seg_driver #(
    parameter CLK_FREQ = 100_000_000,
    parameter REFRESH_HZ_PER_DIGIT = 1000  // ~1kHz scan rate per digit -> flicker-free
)(
    input  wire        clk,
    input  wire        rst_n,

    // D1 bank (leftmost 4 digits)
    input  wire [3:0]  digit7, digit6, digit5, digit4,
    // D0 bank (rightmost 4 digits)
    input  wire [3:0]  digit3, digit2, digit1, digit0,

    output reg  [3:0]  d0_an,   // active-low anode select, D0 bank
    output reg  [7:0]  d0_seg,  // active-low segments, D0 bank
    output reg  [3:0]  d1_an,   // active-low anode select, D1 bank
    output reg  [7:0]  d1_seg   // active-low segments, D1 bank
);

    localparam integer DIV_MAX = CLK_FREQ / (REFRESH_HZ_PER_DIGIT * 8);
    localparam integer DIV_BITS = $clog2(DIV_MAX);

    reg [DIV_BITS-1:0] div_cnt;
    reg [2:0]          digit_sel;   // 0-3 -> D0 digits, 4-7 -> D1 digits

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt   <= 0;
            digit_sel <= 0;
        end else if (div_cnt == DIV_MAX - 1) begin
            div_cnt   <= 0;
            digit_sel <= digit_sel + 1'b1;
        end else begin
            div_cnt <= div_cnt + 1'b1;
        end
    end

    // Pick which digit's value is active this scan slot
    reg [3:0] active_digit;
    always @(*) begin
        case (digit_sel)
            3'd0: active_digit = digit0;
            3'd1: active_digit = digit1;
            3'd2: active_digit = digit2;
            3'd3: active_digit = digit3;
            3'd4: active_digit = digit4;
            3'd5: active_digit = digit5;
            3'd6: active_digit = digit6;
            default: active_digit = digit7;
        endcase
    end

    // Hex-to-segment lookup
    reg [7:0] seg_pattern;
    always @(*) begin
        case (active_digit)
            4'h0: seg_pattern = 8'b11000000;
            4'h1: seg_pattern = 8'b11111001;
            4'h2: seg_pattern = 8'b10100100;
            4'h3: seg_pattern = 8'b10110000;
            4'h4: seg_pattern = 8'b10011001;
            4'h5: seg_pattern = 8'b10010010;
            4'h6: seg_pattern = 8'b10000010;
            4'h7: seg_pattern = 8'b11111000;
            4'h8: seg_pattern = 8'b10000000;
            4'h9: seg_pattern = 8'b10010000;
            4'ha: seg_pattern = 8'b10001000;
            4'hb: seg_pattern = 8'b10000011;
            4'hc: seg_pattern = 8'b11000110;
            4'hd: seg_pattern = 8'b10100001;
            4'he: seg_pattern = 8'b10000110;
            default: seg_pattern = 8'b10001110; // 'F'
        endcase
    end

    wire is_d1_slot = digit_sel[2];   // 1 -> currently scanning a D1 digit

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d0_an  <= 4'hF;   // all digits off
            d1_an  <= 4'hF;
            d0_seg <= 8'hFF;
            d1_seg <= 8'hFF;
        end else begin
            d0_an  <= is_d1_slot ? 4'hF : ~(4'b1 << digit_sel[1:0]);
            d1_an  <= is_d1_slot ? ~(4'b1 << digit_sel[1:0]) : 4'hF;
            d0_seg <= seg_pattern;
            d1_seg <= seg_pattern;
        end
    end

endmodule
