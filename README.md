# ChipDesign_SiliconSparks
# Edge Analytics IP Core for Industrial IoT

## Overview

Edge Analytics IP is a configurable FPGA-based hardware accelerator that performs lightweight industrial sensor analytics directly at the edge. Instead of transmitting raw sensor data to the cloud, the IP processes vibration, current, and temperature measurements on-chip to generate real-time machine health information with deterministic latency.

The design is intended as a reusable RTL IP core for FPGA and future ASIC integration.

## Features
Multi-sensor industrial monitoring  
Moving average noise filtering  
Threshold-based anomaly detection  
Trend analysis for vibration, current, and temperature  
Confidence-based sensor fusion  
Configurable confidence weighting per industry profile  
Multiple industry operating profiles  
Machine health score generation  
FPGA implementation on Spartan-7  
Human-readable visualization using LEDs and seven-segment displays  

## Supported Industry Profiles
Textile Manufacturing  
Cold Storage  
Job Shop  
General Industrial Equipment  

Each profile uses different threshold values and confidence weights to better represent varying operating conditions.

## System Architecture
```
Sensors
(Vibration | Current | Temperature)
            │
            ▼
Sensor Interface
            │
            ▼
Moving Average Filters
            │
            ▼
Threshold Detection
            │
            ▼
Trend Detection
            │
            ▼
Confidence Engine
            │
            ▼
Analytics Output
            │
            ▼
LEDs / Seven-Segment Display

```
## Project Structure
```
rtl/
    edge_top.v
    sensor_interface.v
    moving_avg_filter.v
    threshold_detector.v
    trend_detector.v
    industry_profile.v
    confidence_engine.v
    analytics_output.v
    boolean_top.v
    seven_seg_driver.v

tb/
    edge_top_tb.v

constraints/
    boolean.xdc
```

## Hardware Platform
FPGA: AMD/Xilinx Spartan-7 XC7S50  
Development Board: Boolean Board  
Toolchain: Vivado  
Language: Verilog HDL  

## Demonstrated Features
Live sensor monitoring  
Configurable industry profiles  
Dynamic confidence calculation  
Multi-sensor fault confirmation  
Trend visualization  
Health score generation  
Real-time FPGA execution  

## Validation
RTL simulation  
Behavioral waveform verification  
FPGA synthesis and implementation  
Hardware testing on Spartan-7  
Functional verification across all industry profiles  

## Tested scenarios include:
Healthy operation  
Individual sensor faults  
Multi-sensor fault correlation  
Trend detection  
Configurable industry behavior  
Confidence-based fault confirmation  

## Future Improvements
UART/Serial analytics output  
Adaptive threshold calibration  
Additional sensor interfaces (SPI/I²C/ADC)  
AXI4-Lite configuration interface  
ASIC implementation  
TinyML integration for predictive maintenance  
