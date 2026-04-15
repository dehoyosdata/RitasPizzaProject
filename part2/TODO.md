# Part 2 TODO

## Database Choice

Use any database system approved for the project.

Recommended options:

- MySQL
- PostgreSQL

## Setup Plan

Recommended path: Docker

- Use the containerized database environment demonstrated in class.
- Create the database locally.
- Test schema creation and queries in the container.
- Use `docker-compose.yml` and `DOCKER.md` in this folder for the local MySQL setup.

Alternative path: Supabase

- Use Supabase for a simpler cloud-hosted setup.
- Keep the schema and seed files in this repo even if the database is hosted online.

## Submission Checklist

### 1. Schema Creation File

Create `proj2-makeSchema.sql`.

This file should:

- Create the database schema.
- Create all required tables.
- Leave the tables empty.
- Include clear, useful comments.

### 2. Data Population File

Choose one of the following approaches.

#### Option A: SQL Seed File

Create `proj2-fillSchema.sql`.

Requirements:

- Insert at least 5 records per table.
- Write all data manually in SQL.

Note: This works, but it can be tedious for larger datasets.

#### Option B: Seed Script

Create `proj2-fillSchema.py`, or use another scripting language if preferred.

Requirements:

- Automatically generate and insert sample data.
- Produce richer datasets that will be useful for Part 3 queries.

Reference example:

- [seed_library_data.py](https://github.com/TXSTCODEPLAYGROUND/CS4332SPRING2026/blob/main/dal-service/scripts/seed_library_data.py)

Recommended choice: Option B, because it makes it easier to create realistic test data.
