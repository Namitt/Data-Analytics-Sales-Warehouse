# SQL Data Analytics — Sales Warehouse
 
An end-to-end SQL analytics layer built on top of my [data warehouse project](https://github.com/Namitt/data-warehouse-project). It takes the curated `gold` star-schema (customers, products, sales) produced by that warehouse and runs a full analytical workflow on it, from database exploration and trend analysis through customer/product segmentation, RFM scoring, retention, and two production-style reporting views.
 
The goal is to show the *analysis* half of the data lifecycle: once clean, modelled data exists, how do you interrogate it to answer real business questions about revenue, growth, retention, and customer value?
 
## Data source
 
This project consumes the output of my data warehouse, which handles ingestion, cleansing, and dimensional modelling (bronze → silver → gold). This repo picks up at the `gold` layer:
 
| Object | Grain | Key columns |
| :--- | :--- | :--- |
| `gold.dim_customers` | One row per customer | customer_key, country, gender, birthdate |
| `gold.dim_products` | One row per product | product_key, category, subcategory, cost |
| `gold.fact_sales` | One row per order line | order_number, order_date, sales_amount, quantity, price |
 
In the warehouse these are views over the silver layer. `00_init_database.sql` provides a standalone bootstrap that recreates the same `gold` schema as tables loaded from CSV exports, so the analytics scripts can also be run independently of the full warehouse pipeline.
 
## Project structure
 
Scripts are numbered to run as a progressive workflow.
 
**Exploration (01–04)**
- `01_database_exploration.sql` — inspect gold objects and columns via `INFORMATION_SCHEMA`; grain check on the fact table
- `02_dimensions_exploration.sql` — distinct dimension values with counts; `'n/a'` data-quality check
- `03_date_range_exploration.sql` — temporal boundaries and customer age range, with birthdate quality checks
- `04_measures_exploration.sql` — consolidated KPI scorecard (sales, quantity, orders, customers)
**Advanced analysis (05–11)**
- `05_magnitude_analysis.sql` — totals by dimension, with share-of-total percentages
- `06_ranking_analysis.sql` — top/bottom performers using `RANK`, `ROW_NUMBER`, and `TOP`
- `07_change_over_time_analysis.sql` — monthly trend and cross-year seasonality
- `08_cumulative_analysis.sql` — running totals and a true moving average
- `09_performance_analysis.sql` — year-over-year and vs-average benchmarking with `LAG`
- `10_data_segmentation.sql` — cost bands and customer value segments (data-driven thresholds)
- `11_part_to_whole_analysis.sql` — category and country contribution, read as a Pareto view
**Reporting views (12–13)**
- `12_report_customers.sql` — `gold.report_customers`: one row per customer with segments, age groups, and KPIs
- `13_report_products.sql` — `gold.report_products`: one row per product with performance tiers and KPIs
**My extensions (14–17)** — new analyses not in the original material
- `14_retention_repeat_purchase.sql` — repeat-purchase rate, loyalty banding, time-to-second-order
- `15_rfm_segmentation.sql` — Recency/Frequency/Monetary scoring with `NTILE(5)` into actionable segments
- `16_mom_growth_rate.sql` — month-over-month growth rate via `LAG`
- `17_basket_affinity.sql` — category co-purchase analysis via a self-join on order
## Techniques demonstrated
 
Aggregations and grouping, multi-table joins across a star schema, window functions (`RANK`, `ROW_NUMBER`, `NTILE`, `LAG`, `SUM/AVG OVER` with and without frames), date/time functions, conditional logic with `CASE`, CTEs for readable multi-step queries, a self-join for basket analysis, and reusable reporting views.
 
## How to run
 
1. Stand up the `gold` schema — either by running my [data warehouse project](https://github.com/Namitt/data-warehouse-project) end to end, or by running `00_init_database.sql` and pointing its `BULK INSERT` paths at your local CSV exports.
2. Run scripts `01` → `17` in order in SQL Server Management Studio.
3. Query the two views (`gold.report_customers`, `gold.report_products`) directly, or point Power BI / Tableau at them as a reporting source.
> Built and tested on Microsoft SQL Server (T-SQL). Uses functions including `DATETRUNC` and `PERCENTILE_CONT` that require a recent SQL Server version (2022+ for `DATETRUNC`).
 
## A note on thresholds
 
Segmentation cutoffs (VIP spend, product performance tiers, RFM boundaries) are tuned to this dataset's actual distribution rather than carried over as defaults — `10_data_segmentation.sql` includes the percentile diagnostics used to set them. If the underlying data is reloaded with a different range, re-run those diagnostics and reset the thresholds.
 
## Tech stack
 
SQL Server · T-SQL · SSMS · star-schema dimensional model
