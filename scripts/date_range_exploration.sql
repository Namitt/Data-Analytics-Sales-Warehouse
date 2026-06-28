/* ----------------------------------------------------------------------------
   Date Range Exploration — the time span and age range I'm working with
   Project: Sales Analytics (built on my data warehouse gold layer)

   Why: every time-series and recency calculation downstream depends on knowing
   the data's date boundaries. I also sanity-check customer ages here, because
   birthdate comes from the ERP source via a left join in my dim_customers view,
   so missing or junk dates are possible and would skew any age analysis.
---------------------------------------------------------------------------- */

-- 1. Sales window: first and last order, and how long that span is. The year
--    count tells me at a glance whether year-over-year analysis is even viable
--    (need at least two full years for a meaningful YoY comparison).
SELECT
    MIN(order_date)                                   AS first_order_date,
    MAX(order_date)                                   AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months,
    DATEDIFF(YEAR,  MIN(order_date), MAX(order_date)) AS order_range_years
FROM gold.fact_sales;

-- 2. Customer age range. I filter out NULL birthdates so they don't show up as
--    a bogus "oldest" row, and flag anything implausible (age < 0 or > 100)
--    that would point to bad source data rather than a real customer.
SELECT
    MIN(birthdate)                                AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE())     AS oldest_age,
    MAX(birthdate)                                AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE())     AS youngest_age
FROM gold.dim_customers
WHERE birthdate IS NOT NULL;

-- 3. Birthdate quality check: count missing and implausible values up front so
--    I know whether age-based segmentation later needs a filter.
SELECT
    SUM(CASE WHEN birthdate IS NULL THEN 1 ELSE 0 END)                       AS missing_birthdate,
    SUM(CASE WHEN DATEDIFF(YEAR, birthdate, GETDATE()) > 100 THEN 1 ELSE 0 END) AS implausible_age
FROM gold.dim_customers;
