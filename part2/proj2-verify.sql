-- ============================================================
-- Rita's Pizza Project - Business Rule Verification
-- ============================================================
-- Run after seeding data to prove all 15 business rules hold.
-- Each query is labeled with the BR it checks. A passing check
-- returns 0 rows (violations) or a confirmation count.
--
-- Usage:
--   cat part2/proj2-verify.sql | docker compose exec -T mysql \
--       mysql -uroot -prootpassword ritas_pizza
-- ============================================================

USE ritas_pizza;

-- ============================================================
-- BR1: Each branch has exactly one GMGR at all times.
-- Expect: every branch appears with exactly 1 manager who is a GMGR.
-- ============================================================
SELECT '--- BR1: Each branch has exactly one GMGR manager ---' AS '';

SELECT
    b.branch_id,
    b.city,
    b.manager_id,
    e.name AS manager_name,
    e.type AS manager_type
FROM BRANCH b
JOIN EMPLOYEE e ON b.manager_id = e.employee_id;

-- VIOLATION CHECK: branches whose manager is NOT a GMGR (expect 0 rows).
SELECT '--- BR1 VIOLATION CHECK: managers who are not GMGR (expect 0) ---' AS '';

SELECT b.branch_id, b.city, e.name, e.type
FROM BRANCH b
JOIN EMPLOYEE e ON b.manager_id = e.employee_id
WHERE e.type != 'GMGR';

-- ============================================================
-- BR2: Each employee assigned to at most one branch.
-- Enforced by schema (single branch_id FK). Verify no duplicates.
-- ============================================================
SELECT '--- BR2: Employees with multiple branch assignments (expect 0) ---' AS '';

SELECT employee_id, name, COUNT(DISTINCT branch_id) AS branch_count
FROM EMPLOYEE
GROUP BY employee_id, name
HAVING branch_count > 1;

-- ============================================================
-- BR3: Every employee must be assigned to a branch.
-- ============================================================
SELECT '--- BR3: Employees with NULL branch_id (expect 0) ---' AS '';

SELECT employee_id, name
FROM EMPLOYEE
WHERE branch_id IS NULL;

-- ============================================================
-- BR4: Each inspection belongs to exactly one branch.
-- ============================================================
SELECT '--- BR4: Inspections with NULL branch_id (expect 0) ---' AS '';

SELECT inspection_id
FROM INSPECTION
WHERE branch_id IS NULL;

-- ============================================================
-- BR5: Employee type restricted to valid roles.
-- ============================================================
SELECT '--- BR5: Employees with invalid type (expect 0) ---' AS '';

SELECT employee_id, name, `type`
FROM EMPLOYEE
WHERE `type` NOT IN ('GMGR', 'Shift Manager', 'Cook/Kitchen', 'Cashier/Front');

-- ============================================================
-- BR6: Only a GMGR may manage a branch. Each GMGR manages
--      exactly one branch.
-- ============================================================
SELECT '--- BR6: Non-GMGR employees assigned as manager (expect 0) ---' AS '';

SELECT b.branch_id, b.manager_id, e.type
FROM BRANCH b
JOIN EMPLOYEE e ON b.manager_id = e.employee_id
WHERE e.type != 'GMGR';

SELECT '--- BR6: GMGRs managing more than one branch (expect 0) ---' AS '';

SELECT e.employee_id, e.name, COUNT(*) AS branches_managed
FROM EMPLOYEE e
JOIN BRANCH b ON b.manager_id = e.employee_id
GROUP BY e.employee_id, e.name
HAVING branches_managed > 1;

-- ============================================================
-- BR7: Walk-in orders have NULL customer_id (partial participation).
-- Verify that walk-ins exist and are valid.
-- ============================================================
SELECT '--- BR7: Order mix — registered vs walk-in ---' AS '';

SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN customer_id IS NOT NULL THEN 1 ELSE 0 END) AS registered,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS walk_in
FROM PIZZA_ORDER;

-- ============================================================
-- BR8: Every order processed by exactly one branch.
-- ============================================================
SELECT '--- BR8: Orders with NULL branch_id (expect 0) ---' AS '';

SELECT order_id
FROM PIZZA_ORDER
WHERE branch_id IS NULL;

-- ============================================================
-- BR9: Every order must contain at least one menu item.
-- This cannot be enforced by schema — verify in data.
-- ============================================================
SELECT '--- BR9: Orders with zero items (expect 0) ---' AS '';

SELECT po.order_id, po.order_date
FROM PIZZA_ORDER po
LEFT JOIN ORDER_ITEM oi ON po.order_id = oi.order_id
GROUP BY po.order_id, po.order_date
HAVING COUNT(oi.item_id) = 0;

-- ============================================================
-- BR10: Order type is 'online' or 'in-person'.
-- ============================================================
SELECT '--- BR10: Orders with invalid order_type (expect 0) ---' AS '';

SELECT order_id, order_type
FROM PIZZA_ORDER
WHERE order_type NOT IN ('online', 'in-person');

-- ============================================================
-- BR11: Each reward owned by exactly one customer.
-- ============================================================
SELECT '--- BR11: Rewards with NULL customer_id (expect 0) ---' AS '';

SELECT reward_id
FROM REWARD
WHERE customer_id IS NULL;

-- ============================================================
-- BR12: A reward redeemed at most once.
-- UNIQUE on PIZZA_ORDER.reward_id enforces this, but verify.
-- ============================================================
SELECT '--- BR12: Rewards used on more than one order (expect 0) ---' AS '';

SELECT reward_id, COUNT(*) AS times_used
FROM PIZZA_ORDER
WHERE reward_id IS NOT NULL
GROUP BY reward_id
HAVING times_used > 1;

SELECT '--- BR12: Rewards marked used but not on any order (expect 0) ---' AS '';

SELECT r.reward_id, r.used_status
FROM REWARD r
LEFT JOIN PIZZA_ORDER po ON po.reward_id = r.reward_id
WHERE r.used_status = 'Y' AND po.order_id IS NULL;

SELECT '--- BR12: Rewards on an order but not marked used (expect 0) ---' AS '';

SELECT r.reward_id, r.used_status
FROM REWARD r
JOIN PIZZA_ORDER po ON po.reward_id = r.reward_id
WHERE r.used_status != 'Y';

-- ============================================================
-- BR13: Walk-in orders cannot redeem rewards.
-- If reward_id is set, customer_id must also be set.
-- ============================================================
SELECT '--- BR13: Walk-in orders with a reward (expect 0) ---' AS '';

SELECT order_id, customer_id, reward_id
FROM PIZZA_ORDER
WHERE customer_id IS NULL AND reward_id IS NOT NULL;

-- ============================================================
-- BR14: Each menu item uses one or more ingredients via RECIPE.
-- ============================================================
SELECT '--- BR14: Menu items with no recipe entries (expect 0) ---' AS '';

SELECT mi.item_id, mi.name
FROM MENU_ITEM mi
LEFT JOIN RECIPE r ON mi.item_id = r.item_id
GROUP BY mi.item_id, mi.name
HAVING COUNT(r.ingredient_id) = 0;

-- ============================================================
-- BR15: Each branch maintains its own inventory per ingredient.
-- Verify every branch has inventory rows.
-- ============================================================
SELECT '--- BR15: Branches with no inventory (expect 0) ---' AS '';

SELECT b.branch_id, b.city
FROM BRANCH b
LEFT JOIN INVENTORY i ON b.branch_id = i.branch_id
GROUP BY b.branch_id, b.city
HAVING COUNT(i.ingredient_id) = 0;

-- ============================================================
-- DATA INTEGRITY: total_price matches sum of order items.
-- Orders with a reward get a $5 discount, so allow that delta.
-- ============================================================
SELECT '--- INTEGRITY: Orders where total_price differs from item sum (expect 0 or reward-discounted only) ---' AS '';

SELECT
    po.order_id,
    po.total_price,
    SUM(oi.quantity * oi.item_price) AS computed_subtotal,
    po.reward_id,
    CASE
        WHEN po.reward_id IS NOT NULL
        THEN GREATEST(SUM(oi.quantity * oi.item_price) - 5.00, 0)
        ELSE SUM(oi.quantity * oi.item_price)
    END AS expected_total
FROM PIZZA_ORDER po
JOIN ORDER_ITEM oi ON po.order_id = oi.order_id
GROUP BY po.order_id, po.total_price, po.reward_id
HAVING ABS(po.total_price - expected_total) > 0.01;

-- ============================================================
-- SUMMARY: Row counts per table.
-- ============================================================
SELECT '--- SUMMARY: Row counts ---' AS '';

SELECT 'BRANCH' AS table_name, COUNT(*) AS row_count FROM BRANCH
UNION ALL SELECT 'EMPLOYEE', COUNT(*) FROM EMPLOYEE
UNION ALL SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER
UNION ALL SELECT 'MENU_ITEM', COUNT(*) FROM MENU_ITEM
UNION ALL SELECT 'INGREDIENT', COUNT(*) FROM INGREDIENT
UNION ALL SELECT 'REWARD', COUNT(*) FROM REWARD
UNION ALL SELECT 'PIZZA_ORDER', COUNT(*) FROM PIZZA_ORDER
UNION ALL SELECT 'INSPECTION', COUNT(*) FROM INSPECTION
UNION ALL SELECT 'ORDER_ITEM', COUNT(*) FROM ORDER_ITEM
UNION ALL SELECT 'RECIPE', COUNT(*) FROM RECIPE
UNION ALL SELECT 'INVENTORY', COUNT(*) FROM INVENTORY;
