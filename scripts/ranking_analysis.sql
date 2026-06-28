/* ----------------------------------------------------------------------------
   Ranking Analysis — top and bottom performers
   Project: Sales Analytics

   Why: magnitude analysis showed the totals; this ranks them to surface the
   handful of products and customers that matter most (and the laggards worth
   investigating). I use a window function rather than TOP where ties matter,
   because TOP 5 silently cuts mid-tie whereas RANK() keeps tied items together.
---------------------------------------------------------------------------- */

-- 1. Top 5 products by revenue, ranked with RANK() so that if products tie on
--    revenue they share a rank and none is arbitrarily dropped at the cutoff.
--    DENSE_RANK would close the gaps; I want true ranking, hence RANK.
SELECT product_name, total_revenue, revenue_rank
FROM (
    SELECT
        p.product_name,
        SUM(f.sales_amount)                              AS total_revenue,
        RANK() OVER (ORDER BY SUM(f.sales_amount) DESC)  AS revenue_rank
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.product_name
) ranked
WHERE revenue_rank <= 5
ORDER BY revenue_rank;

-- 2. Bottom 5 products by revenue — the under-performers. I exclude products
--    with zero/NULL revenue first, because a product that never sold is a
--    different problem (catalogue/availability) from one that sells poorly.
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
HAVING SUM(f.sales_amount) > 0
ORDER BY total_revenue ASC;

-- 3. Top 10 customers by revenue — the accounts
