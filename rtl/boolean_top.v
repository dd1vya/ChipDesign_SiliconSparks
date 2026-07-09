`timescale 1ns / 1ps

module boolean_top #(
    parameter DATA_WIDTH = 12,
    parameter TS_WIDTH    = 32,
    parameter CLK_FREQ_HZ = 100_000_000,
    parameter SAMPLE_HZ   = 4     
)(
    input  wire        clk,
    input  wire [3:0]  btn,
    input  wire [15:0] sw,
    output wire [15:0] led,

    output wire [3:0]  D0_AN,
    output wire [7:0]  D0_SEG,
    output wire [3:0]  D1_AN,
    output wire [7:0]  D1_SEG,

    output wire [2:0]  RGB0,
    output wire [2:0]  RGB1
);

    //-------------------------------------------------------
    // Reset + slow sample strobe
    //-------------------------------------------------------
    wire rst_n = ~btn[0];

    localparam integer SAMPLE_DIV = CLK_FREQ_HZ / SAMPLE_HZ;
    localparam integer SAMPLE_BITS = $clog2(SAMPLE_DIV);
    reg [SAMPLE_BITS-1:0] sample_cnt;
    reg                   sample_en;
    reg                   heartbeat;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt <= 0;
            sample_en  <= 1'b0;
            heartbeat  <= 1'b0;
        end else if (sample_cnt == SAMPLE_DIV - 1) begin
            sample_cnt <= 0;
            sample_en  <= 1'b1;
            heartbeat  <= ~heartbeat;
        end else begin
            sample_cnt <= sample_cnt + 1'b1;
            sample_en  <= 1'b0;
        end
    end

    //-------------------------------------------------------
    // Switches
    //-------------------------------------------------------
    wire [DATA_WIDTH-1:0] vib_in  = {sw[15:10], 6'b0};  // step = 64, range 0-4032
    wire [DATA_WIDTH-1:0] curr_in = {sw[9:4],   6'b0};  // step = 64, range 0-4032
    wire [DATA_WIDTH-1:0] temp_in = {sw[3:0],   3'b0};  // step = 8,  range 0-120

    wire [2:0] industry_sel = {1'b0, btn[2:1]};

    //-------------------------------------------------------
    // Analytics core 
    //-------------------------------------------------------
    wire fault_vib, fault_curr, fault_temp;
    wire trend_rising, trend_stable, trend_falling;
    wire [3:0] confidence_score;
    wire [1:0] sensor_agreement_count;
    wire confirmed_fault;

    wire [TS_WIDTH-1:0] analytics_timestamp;
    wire [3:0] analytics_confidence;
    wire [6:0] analytics_health;
    wire [1:0] analytics_agreement;
    wire [1:0] analytics_trend_status;
    wire analytics_confirmed_fault;
    wire [2:0] analytics_industry_sel;
    wire analytics_valid;
    localparam ANALYTICS_BUS_WIDTH = TS_WIDTH + 4 + 7 + 2 + 2 + 1 + 3;
    wire [ANALYTICS_BUS_WIDTH-1:0] analytics_bus;

    wire [DATA_WIDTH-1:0] profile_vib_thresh_high;
    wire [DATA_WIDTH-1:0] profile_curr_thresh_high;
    wire [DATA_WIDTH-1:0] profile_temp_thresh_high;
    wire [DATA_WIDTH-1:0] profile_temp_thresh_low;
    wire [2:0] profile_window_sel;

    edge_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .TS_WIDTH   (TS_WIDTH),
        .ANALYTICS_BUS_WIDTH (ANALYTICS_BUS_WIDTH)
    ) CORE (
        .clk                       (clk),
        .rst_n                     (rst_n),
        .vib                       (vib_in),
        .temp                      (temp_in),
        .curr                      (curr_in),
        .sample_en                 (sample_en),
        .industry_sel              (industry_sel),
        .fault_vib                 (fault_vib),
        .fault_curr                (fault_curr),
        .fault_temp                (fault_temp),
        .trend_rising              (trend_rising),
        .trend_stable              (trend_stable),
        .trend_falling             (trend_falling),
        .confidence_score          (confidence_score),
        .sensor_agreement_count    (sensor_agreement_count),
        .confirmed_fault           (confirmed_fault),
        .analytics_timestamp       (analytics_timestamp),
        .analytics_confidence      (analytics_confidence),
        .analytics_health          (analytics_health),
        .analytics_agreement       (analytics_agreement),
        .analytics_trend_status    (analytics_trend_status),
        .analytics_confirmed_fault (analytics_confirmed_fault),
        .analytics_industry_sel    (analytics_industry_sel),
        .analytics_valid           (analytics_valid),
        .analytics_bus             (analytics_bus),
        .profile_vib_thresh_high   (profile_vib_thresh_high),
        .profile_curr_thresh_high  (profile_curr_thresh_high),
        .profile_temp_thresh_high  (profile_temp_thresh_high),
        .profile_temp_thresh_low   (profile_temp_thresh_low),
        .profile_window_sel        (profile_window_sel)
    );

    //-------------------------------------------------------
    // LEDs
    //-------------------------------------------------------
    assign led[0]     = fault_vib;
    assign led[1]     = fault_curr;
    assign led[2]     = fault_temp;
    assign led[3]     = confirmed_fault;
    assign led[4]     = trend_rising;
    assign led[5]     = trend_stable;
    assign led[6]     = trend_falling;
    assign led[7]     = heartbeat;
    assign led[11:8]  = confidence_score;
    assign led[13:12] = sensor_agreement_count;
    assign led[15:14] = industry_sel[1:0];

    //-------------------------------------------------------
    // RGB status LEDs
    //-------------------------------------------------------
    assign RGB0[0] = trend_falling;   // red   = falling
    assign RGB0[1] = trend_stable;    // green = stable
    assign RGB0[2] = trend_rising;    // blue  = rising

    wire partial_agreement = (sensor_agreement_count != 2'd0) && !confirmed_fault;
    assign RGB1[0] = confirmed_fault;                       // red  = confirmed fault
    assign RGB1[1] = !confirmed_fault && !partial_agreement; // green = all clear
    assign RGB1[2] = partial_agreement;                      // blue  = one sensor flagging, not yet confirmed

    //-------------------------------------------------------
    // Seven-segment: health_score (3 digits) + status digits
    //-------------------------------------------------------
    wire [6:0] health = analytics_health;
    wire       health_hundreds_flag = (health >= 7'd100);
    wire [6:0] health_rem           = health_hundreds_flag ? (health - 7'd100) : health;
    wire [3:0] health_hundreds      = health_hundreds_flag ? 4'd1 : 4'd0;
    wire [3:0] health_tens          = health_rem / 7'd10;
    wire [3:0] health_ones          = health_rem % 7'd10;

    // D0 bank (rightmost 4 digits)
    wire [3:0] digit0 = confirmed_fault ? 4'hF : 4'h0;
    wire [3:0] digit1 = {2'b00, industry_sel[1:0]};
    wire [3:0] digit2 = {2'b00, sensor_agreement_count};
    wire [3:0] digit3 = confidence_score;

    // D1 bank (leftmost 4 digits) - health score, hundreds/tens/ones
    wire [3:0] digit4 = 4'h0;
    wire [3:0] digit5 = health_ones;
    wire [3:0] digit6 = health_tens;
    wire [3:0] digit7 = health_hundreds;

    seven_seg_driver #(
        .CLK_FREQ (CLK_FREQ_HZ)
    ) DISP (
        .clk     (clk),
        .rst_n   (rst_n),
        .digit7  (digit7),
        .digit6  (digit6),
        .digit5  (digit5),
        .digit4  (digit4),
        .digit3  (digit3),
        .digit2  (digit2),
        .digit1  (digit1),
        .digit0  (digit0),
        .d0_an   (D0_AN),
        .d0_seg  (D0_SEG),
        .d1_an   (D1_AN),
        .d1_seg  (D1_SEG)
    );

endmodule
