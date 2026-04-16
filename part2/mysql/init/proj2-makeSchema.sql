-- ============================================================
-- Rita's Pizza Project - Part 2 Schema
-- ============================================================
-- MySQL 8.4 implementation of the relational schema designed
-- in Part 1 (see part1/relational-schema.md for full spec).
--
-- Creates all 11 tables (empty). Data is loaded separately
-- by proj2-fillSchema.py (Option B) or proj2-fillSchema.sql
-- (Option A).
--
-- Business rules BR1-BR15 are referenced in comments below.
-- Rules that cannot be enforced declaratively (BR1/BR6 cross-
-- table type check, BR9 minimum one item per order, BR13
-- reward-requires-customer compound check) are noted but
-- require triggers or application logic.
-- ============================================================

CREATE DATABASE IF NOT EXISTS ritas_pizza;
USE ritas_pizza;

-- Rebuild safely during development.
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS ORDER_ITEM;
DROP TABLE IF EXISTS RECIPE;
DROP TABLE IF EXISTS INVENTORY;
DROP TABLE IF EXISTS INSPECTION;
DROP TABLE IF EXISTS PIZZA_ORDER;
DROP TABLE IF EXISTS REWARD;
DROP TABLE IF EXISTS EMPLOYEE;
DROP TABLE IF EXISTS BRANCH;
DROP TABLE IF EXISTS INGREDIENT;
DROP TABLE IF EXISTS MENU_ITEM;
DROP TABLE IF EXISTS CUSTOMER;

SET FOREIGN_KEY_CHECKS = 1;

-- BRANCH: each Rita's Pizza franchise location.
-- BR1: each branch has exactly one GMGR — enforced partially by UNIQUE
--      on manager_id (at most one manager). The type='GMGR' check needs
--      a trigger (cross-table validation).
-- BR2/BR3: employees reference BRANCH via FK, enforcing assignment.
-- Circular FK note: manager_id FK is added via ALTER TABLE after EMPLOYEE
-- exists, because BRANCH and EMPLOYEE reference each other.
CREATE TABLE BRANCH (
    branch_id INT NOT NULL AUTO_INCREMENT,
    street_addr VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    phone_no VARCHAR(20),
    opening_hrs VARCHAR(50),
    seating_cap INT,
    manager_id INT NOT NULL,                -- FK added below after EMPLOYEE
    CONSTRAINT pk_branch PRIMARY KEY (branch_id),
    CONSTRAINT uq_branch_manager UNIQUE (manager_id),       -- BR1: at most one manager
    CONSTRAINT chk_branch_seating_cap CHECK (seating_cap IS NULL OR seating_cap >= 0)
) ENGINE=InnoDB;

-- EMPLOYEE: staff assigned to a branch.
-- BR2: each employee assigned to at most one branch (single branch_id FK).
-- BR3: every employee must belong to a branch (branch_id NOT NULL).
-- BR5: employee type restricted to four roles via CHECK.
-- BR6: only GMGR may manage — enforced in BRANCH.manager_id; the cross-
--      table type='GMGR' check requires a trigger.
CREATE TABLE EMPLOYEE (
    employee_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    hire_date DATE NOT NULL,
    wage DECIMAL(8, 2),
    branch_id INT NOT NULL,                 -- BR3: total participation
    CONSTRAINT pk_employee PRIMARY KEY (employee_id),
    CONSTRAINT fk_employee_branch
        FOREIGN KEY (branch_id)             -- BR2: each employee -> one branch
        REFERENCES BRANCH (branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_employee_type            -- BR5: restricted role set
        CHECK (`type` IN ('GMGR', 'Shift Manager', 'Cook/Kitchen', 'Cashier/Front')),
    CONSTRAINT chk_employee_wage CHECK (wage IS NULL OR wage >= 0)
) ENGINE=InnoDB;

-- Circular FK resolution: now that EMPLOYEE exists, link BRANCH.manager_id.
-- BR1/BR6: UNIQUE + FK ensures each branch has exactly one manager and
-- each manager manages exactly one branch. The type='GMGR' restriction
-- cannot be enforced here — requires a trigger or application logic.
ALTER TABLE BRANCH
    ADD CONSTRAINT fk_branch_manager
        FOREIGN KEY (manager_id)
        REFERENCES EMPLOYEE (employee_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

-- CUSTOMER: registered customers who can earn rewards.
-- BR7: walk-in orders leave customer_id NULL on PIZZA_ORDER (partial
--      participation); this table stores only registered customers.
-- BR11/BR13: rewards are linked to customers via REWARD.customer_id.
CREATE TABLE CUSTOMER (
    customer_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    rewards_pts INT DEFAULT 0,              -- running balance of loyalty points
    date_joined DATE,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email UNIQUE (email),
    CONSTRAINT chk_customer_rewards_pts CHECK (rewards_pts >= 0)
) ENGINE=InnoDB;

-- MENU_ITEM: franchise-wide menu (all branches share the same menu).
-- BR14: menu items link to ingredients via the RECIPE associative table.
CREATE TABLE MENU_ITEM (
    item_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(8, 2) NOT NULL,
    category VARCHAR(50),                   -- Pizza, Side, Dessert, Drink
    CONSTRAINT pk_menu_item PRIMARY KEY (item_id),
    CONSTRAINT chk_menu_item_price CHECK (price >= 0)
) ENGINE=InnoDB;

-- INGREDIENT: global ingredient definitions shared across branches.
-- BR14: linked to menu items via RECIPE (amount per pairing).
-- BR15: linked to branches via INVENTORY (quantity per branch).
CREATE TABLE INGREDIENT (
    ingredient_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL,              -- oz, lb, cup, piece, etc.
    cost_per_unit DECIMAL(8, 2),            -- for inventory valuation
    CONSTRAINT pk_ingredient PRIMARY KEY (ingredient_id),
    CONSTRAINT chk_ingredient_cost CHECK (cost_per_unit IS NULL OR cost_per_unit >= 0)
) ENGINE=InnoDB;

-- REWARD: loyalty rewards owned by registered customers.
-- BR11: each reward belongs to exactly one customer (customer_id NOT NULL).
-- BR12: a reward may be redeemed at most once — enforced by UNIQUE on
--       PIZZA_ORDER.reward_id. used_status tracks redemption state.
-- BR13: only registered customers can own rewards (customer_id FK NOT NULL).
CREATE TABLE REWARD (
    reward_id INT NOT NULL AUTO_INCREMENT,
    description VARCHAR(200),
    reward_type VARCHAR(50),                -- Discount, Free Item, Special
    issue_date DATE,
    used_status CHAR(1) DEFAULT 'N',        -- BR12: Y = redeemed, N = available
    customer_id INT NOT NULL,               -- BR11/BR13: must belong to a customer
    CONSTRAINT pk_reward PRIMARY KEY (reward_id),
    CONSTRAINT fk_reward_customer
        FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER (customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_reward_used_status CHECK (used_status IN ('Y', 'N'))
) ENGINE=InnoDB;

-- PIZZA_ORDER: named to avoid the reserved word ORDER.
-- BR7:  customer_id is nullable — walk-in orders have no registered customer.
-- BR8:  every order processed by exactly one branch (branch_id NOT NULL).
-- BR9:  must contain at least one item — NOT enforceable here; requires a
--       trigger or application logic (checked in proj2-verify.sql).
-- BR10: order type restricted to 'online' or 'in-person' via CHECK.
-- BR12: reward_id UNIQUE ensures a reward is redeemed on at most one order.
-- BR13: if reward_id is set, customer_id should be NOT NULL — cannot be
--       enforced with a simple CHECK; requires a trigger.
CREATE TABLE PIZZA_ORDER (
    order_id INT NOT NULL AUTO_INCREMENT,
    order_date DATE NOT NULL,
    order_type VARCHAR(20) NOT NULL,
    total_price DECIMAL(10, 2),
    customer_id INT,                        -- BR7: nullable for walk-ins
    branch_id INT NOT NULL,                 -- BR8: every order -> one branch
    reward_id INT,                          -- BR12: nullable, UNIQUE below
    CONSTRAINT pk_pizza_order PRIMARY KEY (order_id),
    CONSTRAINT uq_pizza_order_reward UNIQUE (reward_id),    -- BR12: one-time use
    CONSTRAINT fk_pizza_order_customer
        FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER (customer_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_pizza_order_branch
        FOREIGN KEY (branch_id)             -- BR8
        REFERENCES BRANCH (branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_pizza_order_reward
        FOREIGN KEY (reward_id)             -- BR12: Redeems relationship
        REFERENCES REWARD (reward_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT chk_pizza_order_type         -- BR10
        CHECK (order_type IN ('online', 'in-person')),
    CONSTRAINT chk_pizza_order_total CHECK (total_price IS NULL OR total_price >= 0)
) ENGINE=InnoDB;

-- INSPECTION: health/safety inspections per branch.
-- BR4: a branch can have many inspections; each belongs to one branch.
CREATE TABLE INSPECTION (
    inspection_id INT NOT NULL AUTO_INCREMENT,
    insp_date DATE NOT NULL,
    result VARCHAR(50) NOT NULL,
    notes VARCHAR(500),
    branch_id INT NOT NULL,
    CONSTRAINT pk_inspection PRIMARY KEY (inspection_id),
    CONSTRAINT fk_inspection_branch
        FOREIGN KEY (branch_id)             -- BR4: each inspection -> one branch
        REFERENCES BRANCH (branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ORDER_ITEM: resolves the Contains M:N between PIZZA_ORDER and MENU_ITEM.
-- BR9:  every order should have at least one row here (enforced by trigger/app).
-- BR14: item_price captured at order time (may differ from current menu price).
CREATE TABLE ORDER_ITEM (
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL,
    item_price DECIMAL(8, 2) NOT NULL,
    CONSTRAINT pk_order_item PRIMARY KEY (order_id, item_id),
    CONSTRAINT fk_order_item_order
        FOREIGN KEY (order_id)
        REFERENCES PIZZA_ORDER (order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_order_item_menu_item
        FOREIGN KEY (item_id)
        REFERENCES MENU_ITEM (item_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_order_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_item_price CHECK (item_price >= 0)
) ENGINE=InnoDB;

-- RECIPE: resolves the Uses M:N between MENU_ITEM and INGREDIENT.
-- BR14: amt_required is specific to each menu-item-ingredient pairing.
CREATE TABLE RECIPE (
    item_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    amt_required DECIMAL(8, 2) NOT NULL,
    CONSTRAINT pk_recipe PRIMARY KEY (item_id, ingredient_id),
    CONSTRAINT fk_recipe_menu_item
        FOREIGN KEY (item_id)
        REFERENCES MENU_ITEM (item_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_recipe_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES INGREDIENT (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_recipe_amt_required CHECK (amt_required > 0)
) ENGINE=InnoDB;

-- INVENTORY: resolves the Stocks M:N between BRANCH and INGREDIENT.
-- BR15: quantity and last_updated are specific to each branch-ingredient pair.
CREATE TABLE INVENTORY (
    branch_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    qty_on_hand DECIMAL(10, 2) NOT NULL,
    last_updated DATE,
    CONSTRAINT pk_inventory PRIMARY KEY (branch_id, ingredient_id),
    CONSTRAINT fk_inventory_branch
        FOREIGN KEY (branch_id)
        REFERENCES BRANCH (branch_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_inventory_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES INGREDIENT (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_inventory_qty_on_hand CHECK (qty_on_hand >= 0)
) ENGINE=InnoDB;
