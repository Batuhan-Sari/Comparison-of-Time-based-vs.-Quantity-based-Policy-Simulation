% === FIXED QUANTITY-BASED POLICY: Event-Based with Cancellations and Canceled Order Tracking ===
clear; clc;

% --- Parameters ---                        
lambda = 10;                        % Order arrival rate
mu = .01;                           % Patience parameter (mean = 1/mu)
shipmentThreshold = 70;            % Ship when this many orders accumulate
fixedCostPerShipment = 250;
UnitVariableCost = 10;
w = 1;                            % Waiting cost per unit per day
c = 2;
days = 1000*shipmentThreshold / lambda; % Simulation duration

% --- Initialization ---
eventTime = 0;
shipmentTimes = [];
totalShipped = 0;
inventoryLevel = 0;
totalWaitingTime = 0;


orderCounter = 0;
orders = [];  % Each row: [ID, arrivalTime, cancelTime]


nonCanceledWaiting = [];
canceledWaiting = [];                 
canceledWaitingTimesPerShipment = [];
canceledWaitingTimes = [];
cancelTimes = [];

inventoryHistory = [];
inventoryTimestamps = [];

% Canceled Order ID tracking
canceledOrderIDsByShipment = {};   % Cell array of vectors
currentCycleCanceledIDs = [];


% First event times
nextArrival = -log(rand)/lambda;
nextCancel = inf;

% === EVENT-BASED SIMULATION ===
while eventTime < days
    % Determine next event
    if nextArrival < nextCancel
        % --- Arrival Event ---
        eventTime = nextArrival;
        if eventTime > days, break; end

        % Create order with unique ID
        orderCounter = orderCounter + 1;
        arrivalTime = eventTime;
        patience = -log(rand)/mu;
        cancelTime = arrivalTime + patience;
        orders = [orders; orderCounter, arrivalTime, cancelTime];

        % Schedule next arrival
        nextArrival = eventTime + (-log(rand)/lambda);

        % Update inventory
        inventoryLevel = inventoryLevel + 1;
        inventoryHistory(end+1) = inventoryLevel;
        inventoryTimestamps(end+1) = eventTime;

        % Update cancel
        if ~isempty(orders)
            [~, idx] = min(orders(:,3));
            nextCancel = orders(idx,3);
        end
    else
        % --- Cancellation Event ---
        eventTime = nextCancel;
        if eventTime > days, break; end

        % Cancel the earliest due order
        [~, idx] = min(orders(:,3));
        canceledOrderID = orders(idx,1);
        currentCycleCanceledIDs(end+1) = canceledOrderID;

        canceledWaitingTimes(end+1) = eventTime - orders(idx,2);
        canceledWaiting(end+1) = eventTime - orders(idx,2);
        cancelTimes(end+1) = eventTime;

        orders(idx,:) = [];
        inventoryLevel = inventoryLevel - 1;

        inventoryHistory(end+1) = inventoryLevel;
        inventoryTimestamps(end+1) = eventTime;

        if ~isempty(orders)
            [~, idx] = min(orders(:,3));
            nextCancel = orders(idx,3);
        else
            nextCancel = inf;
        end
    end

    % --- Shipment Trigger ---
    if inventoryLevel >= shipmentThreshold
        shipmentTimes(end+1) = eventTime;

        shippedNow = size(orders, 1);
        totalShipped = totalShipped + shippedNow;

        waitingTimes = eventTime - orders(:,2);  % orders(:,2) = arrival times
        totalWaitingTime = totalWaitingTime + sum(waitingTimes);
        nonCanceledWaiting(end+1) = sum(waitingTimes);
    
        % Save canceled order IDs and reset for next cycle
        canceledOrderIDsByShipment{end+1} = currentCycleCanceledIDs;
        canceledWaitingTimesPerShipment(end+1) = sum(canceledWaiting);
        currentCycleCanceledIDs = [];
        canceledWaiting = [];

        % Clear system
        orders = [];
        inventoryLevel = 0;
        nextCancel = inf;

        inventoryHistory(end+1) = inventoryLevel;
        inventoryTimestamps(end+1) = eventTime;
    end
end

% --- Cost Calculations ---
totalShipments = length(shipmentTimes);
totalCancel = length(canceledWaitingTimes);
variableCost = totalShipped * UnitVariableCost;
waitingCost = w * totalWaitingTime;
canceledWaitingCost = w * sum(canceledWaitingTimes);
totalCost = totalShipments * fixedCostPerShipment + variableCost + (waitingCost + canceledWaitingCost) + c*totalCancel;
costPerUnitPerDay = totalCost / days;


if totalShipments > 0
    costPerShipment = totalCost / totalShipments;
else
    costPerShipment = NaN;
end

% --- Output Report ---
fprintf('=== EVENT-BASED QUANTITY POLICY (FIXED) ===\n');
fprintf('Total Shipments: %d\n', totalShipments);
fprintf('Total Orders Arrived: %d\n', orderCounter);
fprintf('Total Waiting Time (unit-days): %.2f\n', totalWaitingTime);
fprintf('Variable Cost: $%.2f\n', variableCost);
fprintf('Waiting Cost: $%.2f\n', waitingCost);
fprintf('Canceled Orders Waiting Cost: $%.2f\n', canceledWaitingCost);
fprintf('Total Cost: $%.2f\n', totalCost);
fprintf('Average Cost per Unit per Day: $%.2f\n', costPerUnitPerDay);


% --- Plot 1: Inventory Level over Time ---
figure;
stairs(inventoryTimestamps, inventoryHistory, 'b-', 'LineWidth', 1.5); hold on;
if ~isempty(shipmentTimes)
    stem(shipmentTimes, zeros(size(shipmentTimes)), 'r', 'filled', 'LineStyle', 'none');
    legend('Inventory Level', 'Shipment Events');
else
    legend('Inventory Level');
end
xlabel('Time (Days)');
ylabel('Inventory Level');
title('Inventory Level Over Time');
grid on;

% --- Plot 2: Waiting Times per Shipment (Shipped vs. Canceled) ---
figure;
numShipments = length(nonCanceledWaiting);
if length(canceledWaitingTimesPerShipment) < numShipments
    canceledWaitingTimesPerShipment(end+1:numShipments) = 0;
end
bar(1:numShipments, [nonCanceledWaiting(:), canceledWaitingTimesPerShipment(:)], 'stacked');
xlabel('Shipment Number');
ylabel('Total Waiting Time');
legend('Shipped Waiting Time', 'Canceled Waiting Time');
title('Waiting Time per Shipment');
grid on;

% --- Plot 3: Canceled Order IDs per Shipment ---
figure;
numCanceled = cellfun(@length, canceledOrderIDsByShipment);
bar(1:length(numCanceled), numCanceled, 'FaceColor', [0.8500 0.3250 0.0980]);
xlabel('Shipment Number');
ylabel('Number of Canceled Orders');
title('Canceled Order IDs per Shipment');
ylim([0 max(numCanceled)+1]);
grid on;

% Annotate bars with actual canceled order IDs
for i = 1:length(canceledOrderIDsByShipment)
    ids = canceledOrderIDsByShipment{i};
   if isempty(ids)
        txt = 'None';
    else
        txt = strjoin(string(ids), ', ');
    end
    text(i, numCanceled(i) + 0.2, txt, 'HorizontalAlignment', 'center', 'FontSize', 12, 'Rotation', 0);
end
