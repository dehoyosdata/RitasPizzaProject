-- Basic query:
-- Show each branch with its manager and full employee roster.

SELECT
    b.branch_id,
    b.city,
    b.street_addr,
    manager.name AS branch_manager,
    e.employee_id,
    e.name AS employee_name,
    e.type AS employee_type,
    e.hire_date,
    e.wage,
    CASE
        WHEN e.employee_id = b.manager_id THEN 'Manager'
        ELSE 'Staff'
    END AS assignment_role
FROM BRANCH AS b
JOIN EMPLOYEE AS manager
    ON b.manager_id = manager.employee_id
JOIN EMPLOYEE AS e
    ON b.branch_id = e.branch_id
ORDER BY
    b.city,
    CASE
        WHEN e.employee_id = b.manager_id THEN 0
        WHEN e.type = 'Shift Manager' THEN 1
        WHEN e.type = 'Cook/Kitchen' THEN 2
        ELSE 3
    END,
    e.name;
