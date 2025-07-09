% === DYNAMIC POLICY: Event-Based Replenishment ===
clear; clc;

% --- Parameters ---
days = 300;                         % Total days that simulation will run
lambda = 2;                          % Average order rate (orders per day)
shipmentThreshold = 6;              % Shipment triggered after this many orders
fixedCostPerShipment = 500;
UnitVariableCost = 1;
w = 0.5;                             % Waiting cost per unit per day

% --- Initialize ---
buffer = 0;
eventTime = 0;
shipmentTimes = [];
totalShipped = 0;
totalWaitingTime = 0;
orderArrivalTimes = [];

inventoryHistory = [];
inventoryTimestamps = [];

% === EVENT-BASED SIMULATION ===
while eventTime < days
    % Generate interarrival time
    interArrival = -log(rand) / lambda;
    eventTime = eventTime + interArrival;
    if eventTime > days
        break
    end

    % New order arrives
    buffer = buffer + 1;
    orderArrivalTimes = [orderArrivalTimes, eventTime];

    % Log inventory state
    inventoryHistory(end+1) = buffer;
    inventoryTimestamps(end+1) = eventTime;

    % Trigger shipment
    if buffer >= shipmentThreshold
        shipmentTimes(end+1) = eventTime;
        totalShipped = totalShipped + shipmentThreshold;

        waitingTimes = eventTime - orderArrivalTimes(1:shipmentThreshold);
        totalWaitingTime = totalWaitingTime + sum(waitingTimes);

        % Remove shipped orders
        orderArrivalTimes(1:shipmentThreshold) = [];
        buffer = buffer - shipmentThreshold;

        % Log inventory after shipment
        inventoryHistory(end+1) = buffer;
        inventoryTimestamps(end+1) = eventTime;
    end
end

% --- Cost Calculations ---
totalShipments = length(shipmentTimes);
variableCost = totalShipped * UnitVariableCost;
waitingCost = w * totalWaitingTime;
totalCost = totalShipments * fixedCostPerShipment + variableCost + waitingCost;
costPerDay = totalCost / days;

if totalShipments > 0
    costPerShipment = totalCost / totalShipments;
else
    costPerShipment = NaN;
end

% --- Output Report ---
fprintf('=== EVENT-BASED DYNAMIC POLICY ===\n');
fprintf('Total Shipments: %d\n', totalShipments);
fprintf('Total Units Shipped: %d\n', totalShipped);
fprintf('Total Waiting Time (unit-days): %.2f\n', totalWaitingTime);
fprintf('Variable Cost: $%.2f\n', variableCost);
fprintf('Waiting Cost: $%.2f\n', waitingCost);
fprintf('Total Cost: $%.2f\n', totalCost);
fprintf('Average Cost per Shipment: $%.2f\n', costPerShipment);
fprintf('Average Cost per Day: $%.2f\n', costPerDay);

% --- Plot: Inventory Level by Event ---
figure;
stairs(inventoryTimestamps, inventoryHistory, 'b-', 'LineWidth', 1.5); hold on;
stem(shipmentTimes, zeros(size(shipmentTimes)), 'r', 'filled', 'LineStyle', 'none');
xlabel('Time (Days)');
ylabel('Inventory (Orders in Buffer)');
title('Inventory Level Over Time (Event-Based Simulation)');
legend('Inventory Level', 'Shipment Events');
grid on;

% === FUNCTION: Optional if Poisson needed elsewhere ===
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
