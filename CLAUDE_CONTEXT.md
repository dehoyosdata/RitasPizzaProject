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
├── part1/                          ← ER design (group, due Week 7)
│   ├── business-rules.md
│   ├── chen-diagram-reference.txt  ← reference for drawing Chen diagram in draw.io
│   ├── design-decisions.md
│   ├── er-diagram.mmd             ← Mermaid source (crow's foot, not Chen)
│   ├── relational-schema.dbml     ← paste into dbdiagram.io to generate diagram
│   ├── relational-schema.md       ← full table definitions + constraints
│   └── requirements-gathering.md
├── part2/                          ← Oracle SQL schema + data (individual, due Week 11)
├── part3/                          ← SQL queries + PL/SQL (individual, due Week 15)
├── CLAUDE_CONTEXT.md
├── TEAM_UPDATE.md                  ← shared with team, pending their review
├── Database Project Part 1.pdf     ← current working document
└── s26_Database_Project_Specs (1).pdf  ← assignment specs from professor
```

### Key constraint
Parts 2 and 3 **must run on Oracle SQL*Plus** at Texas State labs — not Postgres, not Supabase.
Oracle-specific syntax: use `VARCHAR2`, `NUMBER`, `DATE`; sequences + triggers for auto-increment (no `SERIAL`).

---

## Team

- **Teammates (Stephen Cox, Hayden Domino, Chandler Duffey, Harrison Crabb)** — wrote the relationship reasoning document
- **Me / Davos DeHoyos (repo owner)** — wrote requirements gathering, business rules, design decisions, relational schema, constraints section. Contributing Part 2 + Part 3 individually.

---

## Part 1 status — NEARLY COMPLETE (due Week 7)

### Done (in the document)
- [x] Requirements gathering write-up (overview, domain research, functional requirements)
- [x] Formal business rules list (BR1–BR15)
- [x] Summary and reasoning for each major relation (teammate's section, kept as-is)
- [x] Design decision notes (6 decisions + assumptions)
- [x] Relational schema diagram (dbdiagram.io export — image in doc)
- [x] Relational schema tables with PK/FK/constraints for all 11 tables
- [x] Constraints not expressible in relational schema

### Still TODO
- [ ] **Chen-notation ER diagram** — needs to be redrawn in draw.io with merged attributes (delegated to team, waiting on response). Reference: `part1/chen-diagram-reference.txt`
- [ ] **Two small text edits** in teammate's reasoning section:
  - Italic note on Places: make definitive ("partial participation to support walk-ins")
  - Italic note on Redeems: decide yes/no on `redeem_date` attribute
- [ ] **Remove "Diagram TODO:" label** from doc, replace with "# ER Diagram"
- [ ] **Package as `proj1.zip`** — export PDF, zip, submit

### Waiting on team
- Approval of attribute merge decisions (listed in TEAM_UPDATE.md)
- Someone to pick up the Chen diagram task

---

## Attribute merge decisions (made 2026-03-22)

These were decided during reconciliation of teammate's original attributes vs. mine. Sent to team for approval, not yet confirmed.

| Change | Rationale |
|---|---|
| `location` → `street_addr` + `city` | Better queryability |
| Dropped `reputation` from Branch | Subjective, not transactional |
| Merged `role` + `employee_type` → `type` | Redundant — same concept |
| Added `wage` to Employee | From teammate's proposal, operationally useful |
| `total_amount` → `total_price` | Consistent with MenuItem's `price` |
| Dropped `certification_status` from Employee | Not in any business rule |
| Dropped `expiration_date` from Ingredient | Belongs at inventory/batch level |
| Added `cost_per_unit` to Ingredient | Useful for inventory valuation |
| Added `reward_type`, `issue_date`, `used_status` to Reward | Supports BR12 one-time redemption |
| Added `notes` to Inspection | Free-text alongside structured `result` |
| Named Order table `PIZZA_ORDER` | `ORDER` is reserved in Oracle SQL |

---

## Entities and attributes (MERGED — current)

### BRANCH
| Attribute | Key? | Notes |
|---|---|---|
| branch_id | PK | |
| street_addr | | |
| city | | |
| phone_no | | |
| opening_hrs | | |
| seating_cap | | |
| manager_id | FK → Employee | UNIQUE, NOT NULL, GMGR only |

### EMPLOYEE
| Attribute | Key? | Notes |
|---|---|---|
| employee_id | PK | |
| name | | |
| type | | GMGR / Shift Manager / Cook/Kitchen / Cashier/Front |
| hire_date | | |
| wage | | NUMBER(8,2) |
| branch_id | FK → Branch | NOT NULL, total participation |

### CUSTOMER
| Attribute | Key? | Notes |
|---|---|---|
| customer_id | PK | |
| name | | |
| email | | |
| phone | | |
| rewards_pts | | DEFAULT 0, running balance |
| date_joined | | |

### PIZZA_ORDER
| Attribute | Key? | Notes |
|---|---|---|
| order_id | PK | |
| order_date | | DATE, NOT NULL |
| order_type | | 'online' or 'in-person' |
| total_price | | NUMBER(10,2) |
| customer_id | FK → Customer | nullable (walk-in) |
| branch_id | FK → Branch | NOT NULL |
| reward_id | FK → Reward | nullable, UNIQUE (at most one redemption) |

### MENU_ITEM
| Attribute | Key? | Notes |
|---|---|---|
| item_id | PK | |
| name | | |
| price | | NUMBER(8,2) |
| category | | |

### INGREDIENT
| Attribute | Key? | Notes |
|---|---|---|
| ingredient_id | PK | |
| name | | |
| unit | | |
| cost_per_unit | | NUMBER(8,2) |

### REWARD
| Attribute | Key? | Notes |
|---|---|---|
| reward_id | PK | |
| description | | |
| reward_type | | |
| issue_date | | |
| used_status | | VARCHAR2(1), DEFAULT 'N', CHECK Y/N |
| customer_id | FK → Customer | NOT NULL |

### INSPECTION
| Attribute | Key? | Notes |
|---|---|---|
| inspection_id | PK | |
| insp_date | | DATE, NOT NULL |
| result | | NOT NULL |
| notes | | VARCHAR2(500) |
| branch_id | FK → Branch | NOT NULL |

### Associative tables (M:N resolved)
- `ORDER_ITEM` (order_id PK/FK, item_id PK/FK, quantity, item_price)
- `RECIPE` (item_id PK/FK, ingredient_id PK/FK, amt_required)
- `INVENTORY` (branch_id PK/FK, ingredient_id PK/FK, qty_on_hand, last_updated)

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

## Constraints not expressible in relational schema

1. **BR1/BR6** — manager_id UNIQUE FK ensures at most one manager, but enforcing `type = 'GMGR'` requires a trigger
2. **BR9** — minimum one item per order can't be enforced declaratively; needs trigger or app logic
3. **BR13** — if reward_id is set then customer_id must be NOT NULL; needs trigger or compound CHECK
4. **Circular FK** — BRANCH refs EMPLOYEE (manager_id) and EMPLOYEE refs BRANCH (branch_id); handle with deferred constraints or NULL-then-update

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
