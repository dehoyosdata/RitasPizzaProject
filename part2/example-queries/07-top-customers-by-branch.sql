-- Find the top-spending customer at each branch using a ranked subquery.
-- Demonstrates: subquery, window function (RANK), JOIN, GROUP BY, HAVING.

SELECT ranked.branch_id,
       ranked.city,
       ranked.customer_id,
       ranked.customer_name,
       ranked.total_spent,
       ranked.order_count,
       ranked.spending_rank
FROM (
    SELECT
        b.branch_id,
        b.city,
        c.customer_id,
        c.name AS customer_name,
        SUM(po.total_price) AS total_spent,
        COUNT(po.order_id) AS order_count,
        RANK() OVER (
            PARTITION BY b.branch_id
            ORDER BY SUM(po.total_price) DESC
        ) AS spending_rank
    FROM PIZZA_ORDER po
    JOIN BRANCH b ON po.branch_id = b.branch_id
    JOIN CUSTOMER c ON po.customer_id = c.customer_id
    GROUP BY b.branch_id, b.city, c.customer_id, c.name
) ranked
WHERE ranked.spending_rank <= 3
ORDER BY ranked.branch_id, ranked.spending_rank;
