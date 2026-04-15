-- Show registered customers with spending and reward activity.

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
