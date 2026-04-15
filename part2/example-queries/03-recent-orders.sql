-- Show recent orders with customer, branch, totals, and item details.

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
