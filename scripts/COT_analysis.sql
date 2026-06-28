/* ----------------------------------------------------------------------------
   Change Over Time — monthly trend and seasonality
   Project: Sales Analytics

   Why: the first real time-series view. I use DATETRUNC to bucket by month
   because it keeps a true date type (so it sorts chronologically and charts
   cleanly), unlike FORMAT which returns a string that sorts alphabetically
   and would put April before January.
---------------------------------------------------------------------------- */

-- 1. Monthly performance trend: sales, active customers, and units per month.
--    DATETRUNC(month, ...) collapses each date to the first of its month and
--    keeps it as a date, so the chronological ORDER BY just works.
SELECT
    DATETRUNC(month, order_date)  AS order_month,
    SUM(sales_amount)             AS total_sales,
    COUNT(DISTINCT customer_key)  AS active_customers,
    SUM(quantity)                 AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY order_month;

-- 2. Seasonality: average sales for each calendar month pooled across all years.
--    This answers "are Decembers always strong?" rather than "how was Dec 2013?"
--    by collapsing the year and averaging the monthly totals per month number.
WITH monthly AS (
    SELECT
        YEAR(order_date)  AS yr,
        MONTH(order_date) AS mth,
        SUM(sales_amount) AS month_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT
    mth                         AS calendar_month,
    DATENAME(month, DATEFROMPARTS(2000, mth, 1)) AS month_name,
    AVG(month_sales)            AS avg_sales_for_month,
    COUNT(*)                    AS years_observed
FROM monthly
GROUP BY mth
ORDER BY calendar_month;
