from pathlib import Path

import pandas as pd
from sqlalchemy import text

from ingestion.config import get_mysql_engine
from ingestion.data_validator import find_csv_file


CHUNK_SIZE = 250_000


def clean_product_master(df: pd.DataFrame) -> pd.DataFrame:
    product_df = df[["product_id", "category_id", "category_code", "brand"]].copy()

    product_df["product_id"] = pd.to_numeric(product_df["product_id"], errors="coerce").astype("Int64")
    product_df["category_id"] = pd.to_numeric(product_df["category_id"], errors="coerce").astype("Int64")

    product_df["category_code"] = product_df["category_code"].fillna("unknown").astype(str)
    product_df["brand"] = product_df["brand"].fillna("unknown").astype(str)

    product_df = product_df.dropna(subset=["product_id"])
    product_df = product_df.drop_duplicates(subset=["product_id"], keep="first")

    return product_df


def truncate_product_dim() -> None:
    engine = get_mysql_engine()

    with engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE product_dim"))

    print("Truncated MySQL table: product_master.product_dim")


def load_product_master() -> None:
    csv_file = find_csv_file()
    engine = get_mysql_engine()

    truncate_product_dim()

    total_inserted = 0
    seen_product_ids = set()

    usecols = ["product_id", "category_id", "category_code", "brand"]

    for chunk_number, chunk in enumerate(
        pd.read_csv(csv_file, usecols=usecols, chunksize=CHUNK_SIZE),
        start=1,
    ):
        product_df = clean_product_master(chunk)

        product_df = product_df[~product_df["product_id"].isin(seen_product_ids)]
        seen_product_ids.update(product_df["product_id"].dropna().astype(int).tolist())

        if product_df.empty:
            print(f"Chunk {chunk_number}: no new products")
            continue

        product_df.to_sql(
            name="product_dim",
            con=engine,
            if_exists="append",
            index=False,
            method="multi",
            chunksize=10_000,
        )

        total_inserted += len(product_df)
        print(f"Chunk {chunk_number}: inserted {len(product_df)} products")

    print(f"Product master load complete. Total inserted: {total_inserted}")


if __name__ == "__main__":
    load_product_master()