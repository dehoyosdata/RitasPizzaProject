#!/usr/bin/env python3
"""
Generate and insert sample data for the Rita's Pizza MySQL database.

This follows the structure of the class seed_library_data.py example:
configuration constants, deterministic fake data, per-table seed builders,
an already-seeded check, and a main() entry point.

The script intentionally uses only the Python standard library. It sends the
generated SQL to the MySQL Docker container with `docker compose exec`, so no
extra Python database driver is required.
"""

from __future__ import annotations

import argparse
import logging
import os
import random
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import date, timedelta
from decimal import Decimal
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
PART2_DIR = SCRIPT_DIR.parents[2]

DEFAULT_DATABASE = "ritas_pizza"
DEFAULT_SEED = 42
DEFAULT_CUSTOMERS = 80
DEFAULT_ORDERS = 200

BRANCH_COUNT = 5
EMPLOYEES_PER_BRANCH = 6
INSPECTIONS_PER_BRANCH = 4
REWARD_COUNT = 60

MONEY = Decimal("0.01")


logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("seed_ritas_pizza")


@dataclass(frozen=True)
class MySQLConfig:
    compose_dir: Path
    service: str
    database: str
    user: str
    password: str


def read_env_file(path: Path) -> dict[str, str]:
    """Read a simple KEY=value env file without requiring python-dotenv."""
    values: dict[str, str] = {}
    if not path.exists():
        return values

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def project_env() -> dict[str, str]:
    """Merge project .env values with the current process environment."""
    file_env = read_env_file(PART2_DIR / ".env")
    merged = {**file_env, **os.environ}
    return merged


def decimal(value: str | int | float) -> Decimal:
    return Decimal(str(value)).quantize(MONEY)


def sql_identifier(name: str) -> str:
    return f"`{name.replace('`', '``')}`"


def sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, Decimal):
        return format(value, "f")
    if isinstance(value, float):
        return format(decimal(value), "f")
    if isinstance(value, date):
        return f"'{value.isoformat()}'"

    text = str(value).replace("\\", "\\\\").replace("'", "''")
    return f"'{text}'"


def insert_sql(table: str, rows: list[dict[str, Any]], batch_size: int = 100) -> str:
    if not rows:
        return ""

    columns = list(rows[0].keys())
    column_sql = ", ".join(sql_identifier(column) for column in columns)
    statements: list[str] = []

    for start in range(0, len(rows), batch_size):
        batch = rows[start : start + batch_size]
        values = []
        for row in batch:
            row_values = ", ".join(sql_literal(row[column]) for column in columns)
            values.append(f"    ({row_values})")

        statements.append(
            f"INSERT INTO {sql_identifier(table)} ({column_sql}) VALUES\n"
            + ",\n".join(values)
            + ";"
        )

    return "\n\n".join(statements)


def random_date(rng: random.Random, start: date, end: date) -> date:
    days = max((end - start).days, 1)
    return start + timedelta(days=rng.randint(0, days))


def build_branches_and_employees(rng: random.Random) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    branch_templates = [
        ("101 Tomato Ave", "San Marcos", "512-555-0101", "10:00-22:00", 42),
        ("2208 River Rd", "New Braunfels", "830-555-0102", "10:00-23:00", 55),
        ("415 University Dr", "Austin", "512-555-0103", "11:00-23:00", 64),
        ("88 Cypress Bend", "Kyle", "512-555-0104", "10:30-22:00", 38),
        ("730 Ranch Market 12", "Wimberley", "512-555-0105", "11:00-21:30", 30),
    ]
    first_names = [
        "Alex", "Bailey", "Casey", "Devon", "Elena", "Francisco", "Grace",
        "Harper", "Isaac", "Jasmine", "Kai", "Lena", "Mateo", "Nora",
        "Owen", "Priya", "Quinn", "Riley", "Sofia", "Theo",
    ]
    last_names = [
        "Bennett", "Carter", "Diaz", "Flores", "Garcia", "Hill", "Kim",
        "Lopez", "Morris", "Nguyen", "Patel", "Rivera", "Smith", "Taylor",
    ]

    branches: list[dict[str, Any]] = []
    employees: list[dict[str, Any]] = []
    employee_id = 1

    for branch_id, template in enumerate(branch_templates, start=1):
        street_addr, city, phone_no, opening_hrs, seating_cap = template
        manager_id = employee_id
        branches.append(
            {
                "branch_id": branch_id,
                "street_addr": street_addr,
                "city": city,
                "phone_no": phone_no,
                "opening_hrs": opening_hrs,
                "seating_cap": seating_cap,
                "manager_id": manager_id,
            }
        )

        roles = [
            ("GMGR", Decimal("31.50")),
            ("Shift Manager", Decimal("23.00")),
            ("Cook/Kitchen", Decimal("17.75")),
            ("Cook/Kitchen", Decimal("18.25")),
            ("Cashier/Front", Decimal("15.50")),
            ("Cashier/Front", Decimal("16.00")),
        ]
        for role, base_wage in roles:
            first = rng.choice(first_names)
            last = rng.choice(last_names)
            employees.append(
                {
                    "employee_id": employee_id,
                    "name": f"{first} {last}",
                    "type": role,
                    "hire_date": random_date(rng, date(2020, 1, 1), date(2026, 3, 1)),
                    "wage": base_wage + Decimal(rng.choice(["0.00", "0.25", "0.50", "0.75"])),
                    "branch_id": branch_id,
                }
            )
            employee_id += 1

    return branches, employees


def build_customers(rng: random.Random, count: int) -> list[dict[str, Any]]:
    first_names = [
        "Avery", "Blake", "Camila", "Dylan", "Emery", "Finn", "Gianna",
        "Hudson", "Isla", "Jonah", "Keira", "Leo", "Maya", "Nolan",
        "Olivia", "Parker", "Reese", "Sam", "Tessa", "Wyatt",
    ]
    last_names = [
        "Adams", "Brooks", "Cooper", "Edwards", "Foster", "Gomez",
        "Hayes", "James", "Kelly", "Long", "Mitchell", "Ortiz",
        "Perry", "Reed", "Sanchez", "Turner",
    ]

    customers: list[dict[str, Any]] = []
    for customer_id in range(1, count + 1):
        first = rng.choice(first_names)
        last = rng.choice(last_names)
        joined = random_date(rng, date(2022, 1, 1), date(2026, 3, 31))
        customers.append(
            {
                "customer_id": customer_id,
                "name": f"{first} {last}",
                "email": f"{first.lower()}.{last.lower()}{customer_id}@ritaspizza.test",
                "phone": f"512-555-{2000 + customer_id:04d}",
                "rewards_pts": 0,
                "date_joined": joined,
            }
        )
    return customers


def build_menu_items() -> list[dict[str, Any]]:
    rows = [
        (1, "Classic Cheese Pizza", "10.99", "Pizza"),
        (2, "Pepperoni Pizza", "12.99", "Pizza"),
        (3, "Supreme Pizza", "15.49", "Pizza"),
        (4, "Garden Veggie Pizza", "13.99", "Pizza"),
        (5, "Hawaiian Pizza", "14.49", "Pizza"),
        (6, "BBQ Chicken Pizza", "15.99", "Pizza"),
        (7, "Meat Lovers Pizza", "16.49", "Pizza"),
        (8, "White Garlic Pizza", "14.99", "Pizza"),
        (9, "Jalapeno Popper Pizza", "15.49", "Pizza"),
        (10, "Personal Cheese Pizza", "7.99", "Pizza"),
        (11, "Garlic Breadsticks", "5.49", "Side"),
        (12, "Caesar Salad", "6.99", "Side"),
        (13, "BBQ Wings", "8.99", "Side"),
        (14, "Marinara Cup", "0.75", "Side"),
        (15, "Chocolate Chip Cookie", "2.49", "Dessert"),
        (16, "Brownie", "2.99", "Dessert"),
        (17, "Fountain Cola", "2.25", "Drink"),
        (18, "Iced Tea", "2.25", "Drink"),
    ]
    return [
        {"item_id": item_id, "name": name, "price": decimal(price), "category": category}
        for item_id, name, price, category in rows
    ]


def build_ingredients() -> list[dict[str, Any]]:
    rows = [
        (1, "Pizza Dough", "ball", "0.95"),
        (2, "Tomato Sauce", "cup", "0.42"),
        (3, "Mozzarella Cheese", "oz", "0.18"),
        (4, "Pepperoni", "oz", "0.31"),
        (5, "Italian Sausage", "oz", "0.36"),
        (6, "Mushrooms", "oz", "0.22"),
        (7, "Green Peppers", "oz", "0.19"),
        (8, "Red Onion", "oz", "0.16"),
        (9, "Black Olives", "oz", "0.24"),
        (10, "Pineapple", "oz", "0.20"),
        (11, "Ham", "oz", "0.34"),
        (12, "Bacon", "oz", "0.39"),
        (13, "Chicken", "oz", "0.41"),
        (14, "BBQ Sauce", "cup", "0.48"),
        (15, "Alfredo Sauce", "cup", "0.55"),
        (16, "Parmesan", "oz", "0.28"),
        (17, "Garlic Butter", "oz", "0.21"),
        (18, "Romaine Lettuce", "oz", "0.15"),
        (19, "Croutons", "oz", "0.12"),
        (20, "Caesar Dressing", "oz", "0.17"),
        (21, "Breadstick Dough", "piece", "0.38"),
        (22, "Marinara Cup", "cup", "0.25"),
        (23, "Chocolate Chip Cookie", "piece", "0.62"),
        (24, "Brownie", "piece", "0.76"),
        (25, "Cola Syrup", "oz", "0.08"),
        (26, "Lemon-Lime Syrup", "oz", "0.08"),
        (27, "Tea Concentrate", "oz", "0.07"),
        (28, "Cup", "piece", "0.05"),
        (29, "Ice", "lb", "0.03"),
        (30, "Jalapenos", "oz", "0.18"),
    ]
    return [
        {
            "ingredient_id": ingredient_id,
            "name": name,
            "unit": unit,
            "cost_per_unit": decimal(cost),
        }
        for ingredient_id, name, unit, cost in rows
    ]


def build_recipes() -> list[dict[str, Any]]:
    recipe_map = {
        1: [(1, "1.00"), (2, "0.50"), (3, "6.00"), (16, "0.50")],
        2: [(1, "1.00"), (2, "0.50"), (3, "6.00"), (4, "3.00")],
        3: [(1, "1.00"), (2, "0.55"), (3, "6.50"), (4, "2.00"), (5, "2.00"), (6, "1.50"), (7, "1.50"), (8, "1.00"), (9, "1.00")],
        4: [(1, "1.00"), (2, "0.50"), (3, "5.50"), (6, "2.00"), (7, "2.00"), (8, "1.50"), (9, "1.00")],
        5: [(1, "1.00"), (2, "0.50"), (3, "6.00"), (10, "2.00"), (11, "2.50")],
        6: [(1, "1.00"), (3, "6.00"), (13, "3.00"), (14, "0.60"), (8, "1.00")],
        7: [(1, "1.00"), (2, "0.55"), (3, "6.50"), (4, "2.50"), (5, "2.50"), (11, "2.00"), (12, "1.50")],
        8: [(1, "1.00"), (3, "6.00"), (15, "0.55"), (16, "0.75"), (17, "0.50")],
        9: [(1, "1.00"), (2, "0.50"), (3, "6.00"), (12, "2.00"), (16, "0.50"), (30, "1.50")],
        10: [(1, "0.55"), (2, "0.30"), (3, "3.50")],
        11: [(21, "6.00"), (17, "1.00"), (16, "0.50")],
        12: [(18, "6.00"), (19, "1.50"), (20, "2.00"), (16, "0.50")],
        13: [(13, "6.00"), (14, "0.75")],
        14: [(22, "1.00")],
        15: [(23, "1.00")],
        16: [(24, "1.00")],
        17: [(25, "2.00"), (28, "1.00"), (29, "0.30")],
        18: [(27, "2.00"), (28, "1.00"), (29, "0.30")],
    }

    recipes: list[dict[str, Any]] = []
    for item_id, ingredients in recipe_map.items():
        for ingredient_id, amount in ingredients:
            recipes.append(
                {
                    "item_id": item_id,
                    "ingredient_id": ingredient_id,
                    "amt_required": decimal(amount),
                }
            )
    return recipes


def build_rewards(rng: random.Random, customers: list[dict[str, Any]]) -> list[dict[str, Any]]:
    reward_templates = [
        ("$5 off next order", "Discount"),
        ("Free dessert with pizza", "Free Item"),
        ("10 percent off online order", "Discount"),
        ("Free side with large pizza", "Free Item"),
        ("Birthday reward", "Special"),
    ]
    rewards: list[dict[str, Any]] = []
    for reward_id in range(1, REWARD_COUNT + 1):
        description, reward_type = rng.choice(reward_templates)
        customer = rng.choice(customers)
        rewards.append(
            {
                "reward_id": reward_id,
                "description": description,
                "reward_type": reward_type,
                "issue_date": random_date(rng, date(2025, 1, 1), date(2026, 4, 1)),
                "used_status": "N",
                "customer_id": customer["customer_id"],
            }
        )
    return rewards


def build_orders(
    rng: random.Random,
    customers: list[dict[str, Any]],
    menu_items: list[dict[str, Any]],
    rewards: list[dict[str, Any]],
    order_count: int,
    end_date: date,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    menu_by_id = {item["item_id"]: item for item in menu_items}
    rewards_by_customer: dict[int, list[dict[str, Any]]] = {}
    for reward in rewards:
        rewards_by_customer.setdefault(reward["customer_id"], []).append(reward)

    points_by_customer = {customer["customer_id"]: 0 for customer in customers}
    orders: list[dict[str, Any]] = []
    order_items: list[dict[str, Any]] = []

    start_date = end_date - timedelta(days=180)

    for order_id in range(1, order_count + 1):
        registered_order = rng.random() < 0.72
        customer_id = rng.choice(customers)["customer_id"] if registered_order else None
        branch_id = rng.randint(1, BRANCH_COUNT)
        order_type = rng.choice(["online", "in-person"]) if registered_order else "in-person"
        order_date = random_date(rng, start_date, end_date)

        item_count = rng.randint(1, 4)
        selected_items = rng.sample(menu_items, item_count)
        subtotal = Decimal("0.00")
        for item in selected_items:
            quantity = rng.randint(1, 3)
            item_price = menu_by_id[item["item_id"]]["price"]
            subtotal += item_price * quantity
            order_items.append(
                {
                    "order_id": order_id,
                    "item_id": item["item_id"],
                    "quantity": quantity,
                    "item_price": item_price,
                }
            )

        reward_id = None
        total = subtotal
        if customer_id is not None and rng.random() < 0.20:
            available_rewards = rewards_by_customer.get(customer_id, [])
            if available_rewards:
                reward = available_rewards.pop()
                reward["used_status"] = "Y"
                reward_id = reward["reward_id"]
                total = max(Decimal("0.00"), subtotal - Decimal("5.00"))

        total = total.quantize(MONEY)
        if customer_id is not None:
            points_by_customer[customer_id] += int(total)

        orders.append(
            {
                "order_id": order_id,
                "order_date": order_date,
                "order_type": order_type,
                "total_price": total,
                "customer_id": customer_id,
                "branch_id": branch_id,
                "reward_id": reward_id,
            }
        )

    for customer in customers:
        customer["rewards_pts"] = points_by_customer[customer["customer_id"]]

    return orders, order_items


def build_inspections(rng: random.Random, end_date: date) -> list[dict[str, Any]]:
    results = [
        ("Pass", "Routine inspection completed with no critical issues."),
        ("Conditional Pass", "Minor corrective actions documented."),
        ("Needs Reinspection", "Follow-up visit scheduled after corrective actions."),
    ]
    inspections: list[dict[str, Any]] = []
    inspection_id = 1

    for branch_id in range(1, BRANCH_COUNT + 1):
        for offset in range(INSPECTIONS_PER_BRANCH):
            result, notes = rng.choices(results, weights=[0.72, 0.22, 0.06], k=1)[0]
            insp_date = end_date - timedelta(days=(offset * 75) + rng.randint(0, 20))
            inspections.append(
                {
                    "inspection_id": inspection_id,
                    "insp_date": insp_date,
                    "result": result,
                    "notes": notes,
                    "branch_id": branch_id,
                }
            )
            inspection_id += 1

    return inspections


def build_inventory(
    rng: random.Random,
    ingredients: list[dict[str, Any]],
    end_date: date,
) -> list[dict[str, Any]]:
    inventory: list[dict[str, Any]] = []
    for branch_id in range(1, BRANCH_COUNT + 1):
        for ingredient in ingredients:
            unit = ingredient["unit"]
            if unit in {"piece", "ball"}:
                quantity = Decimal(rng.randint(30, 260))
            elif unit == "lb":
                quantity = decimal(rng.uniform(20, 100))
            elif unit == "cup":
                quantity = decimal(rng.uniform(40, 420))
            else:
                quantity = decimal(rng.uniform(80, 1800))

            inventory.append(
                {
                    "branch_id": branch_id,
                    "ingredient_id": ingredient["ingredient_id"],
                    "qty_on_hand": quantity,
                    "last_updated": random_date(rng, end_date - timedelta(days=14), end_date),
                }
            )
    return inventory


def build_dataset(seed: int, customers_count: int, order_count: int, end_date: date) -> dict[str, list[dict[str, Any]]]:
    rng = random.Random(seed)

    branches, employees = build_branches_and_employees(rng)
    customers = build_customers(rng, customers_count)
    menu_items = build_menu_items()
    ingredients = build_ingredients()
    rewards = build_rewards(rng, customers)
    orders, order_items = build_orders(rng, customers, menu_items, rewards, order_count, end_date)
    inspections = build_inspections(rng, end_date)
    recipes = build_recipes()
    inventory = build_inventory(rng, ingredients, end_date)

    return {
        "BRANCH": branches,
        "EMPLOYEE": employees,
        "CUSTOMER": customers,
        "MENU_ITEM": menu_items,
        "INGREDIENT": ingredients,
        "REWARD": rewards,
        "PIZZA_ORDER": orders,
        "INSPECTION": inspections,
        "ORDER_ITEM": order_items,
        "RECIPE": recipes,
        "INVENTORY": inventory,
    }


def clear_sql() -> str:
    tables = [
        "ORDER_ITEM",
        "RECIPE",
        "INVENTORY",
        "INSPECTION",
        "PIZZA_ORDER",
        "REWARD",
        "EMPLOYEE",
        "BRANCH",
        "INGREDIENT",
        "MENU_ITEM",
        "CUSTOMER",
    ]
    lines = [
        "-- Clear tables so --force can rebuild the seed data.",
        "SET FOREIGN_KEY_CHECKS = 0;",
    ]
    for table in tables:
        lines.append(f"DELETE FROM {sql_identifier(table)};")
    for table in reversed(tables):
        lines.append(f"ALTER TABLE {sql_identifier(table)} AUTO_INCREMENT = 1;")
    lines.append("SET FOREIGN_KEY_CHECKS = 1;")
    return "\n".join(lines)


def render_seed_sql(dataset: dict[str, list[dict[str, Any]]], database: str, force: bool) -> str:
    lines = [
        "-- Rita's Pizza Project - generated seed data",
        "-- Generated by part2/mysql/init/DataGeneration/proj2-fillSchema.py",
        f"USE {sql_identifier(database)};",
        "",
    ]

    if force:
        lines.extend([clear_sql(), ""])

    # BRANCH and EMPLOYEE have a circular relationship, so insert both while
    # foreign-key checks are off. The generated data still satisfies both FKs.
    lines.append("SET FOREIGN_KEY_CHECKS = 0;")
    lines.append(insert_sql("BRANCH", dataset["BRANCH"]))
    lines.append(insert_sql("EMPLOYEE", dataset["EMPLOYEE"]))
    lines.append("SET FOREIGN_KEY_CHECKS = 1;")
    lines.append("")

    for table in [
        "CUSTOMER",
        "MENU_ITEM",
        "INGREDIENT",
        "REWARD",
        "PIZZA_ORDER",
        "INSPECTION",
        "ORDER_ITEM",
        "RECIPE",
        "INVENTORY",
    ]:
        lines.append(insert_sql(table, dataset[table]))
        lines.append("")

    return "\n".join(line for line in lines if line is not None).strip() + "\n"


def mysql_base_command(config: MySQLConfig) -> list[str]:
    return [
        "docker",
        "compose",
        "exec",
        "-T",
        config.service,
        "mysql",
        f"--user={config.user}",
        f"--password={config.password}",
    ]


def run_mysql_query(config: MySQLConfig, query: str) -> str:
    command = mysql_base_command(config) + [
        "--batch",
        "--skip-column-names",
        config.database,
        f"--execute={query}",
    ]
    result = subprocess.run(
        command,
        cwd=config.compose_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return result.stdout.strip()


def run_mysql_script(config: MySQLConfig, sql: str) -> None:
    command = mysql_base_command(config) + [config.database]
    result = subprocess.run(
        command,
        cwd=config.compose_dir,
        input=sql,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    if result.stderr.strip():
        logger.debug(result.stderr.strip())


def wait_for_db(config: MySQLConfig, attempts: int = 18, delay_seconds: int = 2) -> None:
    for attempt in range(1, attempts + 1):
        try:
            run_mysql_query(config, "SELECT 1;")
            logger.info("Database connected on attempt %d", attempt)
            return
        except RuntimeError as exc:
            logger.info("Waiting for database (%d/%d): %s", attempt, attempts, exc)
            time.sleep(delay_seconds)

    raise RuntimeError("Database was not reachable. Start it with `docker compose up -d` from part2.")


def already_seeded(config: MySQLConfig) -> bool:
    count_text = run_mysql_query(
        config,
        """
        SELECT
            (SELECT COUNT(*) FROM BRANCH)
          + (SELECT COUNT(*) FROM CUSTOMER)
          + (SELECT COUNT(*) FROM PIZZA_ORDER)
          + (SELECT COUNT(*) FROM ORDER_ITEM);
        """,
    )
    return int(count_text or "0") > 0


def parse_end_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("Use YYYY-MM-DD format.") from exc


def parse_args() -> argparse.Namespace:
    env = project_env()
    parser = argparse.ArgumentParser(
        description="Generate and insert sample data for the Rita's Pizza MySQL schema."
    )
    parser.add_argument("--force", action="store_true", help="Delete existing seed data before inserting fresh rows.")
    parser.add_argument("--print-sql", action="store_true", help="Print generated SQL instead of applying it.")
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED, help="Random seed for deterministic data.")
    parser.add_argument("--customers", type=int, default=DEFAULT_CUSTOMERS, help="Number of customers to generate.")
    parser.add_argument("--orders", type=int, default=DEFAULT_ORDERS, help="Number of orders to generate.")
    parser.add_argument("--end-date", type=parse_end_date, default=date.today(), help="Latest date used for generated activity.")
    parser.add_argument("--database", default=env.get("MYSQL_DATABASE", DEFAULT_DATABASE), help="MySQL database name.")
    parser.add_argument("--compose-service", default="mysql", help="Docker Compose service name for MySQL.")
    parser.add_argument("--compose-dir", type=Path, default=PART2_DIR, help="Folder containing docker-compose.yml.")
    parser.add_argument("--mysql-user", default=env.get("MYSQL_SCRIPT_USER", "root"), help="MySQL user for seeding.")
    parser.add_argument(
        "--mysql-password",
        default=env.get("MYSQL_SCRIPT_PASSWORD", env.get("MYSQL_ROOT_PASSWORD", "rootpassword")),
        help="MySQL password for the seed user.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.customers < 5:
        raise SystemExit("--customers must be at least 5.")
    if args.orders < 5:
        raise SystemExit("--orders must be at least 5.")

    dataset = build_dataset(
        seed=args.seed,
        customers_count=args.customers,
        order_count=args.orders,
        end_date=args.end_date,
    )
    sql = render_seed_sql(dataset, database=args.database, force=args.force)

    if args.print_sql:
        sys.stdout.write(sql)
        return 0

    config = MySQLConfig(
        compose_dir=args.compose_dir.resolve(),
        service=args.compose_service,
        database=args.database,
        user=args.mysql_user,
        password=args.mysql_password,
    )

    wait_for_db(config)
    if not args.force and already_seeded(config):
        logger.info("Seed data already exists. Use --force to clear and reseed.")
        return 0

    logger.info(
        "Seeding %d branches, %d employees, %d customers, %d menu items, %d ingredients, %d rewards, %d orders.",
        len(dataset["BRANCH"]),
        len(dataset["EMPLOYEE"]),
        len(dataset["CUSTOMER"]),
        len(dataset["MENU_ITEM"]),
        len(dataset["INGREDIENT"]),
        len(dataset["REWARD"]),
        len(dataset["PIZZA_ORDER"]),
    )
    run_mysql_script(config, sql)
    logger.info(
        "Seed complete: %d order items, %d recipes, %d inventory rows, %d inspections.",
        len(dataset["ORDER_ITEM"]),
        len(dataset["RECIPE"]),
        len(dataset["INVENTORY"]),
        len(dataset["INSPECTION"]),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
