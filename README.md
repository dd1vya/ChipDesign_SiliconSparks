# ChipDesign_SiliconSparks
# EdgeSense-IP: Configurable Edge Analytics IP Core for Industrial IoT

## Overview

**EdgeSense-IP** is a lightweight, synthesizable Verilog IP core for **real-time edge analytics** in Industrial IoT systems. Instead of transmitting raw sensor data to the cloud, the IP performs filtering, multi-sensor analysis, and fault detection directly on-chip, enabling low-latency decision making with minimal computational overhead.

Designed for resource-constrained embedded systems, the architecture focuses on reducing false alarms through **sensor correlation** while supporting **industry-specific operating profiles** that allow the same hardware to adapt to different industrial environments.

This project was developed as a proof-of-concept for edge analytics in semiconductor and industrial IoT applications.

---

# Key Features

### Multi-Sensor Data Acquisition

* Interfaces with multiple sensor channels
* Timestamp-ready sensor pipeline
* Low-overhead acquisition architecture
* Designed for vibration, temperature, current, and similar industrial sensors

---

### Hardware Moving Average Filter

* Resource-efficient moving average implementation
* Configurable window size
* Suppresses transient sensor noise
* Suitable for FPGA and ASIC implementation

---

### Sensor Correlation Engine

Instead of triggering alarms from a single sensor threshold, EdgeSense-IP performs **multi-sensor fault correlation**.

Example:

* High vibration only → ignored as temporary disturbance
* High current only → monitored
* High vibration + high current simultaneously → confirmed fault

This significantly reduces false positives compared to traditional threshold-only systems.

---

### Industry Profile Engine

A lightweight profile lookup module allows the same hardware to operate across different industrial environments.

Selectable profiles automatically configure:

* Detection thresholds
* Filter window size
* Processing parameters

Example supported profiles:

* Textile Machinery
* Food Processing
* Cold Storage
* General Manufacturing

No HDL modification is required—only the profile selection input changes.

---

### Real-Time Analytics Output

The IP generates processed outputs suitable for:

* Industrial dashboards
* PLC interfaces
* Embedded controllers
* Local HMI systems
* Edge IoT gateways

---

# Architecture

```
          Sensors
(Vibration • Temperature • Current)

                │
                ▼

        Sensor Interface

                │
                ▼

      Moving Average Filter

                │
                ▼

     Industry Profile Engine
     (Threshold Configuration)

                │
                ▼

      Threshold Detection

                │
                ▼

     Multi-Sensor Correlator

                │
                ▼

      Analytics / Fault Output
```

---

# Why This Project?

Many low-cost industrial monitoring systems rely on **single-sensor threshold detection**, which often produces unnecessary alarms due to temporary disturbances.

EdgeSense-IP introduces two practical improvements while remaining lightweight enough for FPGA or ASIC implementation:

* **Sensor correlation**, reducing false positives by validating events across multiple sensors.
* **Configurable industry profiles**, enabling a single IP core to be reused across different industrial applications without redesign.

These additions improve flexibility and reliability while maintaining a small hardware footprint.

---

# Applications

* Predictive maintenance
* Industrial machine monitoring
* Factory automation
* Smart manufacturing
* Condition monitoring
* Edge Industrial IoT
* Embedded analytics
* Semiconductor equipment monitoring

---

# Technologies

* Verilog HDL
* Xilinx Vivado
* XSIM Simulation
* FPGA-oriented RTL Design

---

# Future Enhancements

* AI-assisted anomaly detection
* Adaptive threshold learning
* Sensor confidence weighting
* Cloud synchronization (Hybrid Edge-Cloud)
* SPI/I²C sensor interfaces
* AXI4-Lite integration
* Power optimization
* Edge TinyML accelerator support


