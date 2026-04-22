from ingestion.config import get_postgres_engine, get_mysql_engine


def check_postgres_raw_events():
    engine = get_postgres_engine()

    queries = {
        "total_events": """
            SELECT COUNT(*) 
            FROM raw.raw_events;
        """,
        "event_type_counts": """
            SELECT event_type, COUNT(*) AS event_count
            FROM raw.raw_events
            GROUP BY event_type
            ORDER BY event_count DESC;
        """,
        "date_range": """
            SELECT 
                MIN(event_time) AS min_event_time,
                MAX(event_time) AS max_event_time
            FROM raw.raw_events;
        """,
        "null_check": """
            SELECT
                COUNT(*) FILTER (WHERE event_time IS NULL) AS null_event_time,
                COUNT(*) FILTER (WHERE event_type IS NULL) AS null_event_type,
                COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
                COUNT(*) FILTER (WHERE user_id IS NULL) AS null_user_id,
                COUNT(*) FILTER (WHERE user_session IS NULL) AS null_user_session,
                COUNT(*) FILTER (WHERE price IS NULL) AS null_price
            FROM raw.raw_events;
        """,
        "sample_rows": """
            SELECT *
            FROM raw.raw_events
            LIMIT 5;
        """,
    }

    print("\nPOSTGRESQL RAW EVENTS CHECKS")
    print("=*=" * 60)

    with engine.connect() as conn:
        for check_name, query in queries.items():
            print(f"\n{check_name.upper()}")
            result = conn.exec_driver_sql(query)

            rows = result.fetchall()
            for row in rows:
                print(row)


def check_mysql_product_dim():
    engine = get_mysql_engine()

    queries = {
        "total_products": """
            SELECT COUNT(*) 
            FROM product_dim;
        """,
        "unknown_category_code_count": """
            SELECT COUNT(*) 
            FROM product_dim
            WHERE category_code = 'unknown';
        """,
        "unknown_brand_count": """
            SELECT COUNT(*) 
            FROM product_dim
            WHERE brand = 'unknown';
        """,
        "sample_rows": """
            SELECT *
            FROM product_dim
            LIMIT 5;
        """,
    }

    print("\nMYSQL PRODUCT DIM CHECKS")
    print("=" * 60)

    with engine.connect() as conn:
        for check_name, query in queries.items():
            print(f"\n{check_name.upper()}")
            result = conn.exec_driver_sql(query)

            rows = result.fetchall()
            for row in rows:
                print(row)


if __name__ == "__main__":
    check_postgres_raw_events()
    check_mysql_product_dim()