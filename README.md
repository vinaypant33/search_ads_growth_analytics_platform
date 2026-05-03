# Search & Ads Growth Analytics Platform

> End-to-end product analytics pipeline for e-commerce clickstream data — built with PostgreSQL, dbt Core, Tableau, and GitHub Actions.

This project follows a **production-style analytics engineering workflow**, not just a CSV dropped into a dashboard. Business logic lives in dbt. Tableau is the presentation layer only.

---

## Table of Contents

- [Project Objective](#project-objective)
- [Business Problem](#business-problem)
- [Architecture](#architecture)
- [Data Warehouse Layers](#data-warehouse-layers)
- [dbt Models](#dbt-models)
- [Key Metrics](#key-metrics)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [How to Run](#how-to-run)
- [Screenshots](#screenshots)
- [Design Decisions](#design-decisions)
- [Future Improvements](#future-improvements)

---

## Project Objective

Most analytics portfolio projects start from a flat CSV loaded directly into Tableau or Power BI.

This project takes a different approach — one closer to how analytics engineering works in practice:

```
Raw Clickstream CSV
        ↓
Python Ingestion Scripts
        ↓
PostgreSQL — Raw Schema
        ↓
dbt Staging Models
        ↓
dbt Fact & Dimension Models
        ↓
dbt Mart Models (Tableau-ready)
        ↓
Python Export Script → CSV
        ↓
Tableau Public Dashboard
        ↓
GitHub Actions CI Validation
```

The goal is to answer product and growth questions such as:

- How much revenue was generated, and how is it trending?
- How many users, sessions, and purchases occurred?
- How do users move from view → cart → purchase?
- How does conversion rate change over time?
- Which event types dominate user behaviour?

---

## Business Problem

Growth and product teams need a reliable way to monitor digital funnel performance. A dashboard can show numbers — but it doesn't guarantee those numbers are clean, reusable, or tested.

This project solves that by building a structured analytics pipeline where all metric logic is prepared and validated in dbt **before** being visualised.

The dashboard supports:

- Executive-level growth monitoring
- Funnel performance review
- Revenue trend analysis
- Conversion tracking
- User activity vs purchase behaviour

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Data Sources                                │
│         Clickstream CSV  ·  Product Master CSV                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Python Ingestion Layer                        │
│    sync_product_dim_to_postgres.py  ·  export_tableau_marts.py  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                 PostgreSQL — Raw Schema                         │
│            raw.raw_events  ·  raw.product_dim                   │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     dbt Core Pipeline                           │
│                                                                 │
│   Staging      →   stg_events                                   │
│                                                                 │
│   Facts        →   fact_sessions                                │
│                    fact_funnel_steps                            │
│                    fact_conversions                             │
│                                                                 │
│   Dimensions   →   dim_user  ·  dim_date  ·  dim_product        │
│                                                                 │
│   Marts        →   mart_growth_daily                            │
│                    mart_revenue_attribution                     │
│                    mart_experiment_results                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              Tableau Public Dashboard                           │
│     KPI Cards · Revenue Trend · Funnel · Conversion Rate        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  GitHub Actions CI                              │
│        dbt_pr_check.yml  ·  dbt_daily_run.yml                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Warehouse Layers

### Raw Layer

Raw source data loaded into PostgreSQL with minimal transformation. Source fidelity is preserved for reprocessing.

| Table | Description |
|---|---|
| `raw.raw_events` | Raw clickstream events — view, cart, purchase |
| `raw.product_dim` | Product master data synced from source |

---

### Staging Layer

Standardises and cleans raw event data for all downstream models.

| Model | Key Transformations |
|---|---|
| `stg_events` | Timestamp parsing, event type normalisation, user/session field cleaning, product/category prep |

---

### Facts & Dimensions

Reusable analytical models. Facts record events at meaningful grain; dimensions provide context for slicing.

**Fact Models**

| Model | Purpose | Grain |
|---|---|---|
| `fact_sessions` | Session-level user journey metrics | 1 row per session |
| `fact_funnel_steps` | Daily funnel movement and conversion metrics | 1 row per day per funnel step |
| `fact_conversions` | Purchase and revenue records | 1 row per purchase |

**Dimension Models**

| Model | Purpose |
|---|---|
| `dim_user` | User profile and behaviour summary |
| `dim_date` | Calendar dimension for time-based slicing |
| `dim_product` | Product, category, and brand dimension |

---

### Mart Layer

Dashboard-ready aggregates exported as CSVs for Tableau Public. These are the only tables Tableau reads.

| Mart | Contents |
|---|---|
| `mart_growth_daily` | Daily revenue, active users, sessions, purchases, conversion rate |
| `mart_revenue_attribution` | Revenue broken down by category and brand |
| `mart_experiment_results` | Simulated A/B experiment outcomes |

---

## dbt Models

### Staging

```sql
-- stg_events
-- Cleans raw clickstream into a standardised event table

select
    event_id,
    cast(event_time as timestamp)         as event_timestamp,
    date(event_time)                      as event_date,
    lower(event_type)                     as event_type,
    user_id,
    user_session,
    product_id,
    category_id,
    category_code,
    brand,
    price
from {{ source('raw', 'raw_events') }}
where event_type in ('view', 'cart', 'purchase')
```

### dbt Tests Applied

```yaml
models:
  - name: stg_events
    columns:
      - name: event_id
        tests: [not_null, unique]
      - name: user_id
        tests: [not_null]
      - name: event_type
        tests:
          - accepted_values:
              values: ['view', 'cart', 'purchase']
      - name: event_date
        tests: [not_null]
```

Tests cover: event IDs, user IDs, session IDs, event types, conversion IDs, product IDs, date fields, and mart-level metrics.

---

## Key Metrics

All metrics are computed in dbt before Tableau reads them. No hidden calculated fields.

| Metric | Source Model |
|---|---|
| Total Revenue | `mart_growth_daily` |
| Active Users | `mart_growth_daily` |
| Sessions | `mart_growth_daily` |
| Purchases | `mart_growth_daily` |
| View-to-Purchase Conversion Rate | `fact_funnel_steps` |
| Daily Revenue Trend | `mart_growth_daily` |
| Daily Users vs Purchases | `mart_growth_daily` |
| Daily Conversion Rate Trend | `mart_growth_daily` |
| Revenue per Active User | `mart_growth_daily` |
| Revenue per Session | `mart_growth_daily` |
| Revenue by Category / Brand | `mart_revenue_attribution` |
| A/B Experiment Results | `mart_experiment_results` |

---

## Tech Stack

| Tool | Role |
|---|---|
| Python | Data ingestion scripts, mart export |
| PostgreSQL | Raw and analytics warehouse |
| dbt Core | SQL transformations, testing, lineage |
| SQL | Core business logic |
| Tableau Public | Presentation layer |
| GitHub Actions | CI/CD — dbt parse and compile validation |
| Git / GitHub | Version control |

---

## Repository Structure

```
search_ads_growth_analytics_platform/
│
├── .github/
│   └── workflows/
│       ├── dbt_daily_run.yml
│       └── dbt_pr_check.yml
│
├── data/
│   └── processed/
│       └── tableau_exports/        # mart CSVs for Tableau
│
├── database/
│   └── setup scripts               # PostgreSQL schema setup
│
├── dbt_project/
│   ├── models/
│   │   ├── staging/                # stg_events
│   │   ├── facts/                  # fact_sessions, fact_funnel_steps, fact_conversions
│   │   ├── dimensions/             # dim_user, dim_date, dim_product
│   │   └── marts/                  # mart_growth_daily, mart_revenue_attribution, mart_experiment_results
│   ├── macros/
│   ├── analyses/
│   └── dbt_project.yml
│
├── dashboards/
│   ├── tableau/                    # packaged Tableau workbook
│   └── screenshots/
│
├── docs/
│   └── screenshots/
│
├── ingestion/
│   ├── config.py
│   ├── sync_product_dim_to_postgres.py
│   └── export_tableau_marts.py
│
├── logs/
├── notebooks/
├── reports/
├── requirements.txt
└── README.md
```

---

## How to Run

### 1. Clone the repository

```bash
git clone https://github.com/vinaypant33/search_ads_growth_analytics_platform.git
cd search_ads_growth_analytics_platform
```

### 2. Create and activate virtual environment

```bash
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Mac / Linux
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Load raw data into PostgreSQL

```bash
python -m ingestion.sync_product_dim_to_postgres
```

### 5. Run dbt

```bash
cd dbt_project
dbt debug      # verify warehouse connection
dbt build      # run all models + tests
```

### 6. Explore dbt documentation

```bash
dbt docs generate
dbt docs serve --port 8085
# open http://localhost:8085
```

### 7. Export marts for Tableau

```bash
# from project root
python -m ingestion.export_tableau_marts
# exports to → data/processed/tableau_exports/
```

### 8. Open Tableau dashboard

Open the packaged workbook from `dashboards/tableau/` and connect to the exported CSVs.

---

## Screenshots


### PostgreSQL Warehouse Layers
<p align="center">
  <img src="https://github.com/vinaypant33/search_ads_growth_analytics_platform/blob/main/database/er_diagrams/PG%20Admin%20Screenshot%20of%20Schemas.png" width="500"/>
</p>

### dbt Build Success
<p align="center">
  <img src="https://github.com/vinaypant33/search_ads_growth_analytics_platform/blob/main/database/er_diagrams/Raw%20Events.png" width="600"/>
</p>


### dbt Lineage Graph
<p align="center">
  <img src="https://github.com/vinaypant33/search_ads_growth_analytics_platform/blob/main/extra_files/Lineage%20Graph/Lineage%20Graph.png" width="600"/>
</p>


### Tableau Growth Overview Dashboard
<p align="center">
  <img src="https://github.com/vinaypant33/search_ads_growth_analytics_platform/blob/main/dashboards/screenshots/Dashbaord%20Screenshot.png" width="600"/>
</p>


---

## Design Decisions

**Why dbt instead of Tableau calculated fields?**

Business logic in dbt means version-controlled SQL, testable models, a lineage graph, and metrics that can be reused across any BI tool. Tableau calculated fields are invisible inside the workbook and cannot be tested or audited.

**Why no physical foreign key constraints in PostgreSQL?**

Analytical warehouses use logical relationships through dbt models, joins, and tests — not physical constraints. Models are rebuilt on each run; physical FKs would break incremental load patterns and are not standard in dbt-based workflows.

**Why export to CSV for Tableau?**

Tableau Public does not support live PostgreSQL connections. Mart exports replicate the extract-and-publish pattern used in production Tableau Server and Tableau Cloud setups.

**Why GitHub Actions?**

Two workflows — a PR check (dbt parse/compile) and a scheduled daily run — demonstrate how a production dbt pipeline would be automated and monitored without dbt Cloud.

---

## Future Improvements

- Add Airflow orchestration
- Add dbt Cloud scheduling
- Deploy to a cloud warehouse (BigQuery or Snowflake)
- Add retention cohort analysis
- Add incremental dbt models
- Add automated Tableau extract refresh
- Add experiment significance testing
- Add advanced product and category segmentation

