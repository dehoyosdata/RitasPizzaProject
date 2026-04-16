-- Show menu items with recipe ingredient counts and estimated ingredient cost.

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
