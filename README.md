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

```
#1 TEXTILE(BTN1-1,BTN2-0)
all switches low
d1sp1[0000]
d1sp2[1000]
rgb0[green]
rgb1[green] 
LD7 BLINKS LD5 GLOWS ALL TIME

sw15-sw10(all follow same pattern)
low to high- 
d1sp1[3100->2100]
d1sp2[0550->0700]
rgb0[green->blue->green]
rgb1[green->blue] 
LD12 LD9 LD0 GLOWS LD4 AND LD8 GLOW AT MID SECOND

high to low- 
d1sp1[2100->0000]
d1sp2[700->1000]
rgb0[green->red->green]
rgb1[blue->green] LD6 GLOWS AT MID

sw9-sw6(all follow same pattern)
low to high
d1sp1[0000->2100]
d1sp2[1000->0700]
rgb0[green->green]
rgb1[green->blue] 
LD12 LD9 LD1 GLOWS

high to low
d1sp1[2100->0000]
d1sp2[700->1000]
rgb0[green->green]
rgb1[blue->green] 
NO GLOW AT MID

A SWITCH FROM (SW15-S10) AND (SW9-SW6) TOGETHER
BOTH HIGH
d1sp1[520F->420F]
d1sp2[0700->0400]
rgb0[green->green]
rgb1[BLUE->RED] 
LD13 LD10 LD3 LD1 LD0 GLOWS

sw3-sw0-NO EFFECT.


#2 COLD STORAGE(BTN1-1,BTN2-0)
TEXTILE
all switches low
d1sp1[1110]
d1sp2[0850]
rgb0[green]
rgb1[blue] 
LD7 BLINKS LD2,LD5,LD8,LD12,LD14 GLOWS ALL TIME

sw15-sw10(all follow same pattern)
low to high- 
d1sp1[1100->2100->421F->3210]
d1sp2[0850->0700->0400->0550]
rgb0[green->blue]
rgb1[BLUE->red] 
LD13 LD13 LD8 LD9 LD2 LD0 GLOWS LD4 LD3 GLOW AT MID SECOND
IT ACTUALLY GOES LIKE LD8->LD9->LD10 AND BACK TO LD8 LD9 AT LAST

high to low- 
d1sp1[3210->1110]
d1sp2[0550->0850]
rgb0[BLUE->green]
rgb1[blue->BLUE] 
LD13,LD0 GLOW TILL MID

sw9-sw4(all follow same pattern)
low to high
d1sp1[1110->3210]
d1sp2[0850->0550]
rgb0[green->green]
rgb1[green->blue] 
LD1,LD2,LD8,LD9,LD13,LD14 GLOWS during HIGH
SW4 AND SW5 NO EFFECT

high to low
d1sp1[3210->1110]
d1sp2[0550->0850]
rgb0[green->green]
rgb1[blue->blue] 
NO GLOW AT MID

A SWITCH FROM (SW15-S10) AND (SW9-SW6) TOGETHER
BOTH HIGH
d1sp1[531F]
d1sp2[0200]
rgb0[green->BLUE->green]
rgb1[BLUE->RED] 
LD12 LD13 LD14 LD10 LD8 LD3 LD1 LD0 GLOWS

sw3-sw0-
SW3 ONLY
low to high
d1sp1[1110->0010]
d1sp2[0850->1000]
rgb0[green->green]
rgb1[green->GREEN] 
LD5,LD14 GLOWS during HIGH

#3 JOB SHOP(BTN1-0,BTN2-1)
all switches low
d1sp1[0020]
d1sp2[1000]
rgb0[green]
rgb1[green] 
LD7 BLINKS LD5,LD15 GLOWS ALL TIME

sw15-sw10(all follow same pattern)
low to high- 
d1sp1[3120->2120]
d1sp2[0550->0700]
rgb0[green->blue->green]
rgb1[green->blue] 
LD4,LD8 GLOWS IN MID
LD15,LD12,LD9,LD0 GLOWS DURING HIGH

high to low- 
d1sp1[2120->0020]
d1sp2[700->1000]
rgb0[green->red->green]
rgb1[blue->green] 
LD6 GLOWS AT MID

sw9-sw6(all follow same pattern)
low to high
d1sp1[2120]
d1sp2[0700]
rgb0[green->green]
rgb1[green->blue] 
LD1,LD9,LD12,LD15 GLOWS

high to low
d1sp1[2120->0020]
d1sp2[700->1000]
rgb0[green->green]
rgb1[blue->green] 
NO GLOW AT MID

A SWITCH FROM (SW15-S10) AND (SW9-SW6) TOGETHER
BOTH HIGH
d1sp1[522F->422F]
d1sp2[0200->0400]
rgb0[green->BLUE->green]
rgb1[BLUE->RED] 
LD8 GLOWS MID


sw5-sw0-NO EFFECT.


#4 GENERAL(BTN1-1,BTN2-1)
all switches low
d1sp1[0030]
d1sp2[1000]
rgb0[green]
rgb1[green] 
LD7 BLINKS LD5 LD14,LD15 GLOWS ALL TIME

sw15-sw10(all follow same pattern)
low to high- 
d1sp1[3120->2130]
d1sp2[0550->0700]
rgb0[green->blue->green]
rgb1[green->blue] 
LD4 - LD5
LD8 glows mid
LD15 LD14 LD12 LD9 LD5 LD0 GLOWS DURING HIGH

high to low- 
d1sp1[2130>30]
d1sp2[700->1000]
rgb0[green->red->green]
rgb1[blue->green] LD6 GLOWS AT MID

sw9-sw6(all follow same pattern)
low to high
d1sp1[30->210]
d1sp2[1000->700]
rgb0[green->green]
rgb1[green->blue] 
LD15 LD14 LD12 LD9 LD1 GLOWS DURING HIGH

high to low
d1sp1[2130->30]
d1sp2[700->1000]
rgb0[green->green]
rgb1[blue->green] 
NO GLOW AT MID

A SWITCH FROM (SW15-S10) AND (SW9-SW6) TOGETHER
BOTH HIGH
d1sp1[523->423F]
d1sp2[200->400]
rgb0[green->BLUE->GREEN]
rgb1[BLUE->RED] 
LD15 LD14 LD13 LD10 LD5 LD3 LD1 LD0 GLOWS

sw4-swO EFFECT.
```
