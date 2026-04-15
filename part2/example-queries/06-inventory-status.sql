-- Show inventory rows that are low enough to check soon.
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
