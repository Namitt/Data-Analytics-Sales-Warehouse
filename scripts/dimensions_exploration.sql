/* ----------------------------------------------------------------------------
   Dimensions Exploration — what's actually in my dimension tables
   Project: Sales Analytics (built on my data warehouse gold layer)

   Why: before grouping by country/category in later scripts, I want to know
   the distinct values each dimension holds and how clean they are. My gold
   views fall back to 'n/a' for unresolved gender/country, so I check for that
   here rather than being surprised by an 'n/a' bucket in a chart later.
---------------------------------------------------------------------------- */

-- 1. Distinct countries customers come from, with a count so I can see how many
--    markets I'm working across (not just the list).
SELECT
    country,
    COUNT(*) AS customers
FROM gold.dim_customers
GROUP BY country
ORDER BY customers DESC;

-- 2. The category > subcategory > product hierarchy. DISTINCT here confirms the
--    grain of dim_products is one row per product and shows how products roll up.
SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY category, subcategory, product_name;

-- 3. Data-quality check: how many customers have unresolved 'n/a' gender or
--    country from the gold layer's fallback logic? Tells me whether to filter
--    or call these out when I segment by demographic later.
SELECT
    SUM(CASE WHEN gender  = 'n/a' THEN 1 ELSE 0 END) AS na_gender,
    SUM(CASE WHEN country = 'n/a' THEN 1 ELSE 0 END) AS na_country
FROM gold.dim_customers;
