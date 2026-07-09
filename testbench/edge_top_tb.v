`timescale 1ns / 1ps
module edge_top_tb;

    reg         clk;
    reg         rst_n;
    reg  [11:0] vib;
    reg  [11:0] temp;
    reg  [11:0] curr;
    reg         sample_en;
    reg  [2:0]  industry_sel;

    wire        fault_vib, fault_curr, fault_temp;
    wire        trend_rising, trend_stable, trend_falling;
    wire [3:0]  confidence_score;
    wire [1:0]  sensor_agreement_count;
    wire        confirmed_fault;

    wire [31:0] analytics_timestamp;
    wire [3:0]  analytics_confidence;
    wire [6:0]  analytics_health;
    wire [1:0]  analytics_agreement;
    wire [1:0]  analytics_trend_status;
    wire        analytics_confirmed_fault;
    wire [2:0]  analytics_industry_sel;
    wire        analytics_valid;
    wire [50:0] analytics_bus;

    wire [11:0] profile_vib_thresh_high;
    wire [11:0] profile_curr_thresh_high;
    wire [11:0] profile_temp_thresh_high;
    wire [11:0] profile_temp_thresh_low;
    wire [2:0]  profile_window_sel;

    edge_top uut (
        .clk                       (clk),
        .rst_n                     (rst_n),
        .vib                       (vib),
        .temp                      (temp),
        .curr                      (curr),
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

    always #5 clk = ~clk;

    integer i;

    initial begin
        clk          = 0;
        rst_n        = 0;
        vib          = 0;
        temp         = 0;
        curr         = 0;
        sample_en    = 0;
        industry_sel = 3'b000;   // Textile loom profile (window = 2)

        #20;
        rst_n     = 1;
        sample_en = 1;
        #10; // let the profile register load

        // Textile profile: window_sel=1 -> window=2. Minimum clean-read time is window(2) + pipeline(5) = ~7 cycles;

        $display("---- Phase 1: NORMAL (Textile profile) ----");
        for (i = 0; i < 10; i = i + 1) begin
            vib = 12'd20; curr = 12'd25; temp = 12'd30; #10;
        end

        $display("---- Phase 2: FALSE ALARM AVOIDED - vib spikes ALONE ----");
        for (i = 0; i < 10; i = i + 1) begin
            vib = 12'd400; curr = 12'd30; temp = 12'd30; #10;
        end

        $display("---- Phase 3: RECOVERY ----");
        for (i = 0; i < 10; i = i + 1) begin
            vib = 12'd20; curr = 12'd25; temp = 12'd30; #10;
        end

        $display("---- Phase 4: CONFIRMED FAULT - vib AND curr spike TOGETHER ----");
        for (i = 0; i < 10; i = i + 1) begin
            vib = 12'd400; curr = 12'd400; temp = 12'd30; #10;
        end

        $display("---- Phase 5: RECOVERY (confirmed_fault should drop back to 0) ----");
        for (i = 0; i < 10; i = i + 1) begin
            vib = 12'd20; curr = 12'd25; temp = 12'd30; #10;
        end

        $display("---- Phase 6: PROFILE SWITCH -> Cold Storage (live) ----");
        industry_sel = 3'b001;
        // window widens to 8: minimum clean-read time is window(8) + pipeline(5) = ~13 cycles.

        $display("---- Phase 6a: temperature alone dips below the cold-storage floor ----");
        for (i = 0; i < 16; i = i + 1) begin
            vib = 12'd50; curr = 12'd60; temp = 12'd10; #10;   // temp < floor(20) -> fault_temp only
        end

        $display("---- Phase 6b: current also rises - still not enough to confirm ----");
        for (i = 0; i < 16; i = i + 1) begin
            vib = 12'd50; curr = 12'd220; temp = 12'd10; #10;  // fault_temp(+1) + fault_curr(+2) = 3
        end

        $display("---- Phase 6c: vibration also trending up - trend tips it to CONFIRMED ----");
        for (i = 0; i < 16; i = i + 1) begin
            vib = 12'd60 + i * 12'd15; curr = 12'd220; temp = 12'd10; #10;
        end

        sample_en = 0;
        #50;
        $display("=== Simulation complete ===");
        $finish;
    end

    always @(posedge clk) begin
        $display("t=%0t | vib=%0d curr=%0d temp=%0d | sel=%0d win=%0d vT=%0d cT=%0d tTh=%0d tTl=%0d | fV=%b fC=%b fT=%b trend(r=%b s=%b f=%b) | score=%0d agree=%0d CONFIRMED=%b | analytics(ts=%0d conf=%0d health=%0d agree=%0d trend=%b fault=%b sel=%0d valid=%b)",
                   $time, vib, curr, temp, industry_sel, profile_window_sel,
                   profile_vib_thresh_high, profile_curr_thresh_high,
                   profile_temp_thresh_high, profile_temp_thresh_low,
                   fault_vib, fault_curr, fault_temp,
                   trend_rising, trend_stable, trend_falling,
                   confidence_score, sensor_agreement_count, confirmed_fault,
                   analytics_timestamp, analytics_confidence, analytics_health,
                   analytics_agreement, analytics_trend_status,
                   analytics_confirmed_fault, analytics_industry_sel, analytics_valid);
    end

endmodule
