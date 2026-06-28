/* ----------------------------------------------------------------------------
   Data Segmentation — grouping products and customers into meaningful tiers
   Project: Sales Analytics
 
   Why: averages hide structure. Segmenting turns a flat list into groups I can
   act on — which price tier holds most of the catalogue, how many customers are
   genuinely high-value vs one-off buyers.
 
   IMPORTANT — these thresholds are mine to set, not inherited defaults.
   The cost bands and the VIP spend cutoff below are tuned to THIS dataset's
   distribution (see the diagnostic queries), not copied from a tutorial. If the
   data is reloaded with a different range, I re-run the diagnostics and reset them.
---------------------------------------------------------------------------- */
 
-- ============================================================================
-- DIAGNOSTIC (run first, don't commit the output): where do my cutoffs belong?
-- I set the cost bands and the VIP spend line from these numbers, so the tiers
-- reflect real breakpoints in my data rather than round numbers picked blind.
-- ============================================================================
-- Product cost spread
SELECT
    MIN(cost) AS min_cost, MAX(cost) AS max_cost, AVG(cost) AS avg_cost,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY cost) OVER () AS p50_cost,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY cost) OVER () AS p90_cost
FROM gold.dim_products
WHERE cost IS NOT NULL;
 
-- Customer total-spend spread (the 80th pct is a sensible VIP line to consider)
SELECT
    MIN(total_spend) AS min_spend, MAX(total_spend) AS max_spend, AVG(total_spend) AS avg_spend,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_spend) OVER () AS p80_spend
FROM (
    SELECT customer_key, SUM(sales_amount) AS total_spend
    FROM gold.fact_sales GROUP BY customer_key
) s;
 
-- ============================================================================
-- 1) Products by cost band.
--    NOTE: bands are half-open [low, high) so boundaries don't double-count —
--    the original BETWEEN bands overlapped (cost = 500 matched two bands).
--    >>> Replace the 100 / 500 / 1000 below with breakpoints from the diagnostic.
-- ============================================================================
WITH product_segments AS (
    SELECT
        product_key,
        cost,
        CASE
            WHEN cost < 100               THEN 'Budget (<100)'
            WHEN cost < 500               THEN 'Mid (100-499)'
            WHEN cost < 1000              THEN 'Premium (500-999)'
            ELSE                               'High-end (1000+)'
        END AS cost_band
    FROM gold.dim_products
    WHERE cost IS NOT NULL          -- exclude products with no cost recorded
)
SELECT
    cost_band,
    COUNT(product_key) AS total_products,
    CAST(100.0 * COUNT(product_key) / SUM(COUNT(product_key)) OVER () AS DECIMAL(5,2)) AS pct_of_catalogue
FROM product_segments
GROUP BY cost_band
ORDER BY total_products DESC;
 
-- ============================================================================
-- 2) Customer value segments.
--    VIP     = established (12+ months active) AND high spend
--    Regular = established but spend below the VIP line
--    New     = less than 12 months between first and last order
--    >>> Set @vip_spend from the p80 figure in the diagnostic above.
-- ============================================================================
DECLARE @vip_spend INT = 5000;   -- <-- my chosen VIP threshold; justify with p80
DECLARE @tenure_months INT = 12; -- <-- my chosen "established" tenure
 
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount)                                   AS total_spending,
        DATEDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS lifespan_months
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
    GROUP BY c.customer_key
)
SELECT
    customer_segment,
    COUNT(customer_key)                                            AS total_customers,
    SUM(total_spending)                                           AS segment_revenue,
    CAST(AVG(total_spending) AS INT)                              AS avg_spend_per_customer
FROM (
    SELECT
        customer_key,
        total_spending,
        CASE
            WHEN lifespan_months >= @tenure_months AND total_spending > @vip_spend THEN 'VIP'
            WHEN lifespan_months >= @tenure_months                                 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
) segmented
GROUP BY customer_segment
ORDER BY segment_revenue DESC;
