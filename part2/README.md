# Part 2 — Schema Creation & Data Population

## Submission Files

| File | Location | Purpose |
|---|---|---|
| `proj2-makeSchema.sql` | `mysql/init/proj2-makeSchema.sql` | Creates database and all 11 tables (empty) |
| `proj2-fillSchema.py` | `mysql/init/DataGeneration/proj2-fillSchema.py` | Generates and inserts sample data |

## Quick Start

### 1. Start MySQL

```bash
cd part2
docker compose up -d
```

Default connection: `127.0.0.1:3308`, database `ritas_pizza`, user `ritas_user` / `ritas_password`. To customize, copy `.env.example` to `.env` and edit.

The schema (`proj2-makeSchema.sql`) runs automatically on first container start via the Docker init volume.

### 2. Seed Data

```bash
python mysql/init/DataGeneration/proj2-fillSchema.py
```

Options:
- `--force` — clear existing data and reseed
- `--print-sql` — print generated SQL to stdout instead of inserting
- `--customers N` — number of customers (default 80)
- `--orders N` — number of orders (default 200)
- `--seed N` — random seed for reproducibility (default 42)

No external Python dependencies required (stdlib only).

### 3. Run Example Queries

```bash
# Single query
cat example-queries/01-database-overview.sql | docker compose exec -T mysql mysql -uroot -prootpassword ritas_pizza

# All queries
for f in example-queries/*.sql; do echo "--- $f ---"; cat "$f" | docker compose exec -T mysql mysql -uroot -prootpassword ritas_pizza; done
```

### 4. Reset Everything

```bash
docker compose down -v    # removes volume
docker compose up -d      # recreates from scratch
```

## Tables

11 tables, matching the Part 1 relational schema:

| Table | Type | Key Relationships |
|---|---|---|
| BRANCH | Entity | manager_id FK -> EMPLOYEE (circular) |
| EMPLOYEE | Entity | branch_id FK -> BRANCH |
| CUSTOMER | Entity | |
| MENU_ITEM | Entity | |
| INGREDIENT | Entity | |
| REWARD | Entity | customer_id FK -> CUSTOMER |
| PIZZA_ORDER | Entity | customer_id FK -> CUSTOMER, branch_id FK -> BRANCH, reward_id FK -> REWARD |
| INSPECTION | Entity | branch_id FK -> BRANCH |
| ORDER_ITEM | Associative (M:N) | order_id + item_id composite PK |
| RECIPE | Associative (M:N) | item_id + ingredient_id composite PK |
| INVENTORY | Associative (M:N) | branch_id + ingredient_id composite PK |

See `DOCKER.md` for detailed Docker setup instructions.
