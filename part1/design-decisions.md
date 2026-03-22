# Design Decisions

## 1. WorksAt vs Manages as Separate Relationships

We considered combining both into a single relationship with a role attribute, but kept them separate because the participation rules differ: all employees participate in WorksAt (total participation), but only GMGRs participate in Manages (partial, restricted by type). Keeping them separate makes the constraint explicit in the ER diagram and avoids ambiguity.

## 2. Walk-in Orders (Partial Participation in Places)

We considered requiring all orders to have a customer account (total participation). We chose partial participation because Rita's Pizza serves walk-in customers who may not want to register, which is realistic for a pizza counter. Rewards cannot be applied to walk-in orders (BR13), so the system remains consistent.

## 3. Inventory as a Relationship, Not an Entity

At the conceptual ER level, inventory describes how much of a given ingredient a branch currently has — this is naturally a property of the Branch–Ingredient relationship (Stocks), not a standalone real-world object. At the relational level it becomes an INVENTORY table with a composite key, but the conceptual design intent is relationship-based.

## 4. Employee Type as an Attribute, Not a Subtype (ISA)

We considered making GMGR, Shift Manager, Cook/Kitchen, and Cashier/Front into subtypes using an ISA hierarchy. We chose a single `type` attribute instead because the subtypes share all the same attributes — there is no attribute unique to one type. The only behavioral difference is the Manages relationship, which is captured separately.

## 5. Attribute Reconciliation and Naming Conventions

During the design process, team members independently proposed slightly different attribute sets. We reconciled these as follows:
- **Branch:** We used specific address fields (`street_addr`, `city`) rather than a single `location` field, for better queryability. We dropped `reputation` as it is subjective and not captured by a transactional system.
- **Employee:** We merged `role` and `employee_type` into a single `type` attribute to avoid redundancy. We added `wage` from the teammate's proposal as it is operationally useful.
- **Order:** We standardized on `total_price` over `total_amount` for consistency with MenuItem's `price` field.
- **Ingredient:** We added `cost_per_unit` (useful for inventory valuation) but dropped `expiration_date` (which belongs at the inventory/batch level, not the ingredient definition).
- **Reward:** We added `reward_type`, `issue_date`, and `used_status` to support the one-time redemption rule (BR12).
- **Inspection:** We kept both `result` (structured outcome) and `notes` (free-text details).

## 6. Redeems as a Separate Relationship

We modeled reward redemption as its own relationship (Redeems) between Reward and Order, rather than just a foreign key on Order. This makes the one-time-use constraint (BR12) explicit: a reward participates in Redeems at most once (0..1 cardinality on both sides). It also cleanly separates ownership (Owns) from usage (Redeems).

## Assumptions

- A branch always has exactly one GMGR; the system does not track historical manager assignments.
- Menu items are franchise-wide (not branch-specific). All branches offer the same menu.
- Ingredient definitions are global; only inventory quantities vary by branch.
- An order belongs to exactly one branch and cannot span multiple locations.
- Reward points are tracked as a running balance on the Customer entity; individual point transactions are not modeled.
