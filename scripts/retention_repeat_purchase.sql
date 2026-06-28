/* ----------------------------------------------------------------------------
   Retention & Repeat-Purchase Analysis
   Project: Sales Analytics
 
   Why this isn't in the core set: every existing script measures revenue volume.
   None of them asks whether customers come BACK. A business with great sales but
   no repeat buyers is leaking — this surfaces that. I look at three things:
   what share of customers ever buy twice, how long until they do, and how the
   customer base splits into one-time vs loyal.
---------------------------------------------------------------------------- */
 
WITH customer_orders AS (
    SELECT
        customer_key,
        COUNT(DISTINCT order_number) AS order_count,
        MIN(order_date)              AS first_order,
        MAX(order_date)              AS last_order
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY customer_key
)
 
-- 1. Headline retention: what share of customers placed more than one order?
SELECT
    COUNT(*)                                                          AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)                  AS repeat_customers,
    CAST(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
              / COUNT(*) AS DECIMAL(5,2))                             AS repeat_rate_pct
FROM customer_orders;
GO
 
-- 2. Loyalty banding: group customers by how many orders they placed, so I can
--    see whether repeat business is broad or concentrated in a loyal few.
WITH customer_orders AS (
    SELECT customer_key, COUNT(DISTINCT order_number) AS order_count
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY customer_key
)
SELECT
    CASE
        WHEN order_count = 1      THEN '1 order (one-time)'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 orders'
        WHEN order_count BETWEEN 4 AND 6 THEN '4-6 orders'
        ELSE '7+ orders (loyal)'
    END AS loyalty_band,
    COUNT(*)                                                  AS customers,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct_of_base
FROM customer_orders
GROUP BY
    CASE
        WHEN order_count = 1      THEN '1 order (one-time)'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 orders'
        WHEN order_count BETWEEN 4 AND 6 THEN '4-6 orders'
        ELSE '7+ orders (loyal)'
    END
ORDER BY customers DESC;
GO
 
-- 3. Time-to-second-order: for customers who did come back, how many days passed
--    between their first and second order? A short gap = sticky product; a long
--    one = a re-engagement opportunity. Uses ROW_NUMBER to find each customer's
--    first two orders, then the gap between them.
WITH ranked_orders AS (
    SELECT
        customer_key,
        order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_key ORDER BY order_date) AS order_seq
    FROM (
        SELECT DISTINCT customer_key, order_number, order_date
        FROM gold.fact_sales
        WHERE order_date IS NOT NULL
    ) o
),
first_two AS (
    SELECT
        customer_key,
        MAX(CASE WHEN order_seq = 1 THEN order_date END) AS first_order,
        MAX(CASE WHEN order_seq = 2 THEN order_date END) AS second_order
    FROM ranked_orders
    WHERE order_seq <= 2
    GROUP BY customer_key
)
SELECT
    COUNT(second_order)                                              AS customers_with_2nd_order,
    AVG(DATEDIFF(DAY, first_order, second_order))                   AS avg_days_to_2nd_order,
    MIN(DATEDIFF(DAY, first_order, second_order))                   AS fastest_days,
    MAX(DATEDIFF(DAY, first_order, second_order))                   AS slowest_days
FROM first_two
WHERE second_order IS NOT NULL;
GO
