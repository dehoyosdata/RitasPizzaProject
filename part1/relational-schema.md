# Relational Schema

Primary keys are **bolded**. Foreign keys are marked with → referencing their parent table.

---

## BRANCH
| Column | Type | Constraints |
|---|---|---|
| **branch_id** | NUMBER | PK |
| street_addr | VARCHAR2(100) | NOT NULL |
| city | VARCHAR2(50) | NOT NULL |
| phone_no | VARCHAR2(20) | |
| opening_hrs | VARCHAR2(50) | |
| seating_cap | NUMBER | |
| manager_id | NUMBER | FK → EMPLOYEE(employee_id), UNIQUE, NOT NULL |

---

## EMPLOYEE
| Column | Type | Constraints |
|---|---|---|
| **employee_id** | NUMBER | PK |
| name | VARCHAR2(100) | NOT NULL |
| type | VARCHAR2(20) | NOT NULL, CHECK IN ('GMGR','Shift Manager','Cook/Kitchen','Cashier/Front') |
| hire_date | DATE | NOT NULL |
| wage | NUMBER(8,2) | |
| branch_id | NUMBER | FK → BRANCH(branch_id), NOT NULL |

---

## CUSTOMER
| Column | Type | Constraints |
|---|---|---|
| **customer_id** | NUMBER | PK |
| name | VARCHAR2(100) | NOT NULL |
| email | VARCHAR2(100) | |
| phone | VARCHAR2(20) | |
| rewards_pts | NUMBER | DEFAULT 0 |
| date_joined | DATE | |

---

## PIZZA_ORDER
| Column | Type | Constraints |
|---|---|---|
| **order_id** | NUMBER | PK |
| order_date | DATE | NOT NULL |
| order_type | VARCHAR2(20) | NOT NULL, CHECK IN ('online','in-person') |
| total_price | NUMBER(10,2) | |
| customer_id | NUMBER | FK → CUSTOMER(customer_id), NULLABLE |
| branch_id | NUMBER | FK → BRANCH(branch_id), NOT NULL |

> Table named PIZZA_ORDER instead of ORDER because ORDER is a reserved word in Oracle SQL.

---

## MENU_ITEM
| Column | Type | Constraints |
|---|---|---|
| **item_id** | NUMBER | PK |
| name | VARCHAR2(100) | NOT NULL |
| price | NUMBER(8,2) | NOT NULL |
| category | VARCHAR2(50) | |

---

## INGREDIENT
| Column | Type | Constraints |
|---|---|---|
| **ingredient_id** | NUMBER | PK |
| name | VARCHAR2(100) | NOT NULL |
| unit | VARCHAR2(20) | NOT NULL |
| cost_per_unit | NUMBER(8,2) | |

---

## REWARD
| Column | Type | Constraints |
|---|---|---|
| **reward_id** | NUMBER | PK |
| description | VARCHAR2(200) | |
| reward_type | VARCHAR2(50) | |
| issue_date | DATE | |
| used_status | VARCHAR2(1) | DEFAULT 'N', CHECK IN ('Y','N') |
| customer_id | NUMBER | FK → CUSTOMER(customer_id), NOT NULL |

---

## INSPECTION
| Column | Type | Constraints |
|---|---|---|
| **inspection_id** | NUMBER | PK |
| insp_date | DATE | NOT NULL |
| result | VARCHAR2(50) | NOT NULL |
| notes | VARCHAR2(500) | |
| branch_id | NUMBER | FK → BRANCH(branch_id), NOT NULL |

---

## ORDER_ITEM (associative — resolves Contains M:N)
| Column | Type | Constraints |
|---|---|---|
| **order_id** | NUMBER | PK, FK → PIZZA_ORDER(order_id) |
| **item_id** | NUMBER | PK, FK → MENU_ITEM(item_id) |
| quantity | NUMBER | NOT NULL |
| item_price | NUMBER(8,2) | NOT NULL |

> Composite PK: (order_id, item_id)

---

## RECIPE (associative — resolves Uses M:N)
| Column | Type | Constraints |
|---|---|---|
| **item_id** | NUMBER | PK, FK → MENU_ITEM(item_id) |
| **ingredient_id** | NUMBER | PK, FK → INGREDIENT(ingredient_id) |
| amt_required | NUMBER(8,2) | NOT NULL |

> Composite PK: (item_id, ingredient_id)

---

## INVENTORY (associative — resolves Stocks M:N)
| Column | Type | Constraints |
|---|---|---|
| **branch_id** | NUMBER | PK, FK → BRANCH(branch_id) |
| **ingredient_id** | NUMBER | PK, FK → INGREDIENT(ingredient_id) |
| qty_on_hand | NUMBER | NOT NULL |
| last_updated | DATE | |

> Composite PK: (branch_id, ingredient_id)

---

## Relationship: Redeems (Reward ↔ Order)

The Redeems relationship (0..1 : 0..1) is implemented via a foreign key on PIZZA_ORDER:

| Column | Type | Constraints |
|---|---|---|
| reward_id | NUMBER | FK → REWARD(reward_id), NULLABLE, UNIQUE |

> Added to the PIZZA_ORDER table. UNIQUE ensures a reward is redeemed at most once. NULLABLE allows orders without a reward.

---

## Constraints Not Expressible in Relational Schema

The following business rules cannot be fully enforced through table constraints alone and would require triggers or application logic:

1. **BR1** — "Each branch must have exactly one GMGR at all times." The UNIQUE FK `manager_id` on BRANCH ensures at most one, but enforcing that the referenced employee has `type = 'GMGR'` requires a trigger or CHECK constraint with a subquery (not supported in Oracle CHECK).
2. **BR6** — "Only a GMGR may manage a branch." Same issue — cross-table validation needed.
3. **BR9** — "An order must contain at least one menu item." Minimum participation in ORDER_ITEM cannot be enforced declaratively; requires a trigger or application-level check.
4. **BR13** — "Only registered customers can redeem rewards." Ensuring that if `reward_id` is set on PIZZA_ORDER then `customer_id` is also NOT NULL requires a trigger or compound CHECK.
5. **Circular FK between BRANCH and EMPLOYEE** — BRANCH references EMPLOYEE (manager_id) and EMPLOYEE references BRANCH (branch_id). This creates a chicken-and-egg insertion problem that must be handled with deferred constraints or by inserting with NULLs first and updating afterward.
