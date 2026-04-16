# MySQL Docker Setup

## Start MySQL

From this folder:

```powershell
docker compose up -d
```

## Connection Details

Default values:

- Host: `127.0.0.1`
- Port: `3308`
- Database: `ritas_pizza`
- User: `ritas_user`
- Password: `ritas_password`
- Root password: `rootpassword`

To change these values, copy `.env.example` to `.env` and edit the values there.

```powershell
Copy-Item .env.example .env
```

## Stop MySQL

```powershell
docker compose down
```

## Reset The Database

This removes the MySQL volume and recreates the database from scratch the next time you start Docker.

```powershell
docker compose down -v
docker compose up -d
```

## Init SQL Files

SQL files placed in `mysql/init` run automatically only when the MySQL volume is created for the first time.

Suggested files:

- `mysql/init/01-makeSchema.sql`
- `mysql/init/02-fillSchema.sql`

## Generate Seed Data

Run the Python seed generator from the project root:

```powershell
python part2\mysql\init\DataGeneration\proj2-fillSchema.py
```

If data already exists, the script skips seeding. To clear the existing rows and rebuild the sample dataset:

```powershell
python part2\mysql\init\DataGeneration\proj2-fillSchema.py --force
```

To print the generated SQL instead of inserting it:

```powershell
python part2\mysql\init\DataGeneration\proj2-fillSchema.py --print-sql
```

## Example Queries

Example SQL queries live in `example-queries`.

From the `part2` folder, run one query like this:

```powershell
Get-Content -Raw .\example-queries\01-database-overview.sql | docker compose exec -T mysql mysql -uroot -prootpassword ritas_pizza
```

## Port Conflicts

This project maps MySQL to local port `3308` because `3306` is commonly used by another local MySQL server or class container.

If `3308` is already taken, copy `.env.example` to `.env` and set `MYSQL_PORT` to another free local port.
