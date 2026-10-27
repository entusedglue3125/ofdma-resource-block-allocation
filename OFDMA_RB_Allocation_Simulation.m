%% OFDMA Resource-Block Allocation: Multi-User Scheduling and Utilization
% Basic, toolbox-free MATLAB simulation.
% Schedulers: Round Robin (RR), Max-Rate, and Proportional Fair (PF).
%
% This is an abstract scheduler-level demonstration, NOT a standards-compliant
% LTE/5G NR PHY or full 5G system-level simulation.
%
% Required: Base MATLAB only. No Communications Toolbox, 5G Toolbox,
% Wireless Network Toolbox, or Simulink is required for this script.
%
% Outputs written to the current folder:
%   ofdma_scheduler_summary.csv
%   ofdma_user_throughput.csv
%   ofdma_tti_metrics.csv
%   ofdma_allocation_heatmaps.png
%   ofdma_user_throughput.png
%   ofdma_scheduler_metrics.png
%   ofdma_cell_throughput_over_time.png

clear; clc; close all;

fprintf('OFDMA RB Allocation Simulation\n');
fprintf('Dependency check: Base MATLAB only; no toolbox functions are used.\n\n');

%% 1. Simulation parameters (edit these to experiment)
rng(7, 'twister');           % Repeatable random scenario in the same MATLAB release

nUsers = 8;                  % Number of simulated user equipment (UEs)
nRB = 48;                    % Resource blocks available per TTI
nTTI = 100;                  % Number of scheduling intervals
rbBandwidthHz = 180e3;       % Simplified bandwidth per RB: 180 kHz
maxRBRequest = 8;            % Per-user RB request limit in each TTI
fadingStdDb = 4;             % Random per-RB/per-TTI SNR variation (dB)
pfAlpha = 0.10;              % Exponential-average update factor for PF

algorithmNames = {'Round Robin', 'Max-Rate', 'Proportional Fair'};
nAlgorithms = numel(algorithmNames);

%% 2. Generate user SNR, RB rates, and per-TTI traffic requests
% Different average SNRs represent users at different channel conditions.
meanSNRdB = linspace(4, 22, nUsers)' + 1.5*randn(nUsers, 1);

% snrDb(user, RB, TTI)
snrDb = zeros(nUsers, nRB, nTTI);
for t = 1:nTTI
    snrDb(:, :, t) = repmat(meanSNRdB, 1, nRB) ...
        + fadingStdDb*randn(nUsers, nRB);
end
snrDb = max(-5, min(30, snrDb));    % Keep simulated SNR within a plausible range
snrLinear = 10.^(snrDb/10);

% Shannon-capacity-style rate estimate per RB, in bits/second.
% This is an idealized upper-bound model; it omits coding, pilots, control,
% retransmissions, protocol overhead, and standardized MCS quantization.
rateBps = rbBandwidthHz .* log2(1 + snrLinear);

% Synthetic fresh RB requests each TTI, shared by all schedulers for fairness.
% This gives utilization meaning: if total demand is below nRB, unused RBs remain idle.
demandRB = randi([0, maxRBRequest], nUsers, nTTI);

%% 3. Run the three schedulers
% allocation(RB, TTI, algorithm) stores the scheduled UE index; 0 means idle.
allocation = zeros(nRB, nTTI, nAlgorithms);
userRateBps = zeros(nUsers, nTTI, nAlgorithms);
allocatedRBs = zeros(nTTI, nAlgorithms);
cellThroughputMbps = zeros(nTTI, nAlgorithms);

for a = 1:nAlgorithms
    rrPointer = 1;

    % PF's past-average throughput estimate (initialization is a model choice).
    if a == 3
        avgThroughputBps = mean(rateBps(:, :, 1), 2) * (maxRBRequest/2);
        avgThroughputBps = max(avgThroughputBps, 1);
    end

    for t = 1:nTTI
        remainingDemand = demandRB(:, t);

        % Allocate at most one UE to each RB.
        for rb = 1:nRB
            eligible = find(remainingDemand > 0);
            if isempty(eligible)
                break;   % No user has any remaining request in this TTI
            end

            eligibleRates = reshape(rateBps(eligible, rb, t), [], 1);

            if a == 1
                % Round Robin: pick the next requesting UE in cyclic order.
                scanOrder = mod((rrPointer - 1) + (0:nUsers-1), nUsers) + 1;
                firstEligible = find(remainingDemand(scanOrder) > 0, 1, 'first');
                chosenUE = scanOrder(firstEligible);
                rrPointer = mod(chosenUE, nUsers) + 1;

            elseif a == 2
                % Max-Rate: choose the eligible UE with the highest rate on this RB.
                [~, localIndex] = max(eligibleRates);
                chosenUE = eligible(localIndex);

            else
                % Proportional Fair: instantaneous RB rate / past-average UE throughput.
                pfMetric = eligibleRates ./ max(avgThroughputBps(eligible), 1);
                [~, localIndex] = max(pfMetric);
                chosenUE = eligible(localIndex);
            end

            allocation(rb, t, a) = chosenUE;
            remainingDemand(chosenUE) = remainingDemand(chosenUE) - 1;
            userRateBps(chosenUE, t, a) = userRateBps(chosenUE, t, a) ...
                + rateBps(chosenUE, rb, t);
            allocatedRBs(t, a) = allocatedRBs(t, a) + 1;
        end

        % Update PF's moving average once per TTI (including zero-service UEs).
        if a == 3
            avgThroughputBps = (1 - pfAlpha)*avgThroughputBps ...
                + pfAlpha*userRateBps(:, t, a);
        end

        cellThroughputMbps(t, a) = sum(userRateBps(:, t, a))/1e6;
    end
end

%% 4. Compute summary metrics
meanCellThroughputMbps = mean(cellThroughputMbps, 1)';
meanRBUtilizationPct = mean(allocatedRBs, 1)'/nRB*100;

avgUserThroughputMbps = zeros(nUsers, nAlgorithms);
jainFairness = zeros(nAlgorithms, 1);

for a = 1:nAlgorithms
    avgUserThroughputMbps(:, a) = mean(userRateBps(:, :, a), 2)/1e6;
    x = avgUserThroughputMbps(:, a);
    if sum(x.^2) > 0
        jainFairness(a) = (sum(x)^2)/(nUsers*sum(x.^2));
    else
        jainFairness(a) = 0;
    end
end

summaryTable = table(string(algorithmNames(:)), meanCellThroughputMbps, ...
    meanRBUtilizationPct, jainFairness, ...
    'VariableNames', {'Scheduler', 'MeanCellThroughput_Mbps', ...
    'MeanRBUtilization_pct', 'JainFairnessIndex'});

fprintf('=== Scheduler summary (generated by this run) ===\n');
disp(summaryTable);

perUserTable = table((1:nUsers)', avgUserThroughputMbps(:, 1), ...
    avgUserThroughputMbps(:, 2), avgUserThroughputMbps(:, 3), ...
    'VariableNames', {'User', 'RoundRobin_Mbps', 'MaxRate_Mbps', ...
    'ProportionalFair_Mbps'});

fprintf('=== Mean throughput per UE (Mbps) ===\n');
disp(perUserTable);

ttiTable = table((1:nTTI)', sum(demandRB, 1)', allocatedRBs(:, 1), ...
    allocatedRBs(:, 2), allocatedRBs(:, 3), ...
    cellThroughputMbps(:, 1), cellThroughputMbps(:, 2), ...
    cellThroughputMbps(:, 3), ...
    'VariableNames', {'TTI', 'TotalRBRequests', 'RR_AllocatedRBs', ...
    'MaxRate_AllocatedRBs', 'PF_AllocatedRBs', 'RR_CellMbps', ...
    'MaxRate_CellMbps', 'PF_CellMbps'});

%% 5. Sanity checks
assert(all(allocatedRBs(:) <= nRB), 'Scheduler allocated more than available RBs.');
assert(all(allocatedRBs(:) >= 0), 'Allocated RB count cannot be negative.');
for a = 1:nAlgorithms
    assert(all(sum(allocation(:, :, a) > 0, 1)' == allocatedRBs(:, a)), ...
        'Allocation grid and allocated-RB counters do not match.');
end
fprintf('Sanity checks passed: at most %d RBs were allocated per TTI.\n', nRB);
fprintf('Mean RB utilization is below 100%% when the generated demand is below capacity.\n\n');

%% 6. Figure 1: RB allocation over time (0 means idle)
fig1 = figure('Name', 'OFDMA Resource-Block Allocation', 'Color', 'w');
ueLabels = [{'Idle'}, arrayfun(@(u) sprintf('UE%d', u), 1:nUsers, ...
    'UniformOutput', false)];

for a = 1:nAlgorithms
    subplot(1, nAlgorithms, a);
    imagesc(1:nTTI, 1:nRB, allocation(:, :, a));
    set(gca, 'YDir', 'normal');
    caxis([-0.5, nUsers + 0.5]);
    colormap(gca, parula(nUsers + 1));
    xlabel('TTI');
    ylabel('Resource block');
    title(algorithmNames{a});
    xlim([1 nTTI]);
    colorbarHandle = colorbar;
    colorbarHandle.Ticks = 0:nUsers;
    colorbarHandle.TickLabels = ueLabels;
end
saveas(fig1, 'ofdma_allocation_heatmaps.png');

%% 7. Figure 2: mean throughput received by each UE
fig2 = figure('Name', 'Mean Throughput Per User', 'Color', 'w');
bar(1:nUsers, avgUserThroughputMbps);
xlabel('User equipment (UE)');
ylabel('Mean delivered rate across TTIs (Mbps)');
title('Per-User Throughput by Scheduler');
legend(algorithmNames, 'Location', 'northoutside', 'Orientation', 'horizontal');
grid on;
saveas(fig2, 'ofdma_user_throughput.png');

%% 8. Figure 3: cell throughput, resource utilization, fairness
fig3 = figure('Name', 'OFDMA Scheduler Metrics', 'Color', 'w');

subplot(3, 1, 1);
bar(meanCellThroughputMbps);
set(gca, 'XTick', 1:nAlgorithms, 'XTickLabel', algorithmNames);
ylabel('Mbps');
title('Mean Aggregate Cell Throughput');
grid on;

subplot(3, 1, 2);
bar(meanRBUtilizationPct);
set(gca, 'XTick', 1:nAlgorithms, 'XTickLabel', algorithmNames);
ylabel('Utilization (%)');
title('Mean RB Utilization');
ylim([0 100]);
grid on;

subplot(3, 1, 3);
bar(jainFairness);
set(gca, 'XTick', 1:nAlgorithms, 'XTickLabel', algorithmNames);
ylabel('Jain index');
title('Throughput Fairness (1 is perfectly fair)');
ylim([0 1]);
grid on;
saveas(fig3, 'ofdma_scheduler_metrics.png');

%% 9. Figure 4: aggregate throughput per TTI
fig4 = figure('Name', 'Cell Throughput Over Time', 'Color', 'w');
plot(1:nTTI, cellThroughputMbps, 'LineWidth', 1.2);
xlabel('TTI');
ylabel('Aggregate scheduled rate (Mbps)');
title('Cell Throughput by TTI');
legend(algorithmNames, 'Location', 'best');
grid on;
saveas(fig4, 'ofdma_cell_throughput_over_time.png');

%% 10. Export CSV outputs
writetable(summaryTable, 'ofdma_scheduler_summary.csv');
writetable(perUserTable, 'ofdma_user_throughput.csv');
writetable(ttiTable, 'ofdma_tti_metrics.csv');

fprintf('Files saved in current folder:\n');
fprintf('  ofdma_scheduler_summary.csv\n');
fprintf('  ofdma_user_throughput.csv\n');
fprintf('  ofdma_tti_metrics.csv\n');
fprintf('  ofdma_allocation_heatmaps.png\n');
fprintf('  ofdma_user_throughput.png\n');
fprintf('  ofdma_scheduler_metrics.png\n');
fprintf('  ofdma_cell_throughput_over_time.png\n');

fprintf('\nInterpretation notes:\n');
fprintf('- Max-Rate often increases aggregate throughput by favoring strong instantaneous channels.\n');
fprintf('- Proportional Fair aims to balance throughput and user fairness; exact outcomes depend on random channels/demand.\n');
fprintf('- Round Robin cycles through users with pending RB requests; user bit rates may still differ due to SNR.\n');
fprintf('- This model uses Shannon-rate estimates and synthetic RB demand, not a 3GPP-compliant PHY/MAC stack.\n');
