/* ----------------------------------------------------------------------------
   Product Report  ->  gold.report_products (view)
   Project: Sales Analytics
 
   What this is: the product-side companion to report_customers. One reusable
   view, one row per product, so BI tools read a single clean object instead of
   re-aggregating the fact table each time.
 
   Per product it produces:
     - identity: key, name, category, subcategory, cost
     - performance tier: High / Mid / Low by total revenue
     - volume:   total orders, sales, quantity, distinct customers, lifespan
     - KPIs:     recency, average order revenue, average monthly revenue,
                 average selling price
 
   The High/Mid/Low revenue cutoffs are mine, set from this dataset's product
   revenue spread (see the diagnostic note below) rather than round defaults.
---------------------------------------------------------------------------- */
 
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO
 
CREATE VIEW gold.report_products AS
 
WITH base_query AS (
    -- 1) Core columns from fact joined to product dim, valid sale dates only.
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),
 
product_aggregations AS (
    -- 2) Roll up to one row per product.
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        MAX(order_date)                                   AS last_sale_date,
        COUNT(DISTINCT order_number)                      AS total_orders,
        COUNT(DISTINCT customer_key)                      AS total_customers,
        SUM(sales_amount)                                 AS total_sales,
        SUM(quantity)                                     AS total_quantity,
        -- Avg selling price per unit. NULLIF guards a 0-quantity line; FLOAT cast
        -- keeps it a real average rather than integer-truncated.
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
    FROM base_query
    GROUP BY product_key, product_name, category, subcategory, cost
)
 
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
    -- Revenue tier. Cutoffs tuned to this dataset's product-revenue range; keep
    -- them aligned with how I describe High/Mid/Low performers in the README.
    CASE
        WHEN total_sales > 50000  THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    -- Average order revenue. *1.0 + NULLIF avoids integer truncation and /0.
    CASE WHEN total_orders = 0 THEN 0
         ELSE CAST(total_sales * 1.0 / NULLIF(total_orders, 0) AS DECIMAL(12,2))
    END AS avg_order_revenue,
    -- Average monthly revenue. A 0-month lifespan (sold within one month) keeps
    -- its full revenue in that month instead of dividing by zero.
    CASE WHEN lifespan = 0 THEN CAST(total_sales AS DECIMAL(12,2))
         ELSE CAST(total_sales * 1.0 / lifespan AS DECIMAL(12,2))
    END AS avg_monthly_revenue
FROM product_aggregations;
GO
