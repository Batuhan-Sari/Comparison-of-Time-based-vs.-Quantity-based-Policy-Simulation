% === STATIC POLICY: Event-Based Replenishment, No Lead Time ===
clear; clc;

% --- Parameters ---
lambda = 10;
mu = 0.01;
T = 10;                                  % Fixed shipment in terval
fixedCostPerShipment = 500;
variableCostPerUnit = 10;
w = 1;                                % Waiting cost per unit per day
c = 2;
days = 1000*T;                        % # of cycles simulation runs  

% --- Initialization ---
eventTime = 0;
shipments = 0;
shipmentTimes = [];
unitsShipped = [];
inventoryLevel = 0;
inventoryHistory = [];
inventoryTimestamps = [];

totalWaitingTime = 0;
waitingTimePerShipment = [];
orderArrivalTimes = [];

totalOrders = 0;
nextShipmentTime = T;

% === Cancellation Setup ===
canceledWaitingTimes = [];
orderPatienceDeadlines = [];  % For each order there is Exp. distributed patience time
nextOrderTime = -log(rand) / lambda;
nextCancelTime = -log(rand) / mu;

% === EVENT-BASED SIMULATION ===
while eventTime < days
    % --- Cancel orders whose patience has expired (before any event) ---
    expiredIdx = find(orderPatienceDeadlines <= eventTime);
    for i = fliplr(expiredIdx)
        canceledWaitingTimes(end+1) = eventTime - orderArrivalTimes(i);
        orderArrivalTimes(i) = [];
        orderPatienceDeadlines(i) = [];
        inventoryLevel = inventoryLevel - 1;

        inventoryHistory(end+1) = inventoryLevel;
        inventoryTimestamps(end+1) = eventTime;
    end

    % Choose the next event (order or cancellation)
    if nextOrderTime <= nextCancelTime
        % Order arrives
        eventTime = nextOrderTime;
        nextOrderTime = eventTime + (-log(rand) / lambda);

        if eventTime > days
            break;
        end

        orderArrivalTimes = [orderArrivalTimes, eventTime];
        patience = -log(rand) / mu;  % <-- ADDED
        orderPatienceDeadlines = [orderPatienceDeadlines, eventTime + patience];  % <-- ADDED
        totalOrders = totalOrders + 1;
        inventoryLevel = inventoryLevel + 1;

        inventoryHistory(end+1) = inventoryLevel;
        inventoryTimestamps(end+1) = eventTime;
        
    else
        % Cancellation occurs
        eventTime = nextCancelTime;
        nextCancelTime = eventTime + (-log(rand) / mu);

        if eventTime > days
            break;
        end

        if ~isempty(orderArrivalTimes)
            canceledWaitingTimes(end+1) = eventTime - orderArrivalTimes(1);  % Include in cost
            orderArrivalTimes(1) = [];
            orderPatienceDeadlines(1) = [];  % <-- ADDED
            inventoryLevel = inventoryLevel - 1;

            inventoryHistory(end+1) = inventoryLevel;
            inventoryTimestamps(end+1) = eventTime;
        end
    end

    % Check for shipment
    if eventTime >= nextShipmentTime
        % Cancel expired orders again before shipping (edge case)
        expiredIdx = find(orderPatienceDeadlines <= eventTime);
        for i = fliplr(expiredIdx)
            canceledWaitingTimes(end+1) = eventTime - orderArrivalTimes(i);
            orderArrivalTimes(i) = [];
            orderPatienceDeadlines(i) = [];
            inventoryLevel = inventoryLevel - 1;

            inventoryHistory(end+1) = inventoryLevel;
            inventoryTimestamps(end+1) = eventTime;
        end

        % All remaining orders are shipped now
        waitingTimes = eventTime - orderArrivalTimes;
        totalWaitingTime = totalWaitingTime + sum(waitingTimes);
        waitingTimePerShipment{end+1} = waitingTimes;
        cumulativeWaitingPerShipment = cellfun(@sum, waitingTimePerShipment);

        % Record shipment
        shipments = shipments + 1;
        shipmentTimes(end+1) = eventTime;
        unitsShipped(end+1) = length(orderArrivalTimes);

        % Reset
        orderArrivalTimes = [];
        orderPatienceDeadlines = [];  % <-- ADDED
        inventoryLevel = 0;

        inventoryHistory(end+1) = inventoryLevel;
        inventoryTimestamps(end+1) = eventTime;

        % Schedule next shipment
        nextShipmentTime = nextShipmentTime + T;
    end
end

% === Cost Calculations ===
totalUnitsShipped = sum(unitsShipped);
totalCancel = length(canceledWaitingTimes);
variableCost = totalUnitsShipped * variableCostPerUnit;
waitingCost = w * totalWaitingTime;
canceledWaitingCost = w * sum(canceledWaitingTimes);
totalCost = shipments * fixedCostPerShipment + variableCost + waitingCost + canceledWaitingCost;
averageCostPerDay = totalCost / days;

% === OUTPUT ===
fprintf('=== EVENT-BASED STATIC POLICY ===\n');
fprintf('Total Shipments: %d\n', shipments);
fprintf('Total Units Shipped: %.2f\n', totalUnitsShipped);
fprintf('Average Units in a Shipment: %.2f\n', mean(unitsShipped));
fprintf('Total Orders: %d\n', totalOrders);
fprintf('Canceled Orders: %d\n', length(canceledWaitingTimes));
fprintf('Canceled Waiting Time: %.2f\n', sum(canceledWaitingTimes));
fprintf('Total Waiting Time (unit-days): %.2f\n', totalWaitingTime);
fprintf('Variable Cost: $%.2f\n', variableCost);
fprintf('Waiting Cost: $%.2f\n', waitingCost);
fprintf('Canceled Waiting Cost: $%.2f\n', canceledWaitingCost);
fprintf('Total Cost: $%.2f\n', totalCost);
fprintf('Average Cost per Day: $%.2f\n', averageCostPerDay);


% === PLOTS === 
figure;
stairs(inventoryTimestamps, inventoryHistory, 'LineWidth', 1.5);
hold on;
stem(shipmentTimes, zeros(size(shipmentTimes)), 'r', 'filled', 'LineStyle', 'none');
xlabel('Time (Days)');
ylabel('Inventory Level');
title('Inventory Level Over Time (Event-Based Simulation)');
legend('Inventory Level', 'Shipment Events');
grid on;

%figure;
plot(1:length(cumulativeWaitingPerShipment), cumulativeWaitingPerShipment, '-o', 'LineWidth', 1.5);
xlabel('Shipment Number');
ylabel('Cumulative Waiting Time (unit-days)');
title('Cumulative Waiting Time per Shipment');
grid on;

% === PLOT: Comparison of Waiting Times (Canceled vs Non-Canceled) ===
% Prepare vectors
numShipments = length(waitingTimePerShipment);
nonCanceledWaiting = cellfun(@sum, waitingTimePerShipment);
canceledWaiting = zeros(1, numShipments);

% Distribute canceled waiting times into shipment intervals (roughly)
if ~isempty(canceledWaitingTimes)
    cancelTimes = cumsum(canceledWaitingTimes);  % approximate times
    cancelBins = discretize(cancelTimes, [0, shipmentTimes]);
    for i = 1:numShipments
        canceledWaiting(i) = sum(canceledWaitingTimes(cancelBins == i));
    end
end

% Plot
figure;
bar(1:numShipments, [nonCanceledWaiting(:), canceledWaiting(:)], 'stacked');
xlabel('Shipment Number');
ylabel('Total Waiting Time');
legend('Shipped Orders', 'Canceled Orders');
title('Comparison of Waiting Time per Shipment');
grid on;

% === Poisson Order Interarrival Generator ===
function samples = myPoisson(lambda, n)
samples = zeros(1, n);
for i = 1:n
    L = exp(-lambda);
    k = 0; p = 1;
    while p > L
        k = k + 1;
        p = p * rand();
    end
    samples(i) = k - 1;
end
end

% === Poisson Cancellation Interarrival Generator ===
function cancels = generateExpCancels(mu, n)
    cancels = -log(rand(1, n)) / mu;
end

