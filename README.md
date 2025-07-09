📦 Inventory Shipment Simulation Models
This repository contains MATLAB simulations of two fundamental inventory replenishment policies:

✅ 1. Static Policy — Time-Based Replenishment
In this model, shipments occur at fixed time intervals (e.g., every T days), regardless of the number of orders received.

Orders are accumulated in a buffer.

At each fixed interval T, all pending orders are shipped together.

Each order incurs a waiting cost based on how long it remained in the buffer.

Shipments are triggered periodically.

Inventory builds up and is reset to zero at each shipment.

Some orders may wait longer depending on when they arrive relative to the shipment day.

✅ 2. Dynamic Policy — Quantity-Based Replenishment
This model triggers a shipment as soon as a certain number of units (e.g., 6) have accumulated in the buffer.

Each order is added to the buffer immediately upon arrival.

When the total accumulated orders reach a predefined threshold, a shipment is triggered immediately.

All orders in the buffer are shipped at once, and their individual waiting times are tracked.

The system is more responsive to demand fluctuations.

Waiting times vary per order but are usually shorter than in the static model.

💰 Cost Components (Common to Both Models):

Waiting Cost: based on cumulative waiting time of all orders (unit-days × cost per unit-time).

📈 Insights using the Visual Outputs:

Inventory level over time / Each order increases the inventory, while cleaning resets the inventory.

Shipment days / When a shipment is made, and total number of shipments made.

Cumulative order waiting time (In each cycle) 
