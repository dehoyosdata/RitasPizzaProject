-- Moderate to advanced query:
-- Summarize inspection history for each branch and highlight locations
-- that may need more attention.

SELECT
    b.branch_id,
    b.city,
    b.street_addr,
    COALESCE(i.inspection_count, 0) AS inspection_count,
    i.last_inspection_date,
    COALESCE(i.pass_count, 0) AS pass_count,
    COALESCE(i.conditional_pass_count, 0) AS conditional_pass_count,
    COALESCE(i.reinspection_count, 0) AS reinspection_count,
    CASE
        WHEN COALESCE(i.reinspection_count, 0) > 0 THEN 'Needs Attention'
        WHEN COALESCE(i.conditional_pass_count, 0) > 0 THEN 'Monitor'
        ELSE 'Strong Record'
    END AS inspection_status
FROM BRANCH AS b
LEFT JOIN (
    SELECT
        branch_id,
        COUNT(*) AS inspection_count,
        MAX(insp_date) AS last_inspection_date,
        SUM(CASE WHEN result = 'Pass' THEN 1 ELSE 0 END) AS pass_count,
        SUM(CASE WHEN result = 'Conditional Pass' THEN 1 ELSE 0 END) AS conditional_pass_count,
        SUM(CASE WHEN result = 'Needs Reinspection' THEN 1 ELSE 0 END) AS reinspection_count
    FROM INSPECTION
    GROUP BY branch_id
) AS i
    ON b.branch_id = i.branch_id
ORDER BY
    CASE
        WHEN COALESCE(i.reinspection_count, 0) > 0 THEN 0
        WHEN COALESCE(i.conditional_pass_count, 0) > 0 THEN 1
        ELSE 2
    END,
    i.last_inspection_date DESC,
    b.city;
