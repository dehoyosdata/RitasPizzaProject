-- Advanced query:
-- Estimate how many full menu items each branch could make from its
-- current inventory, based on the limiting ingredient in each recipe.

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
