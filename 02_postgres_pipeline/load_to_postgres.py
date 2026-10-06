"""
Load the Olist CSV files into PostgreSQL (raw layer).

- Data is loaded as-is, without cleaning: transformations happen later (ELT).
- Idempotent: each run replaces the tables, so running it twice does not duplicate data.
- Validates that every table has the same number of rows as its CSV file.
"""
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# --- Configuration ---
SCRIPT_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPT_DIR.parent / '01_data_exploration' / 'data'
SCHEMA = 'raw'

# CSV file -> table name in PostgreSQL
FILES_TO_TABLES = {
    'olist_customers_dataset.csv': 'customers',
    'olist_geolocation_dataset.csv': 'geolocation',
    'olist_order_items_dataset.csv': 'order_items',
    'olist_order_payments_dataset.csv': 'order_payments',
    'olist_order_reviews_dataset.csv': 'order_reviews',
    'olist_orders_dataset.csv': 'orders',
    'olist_products_dataset.csv': 'products',
    'olist_sellers_dataset.csv': 'sellers',
    'product_category_name_translation.csv': 'category_translation',
}

# --- Connection ---
load_dotenv(SCRIPT_DIR / '.env')
url = URL.create(
    drivername='postgresql+psycopg2',
    username=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    host=os.getenv('DB_HOST'),
    port=int(os.getenv('DB_PORT')),
    database=os.getenv('DB_NAME'),
)
engine = create_engine(url)

# Create the raw schema if it does not exist yet
with engine.begin() as conn:
    conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS {SCHEMA}'))

# --- Load and validate each file ---
all_ok = True
for file_name, table_name in FILES_TO_TABLES.items():
    df = pd.read_csv(DATA_DIR / file_name)

    #if_exists='replace' makes the script idempotent: the table is recreated on every run
    df.to_sql(table_name, engine, schema=SCHEMA, if_exists='replace',
              index=False, chunksize=10000, method='multi')

    #Validation: rows in the database must match rows in the CSV
    with engine.connect() as conn:
        rows_in_db = conn.execute(text(f'SELECT COUNT(*) FROM {SCHEMA}.{table_name}')).scalar()

    status = 'OK' if rows_in_db == len(df) else 'MISMATCH'
    if status != 'OK':
        all_ok = False
    print(f'{table_name}: CSV {len(df):,} rows | DB {rows_in_db:,} rows | {status}')

if all_ok:
    print('\nAll tables loaded and validated.')
else:
    print('\nWARNING: some tables do not match. Check the output above.')