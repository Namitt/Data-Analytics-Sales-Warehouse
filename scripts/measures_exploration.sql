/* ----------------------------------------------------------------------------
   Measures Exploration — headline business numbers
   Project: Sales Analytics (built on my data warehouse gold layer)

   Why: a single scorecard of the top-line measures before I slice anything.
   These totals are my reference point — if a later grouped query doesn't sum
   back to these, I know I've dropped or double-counted rows somewhere.

   Note on counting orders: the fact grain is order-line, so order_number
   repeats across a multi-item order. COUNT(DISTINCT order_number) is therefore
   the real order count; a plain COUNT would inflate it by line items.
---------------------------------------------------------------------------- */

-- Single consolidated KPI scorecard (one result set, easy to drop into a report
-- or BI tile) rather than eight separate one-line queries.
SELECT 'Total Sales'        AS measure_name, CAST(SUM(sales_amount) AS BIGINT) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity',    SUM(quantity)                          FROM gold.fact_sales
UNION ALL
SELECT 'Average Price',     AVG(price)                             FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders',      COUNT(DISTINCT order_number)           FROM gold.fact_sales
UNION ALL
SELECT 'Total Products',    COUNT(DISTINCT product_key)            FROM gold.dim_products
UNION ALL
SELECT 'Total Customers',   COUNT(customer_key)                    FROM gold.dim_customers
UNION ALL
SELECT 'Active Customers',  COUNT(DISTINCT customer_key)           FROM gold.fact_sales;
