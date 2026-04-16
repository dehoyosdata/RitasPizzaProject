-- Compare actual ingredient usage (from orders) against current stock levels.
-- Flags ingredients where projected usage over the last 30 days exceeds
-- current inventory, suggesting a restock is needed.
-- Demonstrates: correlated subquery, multiple JOINs, date filtering,
--               aggregation, CASE expression.

SELECT
    b.branch_id,
    b.city,
    ing.name AS ingredient,
    inv.qty_on_hand,
    ing.unit,
    COALESCE(usage_30d.total_used, 0) AS used_last_30d,
    CASE
        WHEN inv.qty_on_hand < COALESCE(usage_30d.total_used, 0)
        THEN 'RESTOCK NEEDED'
        WHEN inv.qty_on_hand < COALESCE(usage_30d.total_used, 0) * 1.5
        THEN 'LOW'
        ELSE 'OK'
    END AS stock_status
FROM INVENTORY inv
JOIN BRANCH b ON inv.branch_id = b.branch_id
JOIN INGREDIENT ing ON inv.ingredient_id = ing.ingredient_id
LEFT JOIN (
    -- Subquery: total ingredient usage per branch in the last 30 days.
    -- Traces ORDER_ITEM -> RECIPE to compute how much of each ingredient
    -- was consumed by orders at each branch.
    SELECT
        po.branch_id,
        r.ingredient_id,
        SUM(oi.quantity * r.amt_required) AS total_used
    FROM PIZZA_ORDER po
    JOIN ORDER_ITEM oi ON po.order_id = oi.order_id
    JOIN RECIPE r ON oi.item_id = r.item_id
    WHERE po.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY po.branch_id, r.ingredient_id
) usage_30d
    ON usage_30d.branch_id = inv.branch_id
   AND usage_30d.ingredient_id = inv.ingredient_id
WHERE COALESCE(usage_30d.total_used, 0) > 0
ORDER BY
    CASE
        WHEN inv.qty_on_hand < COALESCE(usage_30d.total_used, 0) THEN 0
        WHEN inv.qty_on_hand < COALESCE(usage_30d.total_used, 0) * 1.5 THEN 1
        ELSE 2
    END,
    b.branch_id,
    ing.name;
