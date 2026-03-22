# Business Rules

## Branch
- **BR1.** Each branch must have exactly one General Manager (GMGR) at all times.
- **BR2.** A branch can have many employees, but each employee is assigned to at most one branch.
- **BR3.** Every employee must be assigned to a branch — no unassigned employees exist in the system.
- **BR4.** A branch can have many inspections over time; each inspection belongs to exactly one branch.

## Employee
- **BR5.** Employee type is restricted to: GMGR, Shift Manager, Cook/Kitchen, Cashier/Front.
- **BR6.** Only an employee with type GMGR may manage a branch. A GMGR manages exactly one branch.

## Order
- **BR7.** An order may be placed by a registered customer or anonymously (walk-in). Customer participation in the Places relationship is partial.
- **BR8.** Every order must be processed by exactly one branch.
- **BR9.** An order must contain at least one menu item.
- **BR10.** Order type is either 'online' or 'in-person'.

## Rewards
- **BR11.** A reward is owned by exactly one customer; a customer may own many rewards.
- **BR12.** A reward may be redeemed at most once, linking it to one order. An order may redeem at most one reward.
- **BR13.** Only a registered customer can own or redeem a reward. Walk-in orders cannot redeem rewards.

## Menu & Inventory
- **BR14.** A menu item uses one or more ingredients; an ingredient may appear in many menu items. The amount required is specific to each menu-item–ingredient pairing.
- **BR15.** Each branch maintains its own inventory. Inventory quantity and last-updated timestamp are specific to each branch–ingredient pair.
