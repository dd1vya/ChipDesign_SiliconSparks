`timescale 1ns / 1ps
module sensor_interface #(
    parameter DATA_WIDTH = 12,
    parameter TS_WIDTH   = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,
    // Raw sensor inputs (already digitized by external ADC)
    input  wire [DATA_WIDTH-1:0]  vib_data_in,
    input  wire [DATA_WIDTH-1:0]  temp_data_in,
    input  wire [DATA_WIDTH-1:0]  curr_data_in,
    input  wire                   sample_en,    // sampling strobe
    output reg  [DATA_WIDTH-1:0]  vib_data_out,
    output reg  [DATA_WIDTH-1:0]  temp_data_out,
    output reg  [DATA_WIDTH-1:0]  curr_data_out,
    output reg  [TS_WIDTH-1:0]    timestamp_out,
    output reg                    data_valid
);
    // Free-running timestamp counter -> traceability / audit logging
    reg [TS_WIDTH-1:0] free_run_ts;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            free_run_ts <= {TS_WIDTH{1'b0}};
        else
            free_run_ts <= free_run_ts + 1'b1;
    end
    // Simple registered stage models "signal conditioning" ahead of acquisition
    reg [DATA_WIDTH-1:0] cond_vib, cond_temp, cond_curr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cond_vib  <= {DATA_WIDTH{1'b0}};
            cond_temp <= {DATA_WIDTH{1'b0}};
            cond_curr <= {DATA_WIDTH{1'b0}};
        end else begin
            cond_vib  <= vib_data_in;
            cond_temp <= temp_data_in;
            cond_curr <= curr_data_in;
        end
    end
    // Simultaneous timestamped acquisition of all three channels
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vib_data_out  <= {DATA_WIDTH{1'b0}};
            temp_data_out <= {DATA_WIDTH{1'b0}};
            curr_data_out <= {DATA_WIDTH{1'b0}};
            timestamp_out <= {TS_WIDTH{1'b0}};
            data_valid    <= 1'b0;
        end else if (sample_en) begin
            vib_data_out  <= cond_vib;
            temp_data_out <= cond_temp;
            curr_data_out <= cond_curr;
            timestamp_out <= free_run_ts;
            data_valid    <= 1'b1;
        end else begin
            data_valid <= 1'b0;
        end
    end
endmodule
