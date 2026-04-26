-- Rita's Pizza combined query file
-- Includes example queries 01 through 10.

-- 01-database-overview.sql
-- Counts rows in each table.

SELECT 'BRANCH' AS table_name, COUNT(*) AS row_count FROM BRANCH
UNION ALL
SELECT 'EMPLOYEE', COUNT(*) FROM EMPLOYEE
UNION ALL
SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER
UNION ALL
SELECT 'MENU_ITEM', COUNT(*) FROM MENU_ITEM
UNION ALL
SELECT 'INGREDIENT', COUNT(*) FROM INGREDIENT
UNION ALL
SELECT 'REWARD', COUNT(*) FROM REWARD
UNION ALL
SELECT 'PIZZA_ORDER', COUNT(*) FROM PIZZA_ORDER
UNION ALL
SELECT 'ORDER_ITEM', COUNT(*) FROM ORDER_ITEM
UNION ALL
SELECT 'RECIPE', COUNT(*) FROM RECIPE
UNION ALL
SELECT 'INVENTORY', COUNT(*) FROM INVENTORY
UNION ALL
SELECT 'INSPECTION', COUNT(*) FROM INSPECTION
ORDER BY table_name;

-- 02-branch-sales-summary.sql
-- Summarizes sales and staffing by branch.

SELECT
    b.branch_id,
    b.city,
    b.street_addr,
    manager.name AS manager_name,
    COALESCE(staff.employee_count, 0) AS employee_count,
    COALESCE(orders.order_count, 0) AS order_count,
    COALESCE(orders.total_sales, 0.00) AS total_sales
FROM BRANCH AS b
JOIN EMPLOYEE AS manager
    ON b.manager_id = manager.employee_id
LEFT JOIN (
    SELECT
        branch_id,
        COUNT(*) AS employee_count
    FROM EMPLOYEE
    GROUP BY branch_id
) AS staff
    ON b.branch_id = staff.branch_id
LEFT JOIN (
    SELECT
        branch_id,
        COUNT(*) AS order_count,
        ROUND(SUM(total_price), 2) AS total_sales
    FROM PIZZA_ORDER
    GROUP BY branch_id
) AS orders
    ON b.branch_id = orders.branch_id
ORDER BY total_sales DESC, b.city;

-- 03-recent-orders.sql
-- Shows recent orders with line items.

SELECT
    po.order_id,
    po.order_date,
    b.city AS branch_city,
    COALESCE(c.name, 'Walk-in') AS customer_name,
    po.order_type,
    po.total_price,
    COUNT(oi.item_id) AS line_count,
    SUM(oi.quantity) AS item_quantity,
    GROUP_CONCAT(
        CONCAT(oi.quantity, 'x ', mi.name)
        ORDER BY mi.name
        SEPARATOR '; '
    ) AS items
FROM PIZZA_ORDER AS po
JOIN BRANCH AS b
    ON po.branch_id = b.branch_id
LEFT JOIN CUSTOMER AS c
    ON po.customer_id = c.customer_id
JOIN ORDER_ITEM AS oi
    ON po.order_id = oi.order_id
JOIN MENU_ITEM AS mi
    ON oi.item_id = mi.item_id
GROUP BY
    po.order_id,
    po.order_date,
    b.city,
    c.name,
    po.order_type,
    po.total_price
ORDER BY po.order_date DESC, po.order_id DESC
LIMIT 20;

-- 04-menu-recipes.sql
-- Shows menu items and their ingredients.

SELECT
    mi.item_id,
    mi.name,
    mi.category,
    mi.price,
    COUNT(r.ingredient_id) AS ingredient_count,
    ROUND(SUM(r.amt_required * ing.cost_per_unit), 2) AS estimated_ingredient_cost,
    GROUP_CONCAT(
        CONCAT(ing.name, ' (', r.amt_required, ' ', ing.unit, ')')
        ORDER BY ing.name
        SEPARATOR '; '
    ) AS ingredients
FROM MENU_ITEM AS mi
LEFT JOIN RECIPE AS r
    ON mi.item_id = r.item_id
LEFT JOIN INGREDIENT AS ing
    ON r.ingredient_id = ing.ingredient_id
GROUP BY
    mi.item_id,
    mi.name,
    mi.category,
    mi.price
ORDER BY mi.category, mi.name;

-- 05-customer-rewards.sql
-- Summarizes customer spending and reward use.

SELECT
    c.customer_id,
    c.name,
    c.email,
    c.rewards_pts,
    COALESCE(order_stats.order_count, 0) AS order_count,
    COALESCE(order_stats.total_spent, 0.00) AS total_spent,
    COALESCE(reward_stats.rewards_issued, 0) AS rewards_issued,
    COALESCE(reward_stats.rewards_used, 0) AS rewards_used
FROM CUSTOMER AS c
LEFT JOIN (
    SELECT
        customer_id,
        COUNT(*) AS order_count,
        ROUND(SUM(total_price), 2) AS total_spent
    FROM PIZZA_ORDER
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) AS order_stats
    ON c.customer_id = order_stats.customer_id
LEFT JOIN (
    SELECT
        customer_id,
        COUNT(*) AS rewards_issued,
        SUM(CASE WHEN used_status = 'Y' THEN 1 ELSE 0 END) AS rewards_used
    FROM REWARD
    GROUP BY customer_id
) AS reward_stats
    ON c.customer_id = reward_stats.customer_id
ORDER BY total_spent DESC, c.rewards_pts DESC
LIMIT 20;

-- 06-inventory-status.sql
-- Shows ingredients that are low or worth checking.
-- Thresholds vary by unit because ingredients are stored in different units.

SELECT
    b.city AS branch_city,
    ing.name AS ingredient_name,
    ing.unit,
    inv.qty_on_hand,
    inv.last_updated,
    CASE
        WHEN ing.unit IN ('piece', 'ball') THEN 60
        WHEN ing.unit = 'lb' THEN 30
        WHEN ing.unit = 'cup' THEN 75
        ELSE 200
    END AS check_threshold
FROM INVENTORY AS inv
JOIN BRANCH AS b
    ON inv.branch_id = b.branch_id
JOIN INGREDIENT AS ing
    ON inv.ingredient_id = ing.ingredient_id
WHERE inv.qty_on_hand < CASE
    WHEN ing.unit IN ('piece', 'ball') THEN 60
    WHEN ing.unit = 'lb' THEN 30
    WHEN ing.unit = 'cup' THEN 75
    ELSE 200
END
ORDER BY b.city, inv.qty_on_hand, ing.name
LIMIT 30;

-- 07-branch-staff-directory.sql
-- Lists each branch's manager and employee roster.

SELECT
    b.branch_id,
    b.city,
    b.street_addr,
    manager.name AS branch_manager,
    e.employee_id,
    e.name AS employee_name,
    e.type AS employee_type,
    e.hire_date,
    e.wage,
    CASE
        WHEN e.employee_id = b.manager_id THEN 'Manager'
        ELSE 'Staff'
    END AS assignment_role
FROM BRANCH AS b
JOIN EMPLOYEE AS manager
    ON b.manager_id = manager.employee_id
JOIN EMPLOYEE AS e
    ON b.branch_id = e.branch_id
ORDER BY
    b.city,
    CASE
        WHEN e.employee_id = b.manager_id THEN 0
        WHEN e.type = 'Shift Manager' THEN 1
        WHEN e.type = 'Cook/Kitchen' THEN 2
        ELSE 3
    END,
    e.name;

-- 08-top-selling-menu-items.sql
-- Ranks menu items by orders, units sold, and revenue.

SELECT
    mi.item_id,
    mi.name,
    mi.category,
    mi.price,
    COUNT(DISTINCT oi.order_id) AS order_count,
    COALESCE(SUM(oi.quantity), 0) AS units_sold,
    COALESCE(ROUND(SUM(oi.quantity * oi.item_price), 2), 0.00) AS gross_revenue
FROM MENU_ITEM AS mi
LEFT JOIN ORDER_ITEM AS oi
    ON mi.item_id = oi.item_id
GROUP BY
    mi.item_id,
    mi.name,
    mi.category,
    mi.price
ORDER BY units_sold DESC, gross_revenue DESC, mi.name
LIMIT 15;

-- 09-branch-inspection-summary.sql
-- Summarizes inspection history and flags branches that may need attention.

SELECT
    b.branch_id,
    b.city,
    b.street_addr,
    COALESCE(i.inspection_count, 0) AS inspection_count,
    i.last_inspection_date,
    COALESCE(i.pass_count, 0) AS pass_count,
    COALESCE(i.conditional_pass_count, 0) AS conditional_pass_count,
    COALESCE(i.reinspection_count, 0) AS reinspection_count,
    CASE
        WHEN COALESCE(i.reinspection_count, 0) > 0 THEN 'Needs Attention'
        WHEN COALESCE(i.conditional_pass_count, 0) > 0 THEN 'Monitor'
        ELSE 'Strong Record'
    END AS inspection_status
FROM BRANCH AS b
LEFT JOIN (
    SELECT
        branch_id,
        COUNT(*) AS inspection_count,
        MAX(insp_date) AS last_inspection_date,
        SUM(CASE WHEN result = 'Pass' THEN 1 ELSE 0 END) AS pass_count,
        SUM(CASE WHEN result = 'Conditional Pass' THEN 1 ELSE 0 END) AS conditional_pass_count,
        SUM(CASE WHEN result = 'Needs Reinspection' THEN 1 ELSE 0 END) AS reinspection_count
    FROM INSPECTION
    GROUP BY branch_id
) AS i
    ON b.branch_id = i.branch_id
ORDER BY
    CASE
        WHEN COALESCE(i.reinspection_count, 0) > 0 THEN 0
        WHEN COALESCE(i.conditional_pass_count, 0) > 0 THEN 1
        ELSE 2
    END,
    i.last_inspection_date DESC,
    b.city;

-- 10-branch-menu-capacity.sql
-- Estimates how many full menu items each branch can make from current inventory.
-- Uses the limiting ingredient in each recipe to estimate capacity.

SELECT
    b.branch_id,
    b.city AS branch_city,
    mi.item_id,
    mi.name AS menu_item_name,
    mi.category,
    MIN(FLOOR(COALESCE(inv.qty_on_hand, 0) / r.amt_required)) AS estimated_full_orders,
    COUNT(*) AS ingredient_count,
    ROUND(SUM(r.amt_required * ing.cost_per_unit), 2) AS estimated_ingredient_cost
FROM BRANCH AS b
CROSS JOIN MENU_ITEM AS mi
JOIN RECIPE AS r
    ON mi.item_id = r.item_id
JOIN INGREDIENT AS ing
    ON r.ingredient_id = ing.ingredient_id
LEFT JOIN INVENTORY AS inv
    ON inv.branch_id = b.branch_id
   AND inv.ingredient_id = r.ingredient_id
GROUP BY
    b.branch_id,
    b.city,
    mi.item_id,
    mi.name,
    mi.category
ORDER BY
    estimated_full_orders ASC,
    b.city,
    mi.name
LIMIT 30;
