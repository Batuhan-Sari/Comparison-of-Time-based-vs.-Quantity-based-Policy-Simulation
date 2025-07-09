% === STATIC POLICY: Event-Based Replenishment, No Lead Time ===
clear; clc;

% --- Parameters ---
days = 300;
lambda = 2;
T = 3;                                  % Fixed shipment interval
fixedCostPerShipment = 500;
variableCostPerUnit = 1;
w = 0.5;                                  % Waiting cost per unit per day

% --- Initialization ---
eventTime = 0;
shipments = 0;
shipmentDays = [];
unitsShipped = [];
inventoryLevel = 0;
inventoryHistory = [];
inventoryTimestamps = [];

totalWaitingTime = 0;
waitingTimePerShipment = [];
orderArrivalTimes = [];

totalOrders = 0;
nextShipmentTime = T;

% === EVENT-BASED SIMULATION ===
while eventTime < days
    % Generate interarrival time (exponential) for next order
    interArrival = -log(rand) / lambda;
    eventTime = eventTime + interArrival;

    if eventTime > days
        break
    end

    % One new order arrives
    orderArrivalTimes = [orderArrivalTimes, eventTime];
    totalOrders = totalOrders + 1;
    inventoryLevel = inventoryLevel + 1;

    inventoryHistory(end+1) = inventoryLevel;
    inventoryTimestamps(end+1) = eventTime;

    % Check for shipment
    if eventTime >= nextShipmentTime
        % All orders waiting are shipped now
        waitingTimes = eventTime - orderArrivalTimes;
        totalWaitingTime = totalWaitingTime + sum(waitingTimes);
        waitingTimePerShipment{end+1} = waitingTimes;
        cumulativeWaitingPerShipment = cellfun(@sum, waitingTimePerShipment);

        % Record shipment
        shipments = shipments + 1;
        shipmentDays(end+1) = eventTime;
        unitsShipped(end+1) = length(orderArrivalTimes);

        % Reset
        orderArrivalTimes = [];
        inventoryLevel = 0;

        inventoryHistory(end+1) = inventoryLevel;
        inventoryTimestamps(end+1) = eventTime;

        % Schedule next shipment
        nextShipmentTime = nextShipmentTime + T;
    end
end

% === Cost Calculations ===
totalUnitsShipped = sum(unitsShipped);
variableCost = totalUnitsShipped * variableCostPerUnit;
waitingCost = w * totalWaitingTime;
totalCost = shipments * fixedCostPerShipment + variableCost + waitingCost;
averageCostPerDay = totalCost / days;

% === OUTPUT ===
fprintf('=== EVENT-BASED STATIC POLICY ===\n');
fprintf('Total Shipments: %d\n', shipments);
fprintf('Total Units Shipped: %d\n', totalUnitsShipped);
fprintf('Total Orders: %d\n', totalOrders);
fprintf('Total Waiting Time (unit-days): %.2f\n', totalWaitingTime);
fprintf('Variable Cost: $%.2f\n', variableCost);
fprintf('Waiting Cost: $%.2f\n', waitingCost);
fprintf('Total Cost: $%.2f\n', totalCost);
fprintf('Average Cost per Day: $%.2f\n', averageCostPerDay);

% === PLOTS ===

% Inventory Level Over Time (Event-Based)
figure;
stairs(inventoryTimestamps, inventoryHistory, 'LineWidth', 1.5);
hold on;
stem(shipmentDays, zeros(size(shipmentDays)), 'r', 'filled', 'LineStyle', 'none');
xlabel('Time (Days)');
ylabel('Inventory Level');
title('Inventory Level Over Time (Event-Based Simulation)');
legend('Inventory Level', 'Shipment Events');
grid on;

% === PLOT: Cumulative Waiting Time of Orders Over Time ===
figure;
plot(1:length(cumulativeWaitingPerShipment), cumulativeWaitingPerShipment, '-o', 'LineWidth', 1.5);
xlabel('Shipment Number');
ylabel('Cumulative Waiting Time (unit-days)');
title('Cumulative Waiting Time per Shipment');
grid on;


% === Poisson Interarrival Generator ===
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
