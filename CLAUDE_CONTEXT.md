# Rita's Pizza — Project Context for Claude

> Drop this file in the root of `RitasPizzaProject/` and share it at the start of any new Claude session.
> Say: "Read CLAUDE_CONTEXT.md and continue helping with our database project."

---

## Project overview

**Course:** Intro to Databases — Texas State University
**Company chosen:** Rita's Pizza (multi-branch pizza franchise)
**Repo:** https://github.com/dehoyosdata/RitasPizzaProject.git

### Repo structure
```
RitasPizzaProject/
├── part1/          ← ER design (group, due Week 7)
├── part2/          ← Oracle SQL schema + data (individual, due Week 11)
├── part3/          ← SQL queries + PL/SQL (individual, due Week 15)
└── CLAUDE_CONTEXT.md
```

### Key constraint
Parts 2 and 3 **must run on Oracle SQL*Plus** at Texas State labs — not Postgres, not Supabase.
Oracle-specific syntax: use `VARCHAR2`, `NUMBER`, `DATE`; sequences + triggers for auto-increment (no `SERIAL`).

---

## Team

- **Teammate** — wrote the relationship reasoning document (see `part1/`)
- **Me (repo owner)** — full-stack, contributing ER diagram, relational schema, business rules, writeup, and eventually Part 2 + Part 3 individually

---

## Part 1 status — IN PROGRESS (due Week 7)

### What the teammate produced
- Reasoning doc covering all 10 relationships with cardinality and justification
- Entity identification: Employee, Branch, Customer, Order, MenuItem, Ingredient, Reward, Inspection
- M:N relationship attributes called out: quantity (Contains), amount_required (Uses), quantity_on_hand + last_updated (Stocks)
- Chen notation key defined

### What still needs to be produced (my contribution)
- [ ] Requirements gathering write-up (2–3 paragraphs)
- [ ] Formal business rules list (BR1–BR15 — drafted below)
- [ ] Chen-notation ER diagram (image export for submission)
- [ ] Relational schema diagram with PK/FK annotations
- [ ] Design decision notes (alternatives considered + assumptions)
- [ ] Package as `proj1.zip`

---

## Decisions locked in

| Question | Decision |
|---|---|
| Walk-in / anonymous orders? | **Yes** — customer participation in Places is **partial** |
| Employee must belong to a branch? | **Yes** — total participation, no unassigned employees |
| Employee types tracked | GMGR, Shift Manager, Cook/Kitchen, Cashier/Front |
| Order attributes | order_date, order_type (online/in-person), total_price |
| Customer attributes | name, email, phone, rewards_pts, date_joined |
| Branch attributes | street_addr, city, phone_no, opening_hrs, seating_cap |

---

## Business rules (BR1–BR15)

### Branch
- **BR1** Each branch must have exactly one General Manager (GMGR) at all times.
- **BR2** A branch can have many employees, but each employee is assigned to at most one branch.
- **BR3** Every employee must be assigned to a branch — no unassigned employees exist in the system.
- **BR4** A branch can have many inspections over time; each inspection belongs to exactly one branch.

### Employee
- **BR5** Employee type is restricted to: GMGR, Shift Manager, Cook/Kitchen, Cashier/Front.
- **BR6** Only an employee with type GMGR may manage a branch. A GMGR manages exactly one branch.

### Order
- **BR7** An order may be placed by a customer or anonymously (walk-in). Customer participation in Places is partial.
- **BR8** Every order must be processed by exactly one branch.
- **BR9** An order must contain at least one menu item.
- **BR10** Order type is either online or in-person.

### Rewards
- **BR11** A reward is owned by exactly one customer; a customer may own many rewards.
- **BR12** A reward may be redeemed at most once — linking it to one order. An order may redeem at most one reward.
- **BR13** Only a registered customer can own or redeem a reward. Walk-in orders cannot redeem rewards.

### Menu & inventory
- **BR14** A menu item uses one or more ingredients; an ingredient may appear in many menu items. The amount required is specific to each pairing.
- **BR15** Each branch maintains its own inventory. Inventory quantity and last-updated timestamp are specific to a branch–ingredient pair.

---

## Entities and attributes

### Branch
| Attribute | Key? | Notes |
|---|---|---|
| branch_id | PK | |
| street_addr | | |
| city | | |
| phone_no | | |
| opening_hrs | | |
| seating_cap | | |
| manager_id | FK → Employee | GMGR only |

### Employee
| Attribute | Key? | Notes |
|---|---|---|
| employee_id | PK | |
| name | | |
| type | | GMGR / Shift Mgr / Cook / Cashier |
| hire_date | | |
| branch_id | FK → Branch | total participation |

### Customer
| Attribute | Key? | Notes |
|---|---|---|
| customer_id | PK | |
| name | | |
| email | | |
| phone | | |
| rewards_pts | | running balance |
| date_joined | | |

### Order
| Attribute | Key? | Notes |
|---|---|---|
| order_id | PK | |
| order_date | | datetime |
| order_type | | 'online' or 'in-person' |
| total_price | | |
| customer_id | FK → Customer | nullable (walk-in) |
| branch_id | FK → Branch | |
| reward_id | FK → Reward | nullable |

### MenuItem
| Attribute | Key? |
|---|---|
| item_id | PK |
| name | |
| price | |
| category | |

### Ingredient
| Attribute | Key? |
|---|---|
| ingredient_id | PK |
| name | |
| unit | |

### Reward
| Attribute | Key? | Notes |
|---|---|---|
| reward_id | PK | |
| description | | |
| customer_id | FK → Customer | |

### Inspection
| Attribute | Key? | Notes |
|---|---|---|
| inspection_id | PK | |
| insp_date | | |
| result | | |
| branch_id | FK → Branch | |

---

## Relationships summary

| # | Name | Entities | Cardinality | Attributes on relationship |
|---|---|---|---|---|
| 1 | WorksAt | Employee → Branch | N:1 | — |
| 2 | Manages | Employee → Branch | 1:1 (GMGR only) | — |
| 3 | Places | Customer → Order | 1:N | — (partial on Customer) |
| 4 | ProcessedBy | Branch → Order | 1:N | — |
| 5 | Contains | Order ↔ MenuItem | M:N | quantity, item_price |
| 6 | Uses | MenuItem ↔ Ingredient | M:N | amt_required |
| 7 | Stocks | Branch ↔ Ingredient | M:N | qty_on_hand, last_updated |
| 8 | Owns | Customer → Reward | 1:N | — |
| 9 | Redeems | Reward ↔ Order | 0..1 : 0..1 | — |
| 10 | HasInspection | Branch → Inspection | 1:N | — |

### Associative tables (M:N resolved)
- `ORDER_ITEM` (order_id FK, item_id FK, quantity, item_price)
- `RECIPE` (item_id FK, ingredient_id FK, amt_required)
- `INVENTORY` (branch_id FK, ingredient_id FK, qty_on_hand, last_updated)

---

## Design decisions (for proj1 writeup)

### WorksAt vs Manages as separate relationships
We considered combining both into a single relationship with a role attribute, but kept them separate because the participation rules are different: all employees participate in WorksAt (total), but only GMGRs participate in Manages (partial + restricted by type). Keeping them separate makes the constraint explicit in the diagram.

### Walk-in orders
We considered requiring all orders to have a customer account (total participation). We chose partial participation because Rita's Pizza serves walk-in customers who may not want to register, which is realistic for a pizza counter. Rewards cannot be applied to walk-in orders (BR13).

### Inventory as a relationship, not an entity
At the conceptual ER level, inventory describes how much of a given ingredient a branch has — this is naturally a property of the Branch–Ingredient relationship (Stocks), not a standalone real-world object. At the relational level it becomes an INVENTORY table, but the design intent is relationship-based.

### Employee type as an attribute, not a subtype
We considered making GMGR, Shift Manager, etc. into subtypes (ISA hierarchy). We chose a single `type` attribute instead because the subtypes share all the same attributes — there is no attribute that exists for GMGR but not for Cook. The only behavioral difference is the Manages relationship, which is already captured separately.

---

## Part 2 preview (individual — Week 11)

Files needed:
- `proj2-makeSchema.sql` — CREATE TABLE statements + sequences/triggers
- `proj2-dropDb.sql` — DROP TABLE in reverse FK order
- 5 sample rows per table (INSERT statements)

Must run on **Oracle SQL*Plus** at Texas State. Key Oracle differences from Postgres/Supabase:
- `VARCHAR2(n)` not `VARCHAR`
- `NUMBER(p,s)` not `DECIMAL`
- No `SERIAL` — use `CREATE SEQUENCE` + `BEFORE INSERT` trigger
- `DATE` stores date+time in Oracle
- String concat uses `||`

## Part 3 preview (individual — Week 15)

Will need:
- SELECT queries with JOINs, GROUP BY, subqueries
- PL/SQL procedures — good candidates:
  - Place an order (insert order + order items, update inventory)
  - Redeem a reward (check one-time-use constraint, link to order)
  - Log an inspection result
  - Report branch sales totals

---

## Optional bonus (post Week 7)

A deployed web dashboard using:
- **Supabase** (Postgres mirror of the schema) — account already created
- **React + Recharts** for branch sales, ingredient usage, reward tracking charts
- **Vercel** for hosting — shareable link for the team

This is separate from Oracle deliverables and does not replace them.
