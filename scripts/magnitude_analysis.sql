/* ----------------------------------------------------------------------------
   Magnitude Analysis — totals broken down by dimension
   Project: Sales Analytics

   Why: this is the "where does the volume sit" pass — counts and totals grouped
   by country, gender, category, etc. I add a share-of-total column on the money
   questions, because "Bikes = 28M" means little until it's "Bikes = 28M (70%)".
---------------------------------------------------------------------------- */

-- 1. Customers by country — where my customer base actually is.
SELECT
    country,
    COUNT(customer_key) AS total_customers,
    CAST(100.0 * COUNT(customer_key) / SUM(COUNT(customer_key)) OVER () AS DECIMAL(5,2)) AS pct_of_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- 2. Customers by gender — note the 'n/a' bucket comes from my gold layer's
--    fallback when neither CRM nor ERP resolved a gender.
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- 3. Product count by category — how the catalogue is distributed.
SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- 4. Average cost per category. AVG ignores NULL cost, so this is the average
--    over products that actually have a cost recorded.
SELECT
    category,
    AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- 5. Revenue by category, with each category's share of total revenue — the
--    percentage is what turns this from a list into a finding.
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue,
    CAST(100.0 * SUM(f.sales_amount) / SUM(SUM(f.sales_amount)) OVER () AS DECIMAL(5,2)) AS pct_of_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 6. Top revenue-generating customers. Capped at top 20 — the full per-customer
--    list is thousands of rows and not useful to eyeball; ranking is the point.
SELECT TOP 20
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- 7. Units sold by country — volume distribution, to compare against the
--    revenue picture (high volume + low revenue = low-price market, and vice versa).
SELECT
    c.country,
    SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;
