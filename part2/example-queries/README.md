# Example Queries

These SQL files show what is currently in the Rita's Pizza database after running the schema and seed scripts.

Run a single query from the `part2` folder:

```powershell
Get-Content -Raw .\example-queries\01-database-overview.sql | docker compose exec -T mysql mysql -uroot -prootpassword ritas_pizza
```

Run every query from the `part2` folder:

```powershell
Get-ChildItem .\example-queries\*.sql | Sort-Object Name | ForEach-Object {
    Write-Host "`n--- $($_.Name) ---"
    Get-Content -Raw $_.FullName | docker compose exec -T mysql mysql -uroot -prootpassword ritas_pizza
}
```

## Files

- `01-database-overview.sql` counts rows in each table.
- `02-branch-sales-summary.sql` summarizes sales and staffing by branch.
- `03-recent-orders.sql` shows recent orders with line items.
- `04-menu-recipes.sql` shows menu items and their ingredients.
- `05-customer-rewards.sql` summarizes customer spending and reward use.
- `06-inventory-status.sql` shows ingredients that are low or worth checking.

### Part 3 preview (advanced)

- `07-top-customers-by-branch.sql` ranks customers by spending per branch using `RANK()` window function.
- `08-ingredient-usage-vs-stock.sql` compares 30-day ingredient usage against inventory using correlated subqueries.
- `09-monthly-sales-trends.sql` shows revenue trends with running totals and month-over-month growth via `LAG()` and CTEs.
