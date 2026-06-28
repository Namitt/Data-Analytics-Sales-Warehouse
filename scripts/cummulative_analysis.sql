/* ----------------------------------------------------------------------------
   Cumulative Analysis — running totals and moving averages
   Project: Sales Analytics

   Why: the monthly trend shows each period in isolation; this accumulates it,
   so I can see total sales-to-date climb and judge whether growth is steady or
   stalling. I compute the monthly grain here (not yearly) so there are enough
   points for the running and moving views to actually be informative.

   Terminology I'm being deliberate about:
     - running total / running average = expanding window (all rows up to now)
     - moving average                  = fixed window (last N rows only)
   These are different things; I show both rather than conflate them.
---------------------------------------------------------------------------- */

WITH monthly_sales AS (
    SELECT
        DATETRUNC(month, order_date) AS order_month,
        SUM(sales_amount)            AS total_sales,
        AVG(price)                   AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(month, order_date)
)
SELECT
    order_month,
    total_sales,

    -- Running total: cumulative sales from the first month up to this one.
    SUM(total_sales) OVER (ORDER BY order_month)               AS running_total_sales,

    -- Running (expanding) average price: average across all months so far.
    AVG(avg_price) OVER (ORDER BY order_month)                 AS running_avg_price,

    -- True 3-month moving average price: only the current month and prior two,
    -- via an explicit frame. Smooths short-term noise without the whole history.
    AVG(avg_price) OVER (ORDER BY order_month
                         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_price_3m
FROM monthly_sales
ORDER BY order_month;
