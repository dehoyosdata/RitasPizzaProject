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
├── part1/                                  ← ER design (group, due Week 7)
│   ├── business-rules.md
│   ├── chen-diagram-reference.txt          ← reference for drawing Chen diagram in draw.io
│   ├── design-decisions.md
│   ├── er-diagram.mmd                     ← Mermaid source (crow's foot, not Chen)
│   ├── er-diagrams.pdf                    ← ER diagram PDF (added by Chandler, PR #1)
│   ├── relational-schema.dbml             ← paste into dbdiagram.io to generate diagram
│   ├── relational-schema.md               ← full table definitions + constraints
│   └── requirements-gathering.md
├── part2/                                  ← MySQL schema + seed data (due Week 11)
│   ├── docker-compose.yml                 ← MySQL 8.4 container setup
│   ├── DOCKER.md                          ← setup instructions
│   ├── TODO.md                            ← assignment requirements checklist
│   ├── .env.example                       ← connection config template
│   ├── mysql/init/
│   │   ├── proj2-makeSchema.sql           ← SUBMISSION FILE: creates all 11 tables
│   │   ├── DataGeneration/
│   │   │   ├── proj2-fillSchema.py        ← SUBMISSION FILE: Python seed script
│   │   │   └── seed_library_data.py       ← professor's example (reference only)
│   │   └── README.md
│   └── example-queries/                   ← 6 preview queries for Part 3
│       ├── 01-database-overview.sql
│       ├── 02-branch-sales-summary.sql
│       ├── 03-recent-orders.sql
│       ├── 04-menu-recipes.sql
│       ├── 05-customer-rewards.sql
│       └── 06-inventory-status.sql
├── part3/                                  ← SQL queries (individual, due Week 15)
├── CLAUDE_CONTEXT.md
├── TEAM_UPDATE.md                          ← shared with team, pending their review
├── Database Project Part 1.pdf             ← Part 1 working document
└── s26_Database_Project_Specs (1).pdf      ← original assignment specs from professor
```

### Database choice
Professor updated Part 2 guidelines (2026-04-15): **any database is allowed.** Team chose **MySQL 8.4** via Docker.
MySQL syntax: `VARCHAR(n)`, `INT`, `DECIMAL(p,s)`, `AUTO_INCREMENT` for PKs, `SET FOREIGN_KEY_CHECKS` for circular FKs.

> **Part 3 note:** The original spec says Part 3 uses Oracle SQL + PL/SQL. Need to confirm with professor whether Part 3 guidelines are also updated to allow MySQL, or if we need to port the schema.

---

## Team

- **Teammates (Stephen Cox, Hayden Domino, Chandler Duffey, Harrison Crabb)** — wrote the relationship reasoning document
- **Me / Davos DeHoyos (repo owner)** — wrote requirements gathering, business rules, design decisions, relational schema, constraints section. Contributing Part 2 + Part 3 individually.
- **Chandler Duffey** — added ER diagram PDF (PR #1, merged 2026-03-23)

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
- [ ] **Chen-notation ER diagram** — needs to be redrawn in draw.io using Chen notation (delegated to team, waiting on response). Reference: `part1/chen-diagram-reference.txt` ✓ Nomenclature verified consistent with `er-diagram.mmd`.
- [x] **Two small text edits** in teammate's reasoning section:
  - Italic note on Places: made definitive ("partial participation to support walk-ins")
  - Italic note on Redeems: decided NO on `redeem_date` attribute
- [x] **Remove "Diagram TODO:" label** from doc, replace with "# ER Diagram"
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
| Named Order table `PIZZA_ORDER` | `ORDER` is reserved in SQL |

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

## Part 2 status — COMPLETE (due Week 11)

**Professor updated guidelines (2026-04-15):** Ignore old Part 2 spec. Any database allowed. Schema and data must be in separate files.

### Submission files
- `part2/mysql/init/proj2-makeSchema.sql` — creates all 11 tables (empty), MySQL syntax, well-commented
- `part2/mysql/init/DataGeneration/proj2-fillSchema.py` — Python seed script (stdlib only, no external deps)

### What the seed script generates
| Table | Records | Notes |
|---|---|---|
| BRANCH | 5 | Texas cities (San Marcos, New Braunfels, Austin, Kyle, Wimberley) |
| EMPLOYEE | 30 | 6 per branch: 1 GMGR + 1 Shift Mgr + 2 Cooks + 2 Cashiers |
| CUSTOMER | 80 | Configurable via `--customers` flag |
| MENU_ITEM | 18 | Pizzas, sides, desserts, drinks |
| INGREDIENT | 30 | Pizza-domain ingredients with costs |
| REWARD | 60 | Discount, Free Item, Special types |
| PIZZA_ORDER | 200 | Configurable via `--orders`; 72% registered, 28% walk-in |
| INSPECTION | 20 | 4 per branch |
| ORDER_ITEM | ~400 | 1–4 items per order |
| RECIPE | ~75 | Full ingredient lists for all 18 menu items |
| INVENTORY | 150 | All 30 ingredients × 5 branches |

### How the circular FK is handled
BRANCH and EMPLOYEE reference each other. The seed script uses `SET FOREIGN_KEY_CHECKS = 0` to insert both tables, then re-enables checks. The data is consistent — every branch.manager_id points to a valid GMGR employee.

### How to run
```bash
cd part2
docker compose up -d                                      # start MySQL
python mysql/init/DataGeneration/proj2-fillSchema.py      # seed data
python mysql/init/DataGeneration/proj2-fillSchema.py --force   # reseed
python mysql/init/DataGeneration/proj2-fillSchema.py --print-sql  # preview SQL
```

### Extra: example queries
6 SQL files in `part2/example-queries/` preview Part 3 work: row counts, branch sales, recent orders, recipes, customer rewards, inventory alerts.

---

## Part 3 preview (individual — Week 15)

Will need:
- SELECT queries with JOINs, GROUP BY, subqueries
- Stored procedures — good candidates:
  - Place an order (insert order + order items, update inventory)
  - Redeem a reward (check one-time-use constraint, link to order)
  - Log an inspection result
  - Report branch sales totals

> **Open question:** Original spec says Oracle SQL + PL/SQL. If professor updates Part 3 guidelines like Part 2, we can stay on MySQL. Otherwise may need to port schema to Oracle. The 6 example queries in `part2/example-queries/` are a head start either way.
