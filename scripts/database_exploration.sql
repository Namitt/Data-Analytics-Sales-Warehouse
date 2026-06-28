/* ----------------------------------------------------------------------------
   Database Exploration — structure & metadata checks
   Project: Sales Analytics

   Why this runs first: before any analysis I confirm the gold objects exist,
   check they're views over my silver layer (not standalone tables), and verify
   the columns are what I expect. Cheap to run, saves debugging a bad join later.
---------------------------------------------------------------------------- */

-- 1. List the gold-layer objects. I scope to the gold schema rather than dumping
--    every table in the database, and check TABLE_TYPE — I expect 'VIEW' for all
--    three, since my warehouse exposes gold as views over silver.
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_NAME;

-- 2. Inspect the column contract of dim_customers before I rely on it for joins
--    and grouping (country, gender, birthdate are the ones I use downstream).
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
  AND TABLE_NAME  = 'dim_customers'
ORDER BY ORDINAL_POSITION;

-- 3. Quick grain check on the fact table: one row should be one order line.
--    If order_number isn't unique on its own, the grain is order x product —
--    which tells me COUNT(DISTINCT order_number) is the right way to count
--    orders in every later script.
SELECT
    COUNT(*)                     AS fact_rows,
    COUNT(DISTINCT order_number) AS distinct_orders,
    COUNT(DISTINCT customer_key) AS distinct_customers
FROM gold.fact_sales;
