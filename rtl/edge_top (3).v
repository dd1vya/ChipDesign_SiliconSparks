`timescale 1ns / 1ps
//============================================================
// edge_top.v
//
// Chip-level edge analytics IP core:
//
//   edge_top
//   |
//   +-- sensor_interface   : parallel vib/temp/curr acquisition + timestamp
//   +-- industry_profile   : per-vertical thresholds + window, from industry_sel
//   +-- moving_avg_filter  : one instance per channel (vib / curr / temp)
//   +-- threshold_detector : one instance per channel, band check vs profile
//   +-- trend_detector     : rising/stable/falling on the vibration average
//   +-- confidence_engine  : weighted score -> confirmed_fault
//   +-- analytics_output   : packages everything for a dashboard / IoT link
//
// Design intent: three sensor channels are filtered and threshold-checked
// in parallel (same architecture as a single channel, just instantiated
// three times), then FUSED through a scoring engine instead of a rigid
// AND, so a single noisy channel does not falsely shut a machine down
// while two-or-more-channel or trending faults still get confirmed
// quickly. industry_profile lets the same RTL be redeployed across
// verticals (textile / cold storage / job-shop / general) purely by
// changing industry_sel - no re-synthesis needed.
//============================================================
module edge_top #(
    parameter DATA_WIDTH = 12,
    parameter TS_WIDTH   = 32,
    parameter ANALYTICS_BUS_WIDTH = TS_WIDTH + 4 + 7 + 2 + 2 + 1 + 3
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // Raw sensor channels
    input  wire [DATA_WIDTH-1:0]  vib,
    input  wire [DATA_WIDTH-1:0]  temp,
    input  wire [DATA_WIDTH-1:0]  curr,
    input  wire                   sample_en,
    input  wire [2:0]             industry_sel,   // 000=Textile 001=ColdStorage 010=JobShop 011=General

    // Per-channel fault flags
    output wire                   fault_vib,
    output wire                   fault_curr,
    output wire                   fault_temp,

    // Trend (predictive, ahead of thresholds)
    output wire                   trend_rising,
    output wire                   trend_stable,
    output wire                   trend_falling,

    // Confidence-based decision engine
    output wire [3:0]             confidence_score,
    output wire [1:0]             sensor_agreement_count,
    output wire                   confirmed_fault,

    // Packaged analytics output (dashboard / IoT platform facing)
    output wire [TS_WIDTH-1:0]    analytics_timestamp,
    output wire [3:0]             analytics_confidence,
    output wire [6:0]             analytics_health,
    output wire [1:0]             analytics_agreement,
    output wire [1:0]             analytics_trend_status,
    output wire                   analytics_confirmed_fault,
    output wire [2:0]             analytics_industry_sel,
    output wire                   analytics_valid,
    output wire [ANALYTICS_BUS_WIDTH-1:0] analytics_bus,

    // Profile values broken out so they're visible on the waveform
    output wire [DATA_WIDTH-1:0]  profile_vib_thresh_high,
    output wire [DATA_WIDTH-1:0]  profile_curr_thresh_high,
    output wire [DATA_WIDTH-1:0]  profile_temp_thresh_high,
    output wire [DATA_WIDTH-1:0]  profile_temp_thresh_low,
    output wire [2:0]             profile_window_sel
);

    //-------------------------------------------------------
    // Sensor acquisition - all three channels, same instant
    //-------------------------------------------------------
    wire [DATA_WIDTH-1:0] vib_s, temp_s, curr_s;
    wire [TS_WIDTH-1:0]   timestamp;
    wire                  data_valid;

    sensor_interface #(
        .DATA_WIDTH (DATA_WIDTH),
        .TS_WIDTH   (TS_WIDTH)
    ) SI (
        .clk           (clk),
        .rst_n         (rst_n),
        .vib_data_in   (vib),
        .temp_data_in  (temp),
        .curr_data_in  (curr),
        .sample_en     (sample_en),
        .vib_data_out  (vib_s),
        .temp_data_out (temp_s),
        .curr_data_out (curr_s),
        .timestamp_out (timestamp),
        .data_valid    (data_valid)
    );

    //-------------------------------------------------------
    // Industry profile - shared thresholds/window for every channel
    //-------------------------------------------------------
    wire [DATA_WIDTH-1:0] vib_th_high,  vib_th_low;
    wire [DATA_WIDTH-1:0] curr_th_high, curr_th_low;
    wire [DATA_WIDTH-1:0] temp_th_high, temp_th_low;
    wire [2:0]            window_sel;

    // Per-industry confidence-engine scoring parameters
    wire [2:0]             vib_weight, curr_weight, temp_weight, trend_weight;
    wire [3:0]             confirm_thresh;

    industry_profile #(
        .DATA_WIDTH (DATA_WIDTH)
    ) IP (
        .clk              (clk),
        .rst_n            (rst_n),
        .industry_sel     (industry_sel),
        .vib_thresh_high  (vib_th_high),
        .vib_thresh_low   (vib_th_low),
        .curr_thresh_high (curr_th_high),
        .curr_thresh_low  (curr_th_low),
        .temp_thresh_high (temp_th_high),
        .temp_thresh_low  (temp_th_low),
        .window_sel       (window_sel),
        .vib_weight       (vib_weight),
        .curr_weight      (curr_weight),
        .temp_weight      (temp_weight),
        .trend_weight     (trend_weight),
        .confirm_thresh   (confirm_thresh)
    );

    assign profile_vib_thresh_high  = vib_th_high;
    assign profile_curr_thresh_high = curr_th_high;
    assign profile_temp_thresh_high = temp_th_high;
    assign profile_temp_thresh_low  = temp_th_low;
    assign profile_window_sel       = window_sel;

    //-------------------------------------------------------
    // Per-channel moving average - one instance per sensor,
    // all sharing the profile-selected window
    //-------------------------------------------------------
    wire [DATA_WIDTH-1:0] filt_vib, filt_curr, filt_temp;
    wire                  filt_vib_valid, filt_curr_valid, filt_temp_valid;

    moving_avg_filter #(.DATA_WIDTH(DATA_WIDTH)) MAF_VIB (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (vib_s),
        .data_in_valid  (data_valid),
        .window_sel     (window_sel),
        .data_out       (filt_vib),
        .data_out_valid (filt_vib_valid)
    );

    moving_avg_filter #(.DATA_WIDTH(DATA_WIDTH)) MAF_CURR (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (curr_s),
        .data_in_valid  (data_valid),
        .window_sel     (window_sel),
        .data_out       (filt_curr),
        .data_out_valid (filt_curr_valid)
    );

    moving_avg_filter #(.DATA_WIDTH(DATA_WIDTH)) MAF_TEMP (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (temp_s),
        .data_in_valid  (data_valid),
        .window_sel     (window_sel),
        .data_out       (filt_temp),
        .data_out_valid (filt_temp_valid)
    );

    //-------------------------------------------------------
    // Per-channel threshold check against the profile's band
    //-------------------------------------------------------
    threshold_detector #(.DATA_WIDTH(DATA_WIDTH)) TD_VIB (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (filt_vib),
        .data_valid     (filt_vib_valid),
        .threshold_high (vib_th_high),
        .threshold_low  (vib_th_low),
        .fault          (fault_vib),
        .normal         ()
    );

    threshold_detector #(.DATA_WIDTH(DATA_WIDTH)) TD_CURR (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (filt_curr),
        .data_valid     (filt_curr_valid),
        .threshold_high (curr_th_high),
        .threshold_low  (curr_th_low),
        .fault          (fault_curr),
        .normal         ()
    );

    threshold_detector #(.DATA_WIDTH(DATA_WIDTH)) TD_TEMP (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (filt_temp),
        .data_valid     (filt_temp_valid),
        .threshold_high (temp_th_high),
        .threshold_low  (temp_th_low),
        .fault          (fault_temp),
        .normal         ()
    );

    //-------------------------------------------------------
    // Trend detector - predictive signal, tracked on the
    // vibration channel (typically the earliest indicator of
    // developing mechanical stress)
    //-------------------------------------------------------
    trend_detector #(.DATA_WIDTH(DATA_WIDTH)) TR (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (filt_vib),
        .data_valid (filt_vib_valid),
        .rising     (trend_rising),
        .stable     (trend_stable),
        .falling    (trend_falling)
    );

    // Current and temperature get their own trend detectors too, so a
    // developing fault on either channel can also earn the scoring
    // engine's "rising trend" point - not just vibration. These don't
    // drive the top-level trend_rising/stable/falling display outputs
    // (those stay tied to vibration, the earliest mechanical indicator),
    // they only widen what feeds the confidence score below.
    wire rising_curr, rising_temp;

    trend_detector #(.DATA_WIDTH(DATA_WIDTH)) TR_CURR (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (filt_curr),
        .data_valid (filt_curr_valid),
        .rising     (rising_curr),
        .stable     (),
        .falling    ()
    );

    trend_detector #(.DATA_WIDTH(DATA_WIDTH)) TR_TEMP (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (filt_temp),
        .data_valid (filt_temp_valid),
        .rising     (rising_temp),
        .stable     (),
        .falling    ()
    );

    wire trend_rising_any = trend_rising | rising_curr | rising_temp;

    //-------------------------------------------------------
    // Confidence-based fusion - replaces a rigid AND with a
    // weighted score across all three channels plus trend.
    // Weights and confirm_thresh now come from industry_profile
    // instead of a fixed parameter, so e.g. Cold Storage can
    // weight temperature as heavily as vibration.
    //-------------------------------------------------------
    confidence_engine CE (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .fault_vib              (fault_vib),
        .fault_curr             (fault_curr),
        .fault_temp             (fault_temp),
        .trend_rising           (trend_rising_any),
        .vib_weight             (vib_weight),
        .curr_weight            (curr_weight),
        .temp_weight            (temp_weight),
        .trend_weight           (trend_weight),
        .confirm_thresh         (confirm_thresh),
        .confidence_score       (confidence_score),
        .sensor_agreement_count (sensor_agreement_count),
        .confirmed_fault        (confirmed_fault)
    );

    //-------------------------------------------------------
    // Analytics output package - one clean interface for a
    // dashboard, controller or IoT gateway
    //-------------------------------------------------------
    analytics_output #(
        .TS_WIDTH  (TS_WIDTH),
        .BUS_WIDTH (ANALYTICS_BUS_WIDTH)
    ) AO (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .timestamp_in           (timestamp),
        .confidence_score       (confidence_score),
        .sensor_agreement_count (sensor_agreement_count),
        .confirmed_fault        (confirmed_fault),
        .trend_rising           (trend_rising),
        .trend_stable           (trend_stable),
        .trend_falling          (trend_falling),
        .industry_sel           (industry_sel),
        .data_valid             (filt_vib_valid),
        .timestamp_out          (analytics_timestamp),
        .confidence_score_out   (analytics_confidence),
        .health_score           (analytics_health),
        .sensor_agreement_out   (analytics_agreement),
        .trend_status           (analytics_trend_status),
        .confirmed_fault_out    (analytics_confirmed_fault),
        .industry_sel_out       (analytics_industry_sel),
        .analytics_valid        (analytics_valid),
        .analytics_bus          (analytics_bus)
    );

endmodule
