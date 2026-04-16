-- Monthly sales trends per branch with running totals and month-over-month
-- growth percentage.
-- Demonstrates: window functions (SUM OVER, LAG), DATE_FORMAT, CTEs,
--               calculated columns, ROUND.

WITH monthly AS (
    SELECT
        b.branch_id,
        b.city,
        DATE_FORMAT(po.order_date, '%Y-%m') AS month,
        COUNT(po.order_id) AS order_count,
        SUM(po.total_price) AS revenue,
        COUNT(DISTINCT po.customer_id) AS unique_customers
    FROM PIZZA_ORDER po
    JOIN BRANCH b ON po.branch_id = b.branch_id
    GROUP BY b.branch_id, b.city, DATE_FORMAT(po.order_date, '%Y-%m')
)
SELECT
    branch_id,
    city,
    month,
    order_count,
    ROUND(revenue, 2) AS revenue,
    unique_customers,
    -- Running total of revenue for this branch across months.
    ROUND(SUM(revenue) OVER (
        PARTITION BY branch_id
        ORDER BY month
    ), 2) AS cumulative_revenue,
    -- Month-over-month revenue growth percentage.
    ROUND(
        (revenue - LAG(revenue) OVER (PARTITION BY branch_id ORDER BY month))
        / NULLIF(LAG(revenue) OVER (PARTITION BY branch_id ORDER BY month), 0)
        * 100,
        1
    ) AS revenue_growth_pct
FROM monthly
ORDER BY branch_id, month;
