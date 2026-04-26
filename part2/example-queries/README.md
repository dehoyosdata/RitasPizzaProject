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
- `07-branch-staff-directory.sql` lists each branch's manager and employee roster.
- `08-top-selling-menu-items.sql` ranks menu items by orders, units sold, and revenue.
- `09-branch-inspection-summary.sql` summarizes inspection history and flags branches that may need attention.
- `10-branch-menu-capacity.sql` estimates how many full menu items each branch can make from current inventory.
- `Query.sql` combines queries `01` through `10` into one file, with each section labeled and described.
