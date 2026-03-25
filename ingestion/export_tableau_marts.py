from pathlib import Path

import pandas as pd

from ingestion.config import get_postgres_engine


PROJECT_ROOT = Path(__file__).resolve().parents[1]
EXPORT_DIR = PROJECT_ROOT / "data" / "processed" / "tableau_exports"

MART_TABLES = {
    "mart_growth_daily": "dbt_dev_marts.mart_growth_daily",
    "mart_revenue_attribution": "dbt_dev_marts.mart_revenue_attribution",
    "mart_experiment_results": "dbt_dev_marts.mart_experiment_results",
}


def export_table_to_csv(table_name: str, full_table_path: str) -> None:
    engine = get_postgres_engine()

    query = f"""
        SELECT *
        FROM {full_table_path}
    """

    output_path = EXPORT_DIR / f"{table_name}.csv"

    print(f"Exporting {full_table_path}...")
    df = pd.read_sql_query(query, engine)

    df.to_csv(output_path, index=False)

    print(f"Saved {len(df):,} rows to {output_path}")


def main() -> None:
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)

    for table_name, full_table_path in MART_TABLES.items():
        export_table_to_csv(table_name, full_table_path)

    print("All Tableau mart exports completed.")


if __name__ == "__main__":
    main()