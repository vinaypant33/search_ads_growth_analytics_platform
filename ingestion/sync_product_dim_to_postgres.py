import pandas as pd
from sqlalchemy import text

from ingestion.config import get_mysql_engine, get_postgres_engine


CHUNK_SIZE = 50_000


def truncate_postgres_product_dim() -> None:
    pg_engine = get_postgres_engine()

    with pg_engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE raw.product_dim"))

    print("Truncated PostgreSQL table: raw.product_dim")


def sync_product_dim_to_postgres() -> None:
    mysql_engine = get_mysql_engine()
    pg_engine = get_postgres_engine()

    truncate_postgres_product_dim()

    query = """
        SELECT
            product_id,
            category_id,
            COALESCE(category_code, 'unknown') AS category_code,
            COALESCE(brand, 'unknown') AS brand,
            'mysql_product_master' AS source_system
        FROM product_dim
    """

    total_inserted = 0

    for chunk_number, chunk in enumerate(
        pd.read_sql_query(query, mysql_engine, chunksize=CHUNK_SIZE),
        start=1,
    ):
        chunk.to_sql(
            name="product_dim",
            con=pg_engine,
            schema="raw",
            if_exists="append",
            index=False,
            method="multi",
            chunksize=10_000,
        )

        total_inserted += len(chunk)
        print(f"Chunk {chunk_number}: synced {len(chunk)} products")

    print(f"Product dimension sync complete. Total synced: {total_inserted}")


if __name__ == "__main__":
    sync_product_dim_to_postgres()