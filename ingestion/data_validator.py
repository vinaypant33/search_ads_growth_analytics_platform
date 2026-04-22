from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

EXPECTED_COLUMNS = [
    "event_time",
    "event_type",
    "product_id",
    "category_id",
    "category_code",
    "brand",
    "price",
    "user_id",
    "user_session",
]


def find_csv_file() -> Path:
    csv_files = list(RAW_DATA_DIR.glob("*.csv"))

    if not csv_files:
        raise FileNotFoundError(f"No CSV file found in {RAW_DATA_DIR}")

    if len(csv_files) > 1:
        print("Multiple CSV files found. Using the first CSV:")
        for file in csv_files:
            print(f"- {file.name}")

    return csv_files[0]


def validate_csv_structure(file_path: Path) -> None:
    df_sample = pd.read_csv(file_path, nrows=1000)

    missing_columns = [col for col in EXPECTED_COLUMNS if col not in df_sample.columns]
    extra_columns = [col for col in df_sample.columns if col not in EXPECTED_COLUMNS]

    if missing_columns:
        raise ValueError(f"Missing expected columns: {missing_columns}")

    print("CSV structure validation passed.")
    print(f"File: {file_path.name}")
    print(f"Columns: {list(df_sample.columns)}")

    if extra_columns:
        print(f"Extra columns found: {extra_columns}")


def validate_event_types(file_path: Path) -> None:
    df_sample = pd.read_csv(file_path, usecols=["event_type"], nrows=100000)

    valid_event_types = {"view", "cart", "purchase"}
    actual_event_types = set(df_sample["event_type"].dropna().unique())

    invalid_event_types = actual_event_types - valid_event_types

    if invalid_event_types:
        raise ValueError(f"Invalid event types found: {invalid_event_types}")

    print("Event type validation passed.")
    print(f"Event types found: {sorted(actual_event_types)}")


def validate_required_fields(file_path: Path) -> None:
    required_columns = ["event_time", "event_type", "product_id", "price", "user_id"]

    df_sample = pd.read_csv(file_path, usecols=required_columns, nrows=100000)
    null_counts = df_sample[required_columns].isna().sum()

    print("Null check on required fields:")
    print(null_counts)

    critical_nulls = null_counts[null_counts > 0]

    if not critical_nulls.empty:
        raise ValueError(f"Nulls found in required fields:\n{critical_nulls}")

    print("Required field validation passed.")


def run_validations() -> Path:
    csv_file = find_csv_file()

    validate_csv_structure(csv_file)
    validate_event_types(csv_file)
    validate_required_fields(csv_file)

    print("All validations passed.")
    return csv_file


if __name__ == "__main__":
    run_validations()