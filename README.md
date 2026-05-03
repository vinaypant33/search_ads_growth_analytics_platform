# Search & Ads Growth Analytics Platform

<p align="center">
  <img src="https://img.shields.io/badge/Project-Analytics%20Engineering-black?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Data%20Warehouse-PostgreSQL-blue?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Transformations-dbt%20Core-orange?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Visualization-Tableau-blueviolet?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Automation-GitHub%20Actions-lightgrey?style=for-the-badge"/>
</p>

<p align="center">
  <b>End-to-end product analytics pipeline for e-commerce clickstream, growth, funnel, revenue, and experimentation analysis</b>
</p>

---

## Overview

This project is an **end-to-end analytics engineering platform** built for e-commerce clickstream and product growth analysis.

It follows a production-style analytics workflow where raw event data is ingested into PostgreSQL, transformed and tested using dbt Core, exported into Tableau-ready mart tables, and validated through GitHub Actions.

This is not just a dashboard project. The dashboard is only the final presentation layer. The main focus is on the **data pipeline, warehouse structure, reusable business logic, tested dbt models, and analytics-ready marts**.

---

## Problem Statement

Growth and product teams often depend on dashboards to monitor user behaviour, revenue, and funnel performance. However, dashboards alone do not guarantee that the underlying numbers are clean, consistent, reusable, or tested.

Common issues include:

* Business logic hidden inside BI tools
* No reusable metric layer
* No testing for core fields and assumptions
* No clear lineage from raw data to final dashboard
* Difficulty trusting funnel, conversion, and revenue metrics

This project solves that by building a structured analytics pipeline where business logic is handled in dbt before the data reaches Tableau.

The platform helps answer questions such as:

* How much revenue was generated, and how is it trending?
* How many users, sessions, and purchases occurred?
* How do users move from view → cart → purchase?
* How does conversion rate change over time?
* Which event types dominate user behaviour?
* Which product categories and brands drive revenue?
* How can experiment results be prepared for business analysis?

---

## Architecture

```text
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

## Data Flow

```text
Raw Clickstream CSV
        ↓
Python Ingestion Scripts
        ↓
PostgreSQL Raw Schema
        ↓
dbt Staging Models
        ↓
dbt Fact & Dimension Models
        ↓
dbt Mart Models
        ↓
Python Export Script
        ↓
Tableau Public Dashboard
        ↓
GitHub Actions CI Validation
```

---

## Tech Stack

| Layer | Tools |
|---|---|
| Data Source | Clickstream CSV, Product Master CSV |
| Ingestion | Python |
| Data Warehouse | PostgreSQL |
| Transformation | dbt Core |
| Business Logic | SQL |
| Testing | dbt tests |
| Visualization | Tableau Public |
| Automation / CI | GitHub Actions |
| Version Control | Git / GitHub |

---

## Data Warehouse Layers

### Raw Layer

Raw source data is loaded into PostgreSQL with minimal transformation. This keeps the original source data available for reprocessing and validation.

| Table | Description |
|---|---|
| `raw.raw_events` | Raw clickstream events such as view, cart, and purchase |
| `raw.product_dim` | Product master data synced from source |

---

### Staging Layer

The staging layer cleans and standardises raw event data for downstream models.

| Model | Key Transformations |
|---|---|
| `stg_events` | Timestamp parsing, event type normalisation, user/session field cleaning, product/category preparation |

---

### Fact Models

Fact models capture measurable business events at meaningful analytical grain.

| Model | Purpose | Grain |
|---|---|---|
| `fact_sessions` | Session-level user journey metrics | 1 row per session |
| `fact_funnel_steps` | Daily funnel movement and conversion metrics | 1 row per day per funnel step |
| `fact_conversions` | Purchase and revenue records | 1 row per purchase |

---

### Dimension Models

Dimension models provide descriptive context for slicing and filtering facts.

| Model | Purpose |
|---|---|
| `dim_user` | User profile and behaviour summary |
| `dim_date` | Calendar dimension for time-based slicing |
| `dim_product` | Product, category, and brand dimension |

---

### Mart Layer

Mart models are dashboard-ready aggregates. These are the only tables exported for Tableau.

| Mart | Contents |
|---|---|
| `mart_growth_daily` | Daily revenue, active users, sessions, purchases, conversion rate |
| `mart_revenue_attribution` | Revenue breakdown by category and brand |
| `mart_experiment_results` | Simulated A/B experiment outcomes |

---

## dbt Models

### Staging Example

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

---

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

Tests cover:

* Event IDs
* User IDs
* Session IDs
* Event types
* Conversion IDs
* Product IDs
* Date fields
* Mart-level metrics

---

## Key Metrics

All key metrics are calculated in dbt before Tableau reads the data. This keeps the dashboard lightweight and avoids hidden business logic inside Tableau calculated fields.

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

## Dashboard Highlights

* Revenue trend monitoring
* Active users, sessions, and purchases tracking
* View → cart → purchase funnel analysis
* Daily conversion rate analysis
* Revenue attribution by category and brand
* Experiment result preparation
* Tableau-ready mart exports

---

## Repository Structure

```text
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

## Automation and Validation

The project includes GitHub Actions workflows to simulate production-style validation.

### CI Workflow

```text
Pull Request / Code Change
        ↓
GitHub Actions
        ↓
dbt parse / compile validation
        ↓
Check whether dbt project is valid
```

### Scheduled Workflow

```text
Scheduled Trigger
        ↓
GitHub Actions
        ↓
dbt daily run workflow
        ↓
Pipeline validation
```

This demonstrates how dbt projects can be checked automatically before changes are merged or scheduled for regular execution.

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

### Raw Events Table

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

### Why dbt instead of Tableau calculated fields?

Business logic in dbt means version-controlled SQL, testable models, a lineage graph, and reusable metrics. Tableau is used only as the presentation layer.

This makes the project closer to a real analytics engineering workflow, where metrics are prepared before they reach the BI tool.

---

### Why no physical foreign key constraints in PostgreSQL?

In a dbt-based analytical warehouse, relationships are usually handled logically through models, joins, documentation, and tests.

Physical foreign keys are more common in transactional systems. Analytical models are often rebuilt, refreshed, or materialised through transformation pipelines, so dbt tests are used to validate relationships instead of enforcing every relationship physically in the database.

---

### Why export to CSV for Tableau?

Tableau Public does not support live PostgreSQL connections. Mart exports replicate an extract-based workflow where curated datasets are prepared and then consumed by the BI layer.

---

### Why GitHub Actions?

GitHub Actions adds automated validation to the project. The workflows show how dbt parsing, compilation, and scheduled checks can be integrated into a production-style analytics workflow without using dbt Cloud.

---

## Business Impact

This platform enables:

* Better visibility into product growth
* Clearer understanding of user behaviour
* Funnel performance monitoring
* Revenue attribution by category and brand
* Tested and reusable metrics
* Separation of business logic from dashboard design
* More reliable reporting for growth and product teams

---

## Project Highlights

* End-to-end analytics engineering pipeline
* PostgreSQL warehouse with raw, staging, fact, dimension, and mart layers
* dbt Core models for transformation, testing, and lineage
* Tableau dashboard connected to curated mart exports
* GitHub Actions for automated validation
* Business logic handled before the BI layer
* Built to reflect real-world product analytics workflows

---

## Future Improvements

* Add Airflow orchestration
* Add dbt Cloud scheduling
* Deploy to a cloud warehouse such as BigQuery or Snowflake
* Add retention cohort analysis
* Add incremental dbt models
* Add automated Tableau extract refresh
* Add experiment significance testing
* Add advanced product and category segmentation

---

## Final Note

This project is designed to show how product analytics can be built as a structured data system, not just as a dashboard.

It demonstrates how raw clickstream data can be ingested, transformed, tested, modelled, and delivered into a business-facing dashboard using a modern analytics engineering workflow.
