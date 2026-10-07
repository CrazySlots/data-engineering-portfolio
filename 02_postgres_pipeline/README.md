# Olist Data Pipeline: PostgreSQL + dbt

> **Status:** In progress. Phase 1 (ingestion) complete.

## Objective
Build a data pipeline that loads the Olist e-commerce dataset into PostgreSQL and transforms it into
clean, tested, analysis-ready tables. This project turns the analysis decisions from
[Project 01](../01_data_exploration) into automated, reusable data models.

## Architecture
CSV files → Python ingestion script → PostgreSQL (`raw` schema) → dbt (coming next)

## Phase 1: Ingestion
`load_to_postgres.py` loads the 9 Olist CSV files into the `raw` schema of a PostgreSQL database.

- **ELT approach:** data is loaded as-is; cleaning and type casting happen later in dbt
- **Idempotent:** each run replaces the tables, so it can be run repeatedly without duplicating data
- **Validated:** compares row counts between each CSV file and its table after loading
- **Secure:** credentials are read from a `.env` file that is excluded from version control

## How to run
1. Install PostgreSQL and create a database called `olist`
2. Install dependencies: `pip install pandas sqlalchemy psycopg2-binary python-dotenv`
3. Copy `.env.example` to `.env` and set your PostgreSQL password
4. Run: `python load_to_postgres.py`

## Roadmap
- [x] Phase 1: Load raw data into PostgreSQL
- [ ] Phase 2: Analytical SQL queries
- [ ] Phase 3: dbt models (staging, intermediate, marts) with tests
- [ ] Phase 4: Final documentation