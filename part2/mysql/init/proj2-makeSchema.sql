-- Rita's Pizza Project - Part 2 Schema
-- MySQL version of the DBML in part1/relational-schema.dbml.
-- This script creates empty tables only.

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

-- Stores each Rita's Pizza location.
-- manager_id is added as a foreign key after EMPLOYEE exists because
-- BRANCH and EMPLOYEE reference each other.
CREATE TABLE BRANCH (
    branch_id INT NOT NULL AUTO_INCREMENT,
    street_addr VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    phone_no VARCHAR(20),
    opening_hrs VARCHAR(50),
    seating_cap INT,
    manager_id INT NOT NULL,
    CONSTRAINT pk_branch PRIMARY KEY (branch_id),
    CONSTRAINT uq_branch_manager UNIQUE (manager_id),
    CONSTRAINT chk_branch_seating_cap CHECK (seating_cap IS NULL OR seating_cap >= 0)
) ENGINE=InnoDB;

-- Stores employees assigned to branches.
CREATE TABLE EMPLOYEE (
    employee_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    hire_date DATE NOT NULL,
    wage DECIMAL(8, 2),
    branch_id INT NOT NULL,
    CONSTRAINT pk_employee PRIMARY KEY (employee_id),
    CONSTRAINT fk_employee_branch
        FOREIGN KEY (branch_id)
        REFERENCES BRANCH (branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_employee_type
        CHECK (`type` IN ('GMGR', 'Shift Manager', 'Cook/Kitchen', 'Cashier/Front')),
    CONSTRAINT chk_employee_wage CHECK (wage IS NULL OR wage >= 0)
) ENGINE=InnoDB;

-- Completes the circular BRANCH manager relationship from the DBML.
ALTER TABLE BRANCH
    ADD CONSTRAINT fk_branch_manager
        FOREIGN KEY (manager_id)
        REFERENCES EMPLOYEE (employee_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

-- Stores registered customers. Walk-in orders can leave customer_id NULL.
CREATE TABLE CUSTOMER (
    customer_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    rewards_pts INT DEFAULT 0,
    date_joined DATE,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email UNIQUE (email),
    CONSTRAINT chk_customer_rewards_pts CHECK (rewards_pts >= 0)
) ENGINE=InnoDB;

-- Stores menu items sold by the restaurant.
CREATE TABLE MENU_ITEM (
    item_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(8, 2) NOT NULL,
    category VARCHAR(50),
    CONSTRAINT pk_menu_item PRIMARY KEY (item_id),
    CONSTRAINT chk_menu_item_price CHECK (price >= 0)
) ENGINE=InnoDB;

-- Stores ingredients used by recipes and branch inventory.
CREATE TABLE INGREDIENT (
    ingredient_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    cost_per_unit DECIMAL(8, 2),
    CONSTRAINT pk_ingredient PRIMARY KEY (ingredient_id),
    CONSTRAINT chk_ingredient_cost CHECK (cost_per_unit IS NULL OR cost_per_unit >= 0)
) ENGINE=InnoDB;

-- Stores rewards issued to registered customers.
CREATE TABLE REWARD (
    reward_id INT NOT NULL AUTO_INCREMENT,
    description VARCHAR(200),
    reward_type VARCHAR(50),
    issue_date DATE,
    used_status CHAR(1) DEFAULT 'N',
    customer_id INT NOT NULL,
    CONSTRAINT pk_reward PRIMARY KEY (reward_id),
    CONSTRAINT fk_reward_customer
        FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER (customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_reward_used_status CHECK (used_status IN ('Y', 'N'))
) ENGINE=InnoDB;

-- PIZZA_ORDER avoids the reserved word ORDER.
CREATE TABLE PIZZA_ORDER (
    order_id INT NOT NULL AUTO_INCREMENT,
    order_date DATE NOT NULL,
    order_type VARCHAR(20) NOT NULL,
    total_price DECIMAL(10, 2),
    customer_id INT,
    branch_id INT NOT NULL,
    reward_id INT,
    CONSTRAINT pk_pizza_order PRIMARY KEY (order_id),
    CONSTRAINT uq_pizza_order_reward UNIQUE (reward_id),
    CONSTRAINT fk_pizza_order_customer
        FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER (customer_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_pizza_order_branch
        FOREIGN KEY (branch_id)
        REFERENCES BRANCH (branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_pizza_order_reward
        FOREIGN KEY (reward_id)
        REFERENCES REWARD (reward_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT chk_pizza_order_type CHECK (order_type IN ('online', 'in-person')),
    CONSTRAINT chk_pizza_order_total CHECK (total_price IS NULL OR total_price >= 0)
) ENGINE=InnoDB;

-- Stores health/safety inspections for each branch.
CREATE TABLE INSPECTION (
    inspection_id INT NOT NULL AUTO_INCREMENT,
    insp_date DATE NOT NULL,
    result VARCHAR(50) NOT NULL,
    notes VARCHAR(500),
    branch_id INT NOT NULL,
    CONSTRAINT pk_inspection PRIMARY KEY (inspection_id),
    CONSTRAINT fk_inspection_branch
        FOREIGN KEY (branch_id)
        REFERENCES BRANCH (branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Associative table for the PIZZA_ORDER to MENU_ITEM many-to-many relationship.
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

-- Associative table for the MENU_ITEM to INGREDIENT many-to-many relationship.
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

-- Associative table for the BRANCH to INGREDIENT inventory relationship.
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
