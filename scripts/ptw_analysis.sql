/* ----------------------------------------------------------------------------
   Part-to-Whole Analysis — what share each slice contributes to the total
   Project: Sales Analytics
   Why: ranking tells me the order; this tells me the concentration. The useful
   question isn't "which category is biggest" but "do a few categories carry
   most of the revenue?" — so I add a cumulative share column to read it as a
   Pareto (80/20) view, not just a list of percentages.
---------------------------------------------------------------------------- */

-- 1. Category contribution to total sales, with a running cumulative share so I
--    can see how few categories it takes to reach ~80% of revenue.
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    CAST(100.0 * total_sales / SUM(total_sales) OVER () AS DECIMAL(5,2)) AS pct_of_total,
    CAST(100.0 * SUM(total_sales) OVER (ORDER BY total_sales DESC)
                / SUM(total_sales) OVER () AS DECIMAL(5,2))             AS cumulative_pct
FROM category_sales
ORDER BY total_sales DESC;

-- 2. Same lens on geography: each country's share of total revenue. Shows how
--    concentrated the business is on its top markets vs spread across many.
WITH country_sales AS (
    SELECT
        c.country,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    GROUP BY c.country
)
SELECT
    country,
    total_sales,
    CAST(100.0 * total_sales / SUM(total_sales) OVER () AS DECIMAL(5,2)) AS pct_of_total,
    CAST(100.0 * SUM(total_sales) OVER (ORDER BY total_sales DESC)
                / SUM(total_sales) OVER () AS DECIMAL(5,2))             AS cumulative_pct
FROM country_sales
ORDER BY total_sales DESC;
