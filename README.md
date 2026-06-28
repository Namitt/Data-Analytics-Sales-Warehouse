# SQL Data Analytics: Sales Warehouse
 
An end-to-end SQL analytics layer built on top of my data warehouse project. It takes the curated `gold` star-schema (customers, products, and sales) produced by that warehouse and runs a full analytical workflow on it, from database exploration through to two production-style reporting views for customers and products.
 
The goal is to show the analysis half of the data lifecycle: once clean, modelled data exists, how do you actually interrogate it to answer business questions about revenue, growth, segmentation, and performance?
 
## Background & credit
 
The structure of this project is adapted from Baraa Khatib Salkini's SQL data analytics course, which I used as a learning scaffold. I've since rebuilt it on the `gold`-layer dataset from (https://github.com/Namitt/data-warehouse-project), reworked the queries, and extended the analysis. Credit to Baraa for the original teaching material that got me started.
 
## Data source
 
This project does **not** build its own tables from scratch in the long run — it consumes the output of my data warehouse project. That warehouse handles the ingestion, cleansing, and dimensional modelling (bronze → silver → gold); this repo picks up at the `gold` layer:
 
| Object | Grain | Key columns |
| :--- | :--- | :--- |
| `gold.dim_customers` | One row per customer | customer_key, country, gender, birthdate |
| `gold.dim_products` | One row per product | product_key, category, subcategory, cost |
| `gold.fact_sales` | One row per order line | order_number, order_date, sales_amount, quantity, price |
 
`00_init_database.sql` provides a standalone bootstrap (create database, schema, tables, and bulk-load CSVs) so the scripts can also be run independently of the warehouse if needed.
 
## Project structure
 
The scripts are numbered to run as a progressive workflow — exploration first, then increasingly advanced analysis, then reporting.
 
**Exploration (01–04)**
- `01_database_exploration.sql` — inspect tables and columns via `INFORMATION_SCHEMA`
- `02_dimensions_exploration.sql` — list distinct dimension values (countries, categories)
- `03_date_range_exploration.sql` — temporal boundaries of the data and customer age range
- `04_measures_exploration.sql` — headline business measures (total sales, quantity, orders, etc.)
**Advanced analysis (05–11)**
- `05_magnitude_analysis.sql` — aggregate metrics grouped by dimension (sales by category, customers by country)
- `06_ranking_analysis.sql` — top/bottom performers using `TOP`, `RANK()`, and window functions
- `07_change_over_time_analysis.sql` — trends over time with `DATEPART`, `DATETRUNC`, `FORMAT`
- `08_cumulative_analysis.sql` — running totals and moving averages via window functions
- `09_performance_analysis.sql` — year-over-year and vs-average comparisons using `LAG()` and `CASE`
- `10_data_segmentation.sql` — custom cost bands and VIP/Regular/New customer segments
- `11_part_to_whole_analysis.sql` — category contribution as a percentage of overall sales
**Reporting views (12–13)**
- `12_report_customers.sql` — `gold.report_customers` view: consolidated customer metrics, segments, age groups, and KPIs (recency, average order value, average monthly spend)
- `13_report_products.sql` — `gold.report_products` view: consolidated product metrics, performance tiers, and KPIs (recency, average order revenue, average monthly revenue)
## Analytical techniques demonstrated
 
Aggregations and grouping, multi-table joins across a star schema, window functions (`RANK`, `ROW_NUMBER`, `SUM() OVER`, `AVG() OVER`, `LAG`), date/time functions, conditional logic with `CASE`, CTEs for readable multi-step queries, subqueries, and reusable reporting views.
 
## How to run
 
1. Stand up the `gold` schema — either by running (https://github.com/Namitt/data-warehouse-project) end to end, or by running `00_init_database.sql` and pointing the `BULK INSERT` paths at your local CSV copies.
2. Run scripts `01` → `13` in order in SQL Server Management Studio (T-SQL / SQL Server syntax).
3. Query the two views (`gold.report_customers`, `gold.report_products`) directly, or point Power BI / Tableau at them as a reporting source.
> Built and tested on Microsoft SQL Server (T-SQL). Some functions (`DATETRUNC`, `FORMAT`) require SQL Server 2022 / a recent version.
 
## Tech stack
 
SQL Server · T-SQL · SSMS · star-schema dimensional model
