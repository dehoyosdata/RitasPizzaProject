# Part 1 — Status Update

## What's in the document now (done)
- **Requirements Gathering** — overview, domain research, functional requirements
- **Business Rules** — BR1–BR15, organized by category
- **Relationship Reasoning** — kept from original doc (teammate's section)
- **Design Decisions** — 6 documented choices + assumptions list
- **Relational Schema Diagram** — generated from dbdiagram.io with all 11 tables and FK arrows
- **Relational Schema Tables** — full column types, PK/FK, and constraints for every table
- **Constraints Not Expressible** — stuff that needs triggers, not just table constraints (the assignment specifically asks for this)

## What still needs to be done

### 1. Chen ER Diagram (big item — ~30-45 min)
Someone needs to redraw it in **draw.io** (app.diagrams.net) using Chen notation.

**Nomenclature:** ✓ Verified consistent between `part1/er-diagram.mmd` and `part1/chen-diagram-reference.txt`. Use these as reference for drawing in Chen notation (rectangles for entities, ovals for attributes, diamonds for relationships).

**Can someone pick this up?**

### ~~2. Two small text edits in the relationship reasoning section~~ ✅ DONE
- ~~The italic note about walk-in orders on **Places**~~ — made definitive ("partial participation to support walk-ins")
- ~~The italic note about maybe adding `redeem_date` to **Redeems**~~ — decided NO

### ~~3. Remove "Diagram TODO:" label~~ ✅ DONE

### 4. Final packaging
Once the Chen diagram is done: export as PDF → zip as `proj1.zip` → submit.

---

## Decisions that need your approval

| What changed | Why |
|---|---|
| `location` → split into `street_addr` + `city` | Better for queries — can filter/group by city |
| Dropped `reputation` from Branch | Subjective, not captured by transactions |
| Merged `role` + `employee_type` into single `type` | They were the same thing, redundant |
| Added `wage` to Employee | From original proposal, operationally useful |
| `total_amount` → `total_price` | Consistent with MenuItem's `price` field |
| Dropped `certification_status` from Employee | Not referenced in any business rule |
| Dropped `expiration_date` from Ingredient | Belongs on inventory/batch level, not ingredient definition |
| Added `cost_per_unit` to Ingredient | Useful for inventory valuation |
| Added `reward_type`, `issue_date`, `used_status` to Reward | Supports the one-time redemption rule (BR12) |
| Added `notes` to Inspection | Free-text details alongside structured `result` |
| Named Order table `PIZZA_ORDER` | `ORDER` is a reserved word in Oracle — will save us pain in Part 2 |

**If anyone disagrees, let me know before we finalize. Otherwise I'll treat them as approved.**

---

# Part 2 — Status Update

## Professor's updated guidelines (2026-04-15)

The old Part 2 spec (Oracle, combined files) has been replaced. New rules:
- **Any database** — we chose MySQL 8.4 via Docker
- **Two separate files:** `proj2-makeSchema.sql` (schema only) + `proj2-fillSchema.py` (data)
- Python seed script is the professor's recommended approach

## What's done

### Stephen's work (`origin/part2` branch)
- `proj2-makeSchema.sql` — all 11 tables, MySQL syntax, named constraints, circular FK handled
- `proj2-fillSchema.py` — 739-line stdlib-only seed script (80 customers, 200 orders, all BRs enforced)
- Docker Compose setup + `DOCKER.md` with instructions
- 6 example queries (row counts, branch sales, recent orders, recipes, rewards, inventory)

### Davos's additions (on top of Stephen's branch)
- **Enhanced schema comments** — every table and constraint now references which business rule (BR1-BR15) it enforces
- **`proj2-fillSchema.sql`** — static SQL version (Option A) generated from `--print-sql` for submission without Python
- **`proj2-verify.sql`** — verification script that proves all 15 business rules hold in the seeded data. Every violation check returns 0 rows.
- **3 advanced queries** for Part 3 head start:
  - `07-top-customers-by-branch.sql` — RANK() window function
  - `08-ingredient-usage-vs-stock.sql` — correlated subquery, usage vs stock comparison
  - `09-monthly-sales-trends.sql` — CTEs, LAG(), running totals, month-over-month growth
- Updated `CLAUDE_CONTEXT.md` and READMEs

### Tested end-to-end
- Schema creation, seed (both Python and static SQL), BR verification, all 9 queries — all passing against MySQL 8.4 in Docker.

## What's left for Part 2

Nothing — ready to submit. Files to turn in:
- `part2/mysql/init/proj2-makeSchema.sql`
- `part2/mysql/init/DataGeneration/proj2-fillSchema.py` (or `part2/proj2-fillSchema.sql`)

## Open question for Part 3

The original spec says Part 3 uses **Oracle SQL + PL/SQL**. If the professor updates Part 3 like he did Part 2, we can stay on MySQL. Otherwise we may need to port. The 9 example queries are a head start either way.
