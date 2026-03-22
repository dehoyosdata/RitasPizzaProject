# Requirements Gathering

## Overview

Rita's Pizza is a multi-branch pizza franchise that needs a centralized database system to manage its day-to-day operations across all locations. Each branch operates semi-independently — it has its own staff, inventory, and order flow — but the franchise as a whole needs consistent tracking of employees, menu offerings, customer loyalty, and health inspections. The goal of this system is to provide a unified data model that supports operational reporting (e.g., branch sales, ingredient usage) while reflecting the real-world constraints of a food-service business.

## Domain Research and Requirements

To gather requirements beyond the initial project brief, we examined how real pizza franchises operate. Branches typically maintain their own ingredient stock, reorder independently, and staff their own shifts. Customers may order in person at the counter (walk-ins) or online, and not every customer registers an account — walk-in orders are common and must be supported without requiring a customer record. Franchise loyalty programs reward repeat customers with redeemable offers, but each reward can only be used once. Health and safety inspections are conducted per location and must be logged with dates and results for compliance purposes.

## Key Functional Requirements

The database must support the following:

- **Employee management:** Track employees by branch, role (General Manager, Shift Manager, Cook/Kitchen, Cashier/Front), name, hire date, and wage. Each branch must have exactly one General Manager.
- **Branch operations:** Store branch details including address, phone, operating hours, and seating capacity. Each branch manages its own inventory of ingredients with per-branch quantities and timestamps.
- **Order processing:** Record orders with date, type (online or in-person), and total price. Orders are always processed by a specific branch. An order may optionally be linked to a registered customer, or placed anonymously by a walk-in.
- **Menu and recipes:** Maintain a catalog of menu items with prices and categories. Track which ingredients each item requires and in what amounts (recipes).
- **Customer rewards:** Registered customers accumulate reward points and may earn redeemable rewards. Each reward can be redeemed at most once, on a single order. Walk-in customers cannot redeem rewards.
- **Health inspections:** Log inspection events per branch with date, result, and optional notes.
