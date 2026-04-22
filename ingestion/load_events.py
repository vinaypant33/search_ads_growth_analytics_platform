# from pathlib import Path

# import pandas as pd
# from sqlalchemy import text

# from ingestion.config import get_postgres_engine
# from ingestion.data_validator import find_csv_file


# CHUNK_SIZE = 250_000


# def clean_events(df: pd.DataFrame, source_file: str) -> pd.DataFrame:
#     events_df = df[
#         [
#             "event_time",
#             "event_type",
#             "product_id",
#             "category_id",
#             "price",
#             "user_id",
#             "user_session",
#         ]
#     ].copy()

#     events_df["event_time"] = pd.to_datetime(
#         events_df["event_time"],
#         utc=True,
#         errors="coerce",
#     )

#     events_df["event_type"] = events_df["event_type"].astype(str).str.lower().str.strip()

#     events_df["product_id"] = pd.to_numeric(events_df["product_id"], errors="coerce").astype("Int64")
#     events_df["category_id"] = pd.to_numeric(events_df["category_id"], errors="coerce").astype("Int64")
#     events_df["price"] = pd.to_numeric(events_df["price"], errors="coerce")
#     events_df["user_id"] = pd.to_numeric(events_df["user_id"], errors="coerce").astype("Int64")
#     events_df["user_session"] = events_df["user_session"].astype(str)

#     events_df = events_df.dropna(
#         subset=["event_time", "event_type", "product_id", "user_id"]
#     )

#     events_df["source_file"] = source_file

#     return events_df


# def truncate_raw_events() -> None:
#     engine = get_postgres_engine()

#     with engine.begin() as conn:
#         conn.execute(text("TRUNCATE TABLE raw.raw_events RESTART IDENTITY"))

#     print("Truncated PostgreSQL table: raw.raw_events")


# def load_events() -> None:
#     csv_file = find_csv_file()
#     engine = get_postgres_engine()

#     truncate_raw_events()

#     total_inserted = 0

#     usecols = [
#         "event_time",
#         "event_type",
#         "product_id",
#         "category_id",
#         "price",
#         "user_id",
#         "user_session",
#     ]

#     for chunk_number, chunk in enumerate(
#         pd.read_csv(csv_file, usecols=usecols, chunksize=CHUNK_SIZE),
#         start=1,
#     ):
#         events_df = clean_events(chunk, csv_file.name)

#         if events_df.empty:
#             print(f"Chunk {chunk_number}: no valid events")
#             continue

#         events_df.to_sql(
#             name="raw_events",
#             con=engine,
#             schema="raw",
#             if_exists="append",
#             index=False,
#             method="multi",
#             chunksize=10_000,
#         )

#         total_inserted += len(events_df)
#         print(f"Chunk {chunk_number}: inserted {len(events_df)} events")

#     print(f"Raw events load complete. Total inserted: {total_inserted}")


# if __name__ == "__main__":
#     load_events()



# Above one i made in to load the data from the raw file to the postgre sql and for that it was taking a lot of time as the above code takes the data in batches : 
# csv chunk > pandas data frame > sql alchemy insert  > postgre sql table

# The second option for the flow is  : csv file  ?  postgresql copy > stating table > inset selected data ( columns )

from pathlib import Path

import psycopg2
from psycopg2 import sql

from ingestion.config import (
    POSTGRES_HOST,
    POSTGRES_PORT,
    POSTGRES_DB,
    POSTGRES_USER,
    POSTGRES_PASSWORD,
)
from ingestion.data_validator import find_csv_file


def get_postgres_connection():
    return psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        dbname=POSTGRES_DB,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
    )


def load_events_fast_copy() -> None:
    csv_file = find_csv_file()

    conn = get_postgres_connection()
    conn.autocommit = False

    try:
        with conn.cursor() as cur:
            print("Truncating raw.raw_events...")
            cur.execute("TRUNCATE TABLE raw.raw_events RESTART IDENTITY;")

            print("Creating temporary staging table...")
            cur.execute(
                """
                DROP TABLE IF EXISTS raw.raw_events_stage;

                CREATE UNLOGGED TABLE raw.raw_events_stage (
                    event_time TEXT,
                    event_type TEXT,
                    product_id TEXT,
                    category_id TEXT,
                    category_code TEXT,
                    brand TEXT,
                    price TEXT,
                    user_id TEXT,
                    user_session TEXT
                );
                """
            )

            print(f"Loading CSV into staging table using COPY: {csv_file.name}")

            with open(csv_file, "r", encoding="utf-8") as f:
                copy_sql = """
                    COPY raw.raw_events_stage (
                        event_time,
                        event_type,
                        product_id,
                        category_id,
                        category_code,
                        brand,
                        price,
                        user_id,
                        user_session
                    )
                    FROM STDIN
                    WITH (
                        FORMAT CSV,
                        HEADER TRUE,
                        DELIMITER ',',
                        QUOTE '"',
                        ESCAPE '"'
                    );
                """
                cur.copy_expert(copy_sql, f)

            print("Inserting cleaned event columns into raw.raw_events...")
            cur.execute(
                sql.SQL(
                    """
                    INSERT INTO raw.raw_events (
                        event_time,
                        event_type,
                        product_id,
                        category_id,
                        price,
                        user_id,
                        user_session,
                        source_file
                    )
                    SELECT
                        event_time::timestamptz,
                        LOWER(TRIM(event_type)),
                        product_id::bigint,
                        NULLIF(category_id, '')::numeric(20, 0),
                        NULLIF(price, '')::numeric(12, 2),
                        user_id::bigint,
                        NULLIF(user_session, ''),
                        %s
                    FROM raw.raw_events_stage
                    WHERE event_time IS NOT NULL
                      AND event_type IS NOT NULL
                      AND product_id IS NOT NULL
                      AND user_id IS NOT NULL
                      AND LOWER(TRIM(event_type)) IN ('view', 'cart', 'purchase');
                    """
                ),
                [csv_file.name],
            )

            print("Dropping staging table...")
            cur.execute("DROP TABLE IF EXISTS raw.raw_events_stage;")

            print("Recreating indexes...")
            cur.execute(
                """
                CREATE INDEX IF NOT EXISTS idx_raw_events_event_time
                ON raw.raw_events (event_time);

                CREATE INDEX IF NOT EXISTS idx_raw_events_user_id
                ON raw.raw_events (user_id);

                CREATE INDEX IF NOT EXISTS idx_raw_events_user_session
                ON raw.raw_events (user_session);

                CREATE INDEX IF NOT EXISTS idx_raw_events_product_id
                ON raw.raw_events (product_id);

                CREATE INDEX IF NOT EXISTS idx_raw_events_event_type
                ON raw.raw_events (event_type);
                """
            )

            print("Analyzing table statistics...")
            cur.execute("ANALYZE raw.raw_events;")

        conn.commit()

        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM raw.raw_events;")
            total_rows = cur.fetchone()[0]

        print(f"Fast raw events load complete. Total inserted: {total_rows}")

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    load_events_fast_copy()