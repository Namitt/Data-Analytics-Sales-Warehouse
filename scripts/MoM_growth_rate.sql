/* ----------------------------------------------------------------------------
   Month-over-Month Growth Rate
   Project: Sales Analytics
 
   Why this isn't in the core set: the cumulative script (08) shows running
   totals, and the YoY script (09) compares whole years. Neither gives the
   month-on-month growth RATE — the percentage swing from one month to the next,
   which is how you actually spot momentum and seasonality month to month.
   Uses LAG to reach the prior month and computes the % change.
---------------------------------------------------------------------------- */
 
WITH monthly AS (
    SELECT
        DATETRUNC(month, order_date) AS order_month,
        SUM(sales_amount)            AS total_sales,
        COUNT(DISTINCT order_number) AS total_orders
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(month, order_date)
)
SELECT
    order_month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY order_month) AS prev_month_sales,
    total_sales - LAG(total_sales) OVER (ORDER BY order_month) AS mom_change,
    -- MoM growth %. NULLIF guards a zero prior month; first month returns NULL
    -- (no prior to compare), which I leave as NULL rather than a fake 0%.
    CASE
        WHEN LAG(total_sales) OVER (ORDER BY order_month) IS NULL THEN NULL
        ELSE CAST(100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY order_month))
                  / NULLIF(LAG(total_sales) OVER (ORDER BY order_month), 0) AS DECIMAL(10,1))
    END AS mom_growth_pct,
    -- Plain-language flag for quick scanning.
    CASE
        WHEN LAG(total_sales) OVER (ORDER BY order_month) IS NULL THEN 'baseline'
        WHEN total_sales > LAG(total_sales) OVER (ORDER BY order_month) THEN 'up'
        WHEN total_sales < LAG(total_sales) OVER (ORDER BY order_month) THEN 'down'
        ELSE 'flat'
    END AS trend
FROM monthly
ORDER BY order_month;
GO
