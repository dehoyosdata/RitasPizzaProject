-- Moderate query:
-- Show which menu items sell the most and generate the most revenue.

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
