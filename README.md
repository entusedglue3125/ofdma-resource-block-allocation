# 5G OFDMA Dynamic Resource Block Allocation & Scheduling Simulation

[![MATLAB](https://img.shields.io/badge/MATLAB-R2022a%2B-ED8B00?logo=mathworks&logoColor=white)](https://www.mathworks.com/products/matlab.html)
[![5G NR](https://img.shields.io/badge/Telecommunications-5G%20OFDMA-007ACC)](https://www.3gpp.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> A standalone MATLAB simulation analyzing radio resource allocation strategies (Round Robin, Max-Rate, and Proportional Fair) across multi-user Orthogonal Frequency Division Multiple Access (OFDMA) wireless communication channels.

---

## 📡 Theoretical Overview

In modern 5G NR and LTE downlink transmission, the radio spectrum is subdivided into orthogonal subcarriers grouped into **Resource Blocks (RBs)** ($B_{\text{RB}} = 180\text{ kHz}$). The base station (gNodeB) scheduler must allocate RBs among multiple User Equipments (UEs) every Transmission Time Interval (TTI = 1 ms) balancing overall spectral throughput against inter-user fairness.

### Mathematical Formulation

1. **Shannon Channel Capacity per RB**:
   $$\gamma(u,r,t) = 10^{\frac{\text{SNR}_{\text{dB}}(u,r,t)}{10}}$$
   $$R(u,r,t) = B_{\text{RB}} \cdot \log_2\left(1 + \gamma(u,r,t)\right)$$

2. **Scheduling Algorithms Compared**:
   - **Round Robin (RR)**: Allocates RBs cyclically to requesting users regardless of instantaneous channel conditions. Guaranteed access but poor aggregate spectral efficiency.
   - **Max-Rate / Best-CQI**:
     $$u^*(r,t) = \arg\max_{u \in \mathcal{U}} R(u,r,t)$$
     Maximizes total cell throughput by exploiting multi-user channel diversity, but starves cell-edge users with low SNR.
   - **Proportional Fair (PF)**:
     $$u^*(r,t) = \arg\max_{u \in \mathcal{U}} \frac{R(u,r,t)}{\bar{T}(u,t-1)}$$
     Where past throughput $\bar{T}(u,t)$ is updated with exponential smoothing ($\alpha = 0.10$):
     $$\bar{T}(u,t) = (1 - \alpha)\bar{T}(u,t-1) + \alpha T(u,t)$$
     Strikes an optimal compromise between high spectral efficiency and fair opportunity.

3. **Jain's Fairness Index**:
   $$\mathcal{J} = \frac{\left(\sum_{u=1}^{N} \bar{x}_u\right)^2}{N \sum_{u=1}^{N} \bar{x}_u^2}, \quad \mathcal{J} \in \left[\frac{1}{N}, 1\right]$$

---

## 📊 Simulation Parameters

| Parameter | Value | Description |
|:---|:---|:---|
| **Number of Users ($N_{\text{UE}}$)** | 8 | Active mobile stations across cell radius |
| **Available Resource Blocks ($N_{\text{RB}}$)** | 48 | 10 MHz channel bandwidth equivalent |
| **Simulation Duration** | 100 TTIs | 100 ms total scheduling window |
| **RB Bandwidth ($B_{\text{RB}}$)** | 180 kHz | Standard 3GPP LTE / 5G NR numerology $\mu=0$ |
| **User Traffic Demand** | 0 to 8 RBs / TTI | Uniform random demand requests |
| **Dependencies** | Base MATLAB | No proprietary toolboxes required |

---

## 📁 Repository Structure

```text
ofdma-resource-block-allocation/
├── OFDMA_RB_Allocation_Simulation.m  # Main executable simulation script
├── README_OFDMA_RB_Allocation.txt    # Technical verification notes
├── .gitignore
└── README.md
```

---

## ⚡ How to Run

1. Open MATLAB.
2. In the Current Folder panel, navigate to this repository folder.
3. In the MATLAB Command Window, execute:
   ```matlab
   OFDMA_RB_Allocation_Simulation
   ```
4. **Outputs Generated**:
   - Comparison summary table printed to console (Throughput, RB Utilization %, Jain's Index).
   - High-resolution comparative plots:
     1. Time-frequency RB allocation heatmaps across TTIs.
     2. Individual user average throughput bar graphs.
     3. Aggregate throughput and fairness metric bar charts.
     4. Cumulative throughput progression curves over time.
   - Raw numeric result `.csv` files for post-processing.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
