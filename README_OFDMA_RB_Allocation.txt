OFDMA RESOURCE-BLOCK ALLOCATION — MATLAB STARTER PROJECT
=========================================================

FILES
-----
OFDMA_RB_Allocation_Simulation.m
    Main runnable simulation script.

DEPENDENCIES
------------
Base MATLAB only. The script deliberately does not call Communications Toolbox,
5G Toolbox, Wireless Network Toolbox, or Simulink functions.

Check installed products in MATLAB with:
    ver

Run the script by changing the Current Folder to where the .m file is saved, then:
    OFDMA_RB_Allocation_Simulation

MODEL DESCRIPTION
-----------------
The simulation represents 8 user equipment (UEs), 48 resource blocks (RBs), and
100 scheduling intervals (TTIs). Each UE has a different average SNR and a
randomly varying SNR across RBs and TTIs. Each TTI, every UE requests between
0 and 8 RBs. The same SNR and demand realizations are used by all three schedulers.

Schedulers:
1. Round Robin (RR): cyclically serves users that still have RB requests.
2. Max-Rate: for each RB, selects the requesting UE with the highest achievable
   rate for that RB.
3. Proportional Fair (PF): selects the requesting UE maximizing instantaneous
   RB rate divided by its exponentially averaged past throughput.

EQUATIONS
---------
Convert SNR from dB to linear scale:
    gamma = 10^(SNR_dB / 10)

Idealized per-RB achievable rate:
    R(u,r,t) = B_RB * log2(1 + gamma(u,r,t))
where B_RB = 180 kHz.

Scheduler policies:
    RR: next requesting UE in cyclic order
    Max-Rate: arg max over eligible users of R(u,r,t)
    PF: arg max over eligible users of R(u,r,t) / Tbar(u)

PF moving-average update after each TTI:
    Tbar(u,t) = (1-alpha)*Tbar(u,t-1) + alpha*T(u,t)
where alpha = 0.10 and T(u,t) is the sum of allocated RB rates to UE u in TTI t.

Resource-block utilization:
    Utilization (%) = 100 * number of allocated RBs / total available RBs

Jain's fairness index (using mean throughput x(u) per UE):
    J = (sum_u x(u))^2 / (N_UE * sum_u x(u)^2)
A value closer to 1 indicates more equal throughput across UEs.

HOW TO TEST
-----------
1. Run the script in MATLAB.
2. Confirm that the command window shows the scheduler summary and per-user table.
3. Inspect the four generated PNG plots:
   - RB allocation heatmaps
   - Per-user mean throughput
   - Aggregate throughput, utilization, and fairness
   - Aggregate throughput over time
4. Open the generated CSV files for the numerical results.
5. Change one parameter (e.g., nUsers, nRB, maxRBRequest, or fadingStdDb), rerun,
   and compare results.
6. For a repeatable baseline, leave rng(7, 'twister') unchanged.

EXPECTED OUTPUTS
----------------
The script should:
- Print a 3-row summary table comparing RR, Max-Rate, and PF.
- Print mean throughput for each of the 8 UEs.
- Create four plots and three CSV files in the current folder.
- Never allocate more than 48 RBs in a TTI.
- Usually show Max-Rate favoring higher instantaneous rates and PF attempting a
  throughput/fairness balance. These are trends, not guaranteed ordering for every
  parameter setting or random realization.

LIMITATIONS
-----------
This is a basic, abstract scheduler-level simulation. Its rate equation is an
idealized Shannon-capacity estimate; it excludes coding/MCS quantization, control
and pilot overhead, retransmissions, HARQ, actual OFDM modulation, detailed fading
models, and full 3GPP NR protocol behavior. The per-TTI demand is a fresh synthetic
request, not a persistent packet queue. Therefore, present results as an algorithm
comparison demo, not a standards-conformance or real-network prediction.

For standards-based 5G NR system-level scheduling examples, MathWorks documentation
identifies 5G Toolbox and Wireless Network Toolbox as dependencies:
https://www.mathworks.com/help/5g/ug/nr-plug-custom-scheduler-in-system-level-simulation.html

Communications Toolbox is intended for physical-layer communication design and
simulation (e.g., modulation, channel, and waveform functions):
https://www.mathworks.com/help/comm/get-started-with-communications-toolbox.html
