/* ----------------------------------------------------------------------------
   Category Affinity / Basket Analysis
   Project: Sales Analytics
 
   Why this isn't in the core set: nothing in the existing scripts looks at what
   customers buy TOGETHER. This is a light market-basket analysis — which pairs
   of product categories show up in the same order — the foundation of "customers
   who bought X also bought Y" and cross-sell decisions. It's a self-join of the
   fact table on order_number, which is a genuinely different technique from the
   group-by aggregations the rest of the project uses.
---------------------------------------------------------------------------- */
 
WITH order_categories AS (
    -- Distinct (order, category) pairs: I only care whether a category appears
    -- in an order, not how many lines of it, so DISTINCT collapses duplicates.
    SELECT DISTINCT
        f.order_number,
        p.category
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
      AND p.category IS NOT NULL
)
SELECT
    a.category AS category_a,
    b.category AS category_b,
    COUNT(*)   AS orders_with_both
FROM order_categories a
JOIN order_categories b
    ON a.order_number = b.order_number
   AND a.category < b.category     -- a<b avoids self-pairs and mirror duplicates
GROUP BY a.category, b.category
ORDER BY orders_with_both DESC;
GO
