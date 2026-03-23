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
