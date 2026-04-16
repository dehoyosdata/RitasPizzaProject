-- Show each branch with its manager, staffing level, orders, and sales.

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
