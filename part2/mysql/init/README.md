# MySQL Init Scripts

Put SQL files in this folder if you want MySQL to run them automatically when the database volume is created for the first time.

Suggested order:

- `01-makeSchema.sql`
- `02-fillSchema.sql`

If the database has already been created, Docker will not rerun these files automatically. Recreate the volume when you need a clean database.
