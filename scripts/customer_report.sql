/* ----------------------------------------------------------------------------
   Customer Report  ->  gold.report_customers (view)
   Project: Sales Analytics
 
   What this is: a single reusable view that rolls the fact/dim tables up to one
   row per customer, so BI tools (Power BI / Tableau) can point at one clean
   object instead of re-deriving these metrics every time.
 
   Per customer it produces:
     - identity: key, number, name, age, age band, value segment
     - volume:   total orders, sales, quantity, distinct products, lifespan
     - KPIs:     recency, average order value, average monthly spend
 
   Thresholds (VIP spend, tenure) are mine and match the cutoffs I set in
   10_data_segmentation from this dataset's distribution — kept consistent so a
   "VIP" means the same thing across the project.
---------------------------------------------------------------------------- */
 
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO
 
CREATE VIEW gold.report_customers AS
 
WITH base_query AS (
    -- 1) Core columns, one row per order line. Guard birthdate so a NULL doesn't
    --    produce a misleading age, and skip rows with no order date.
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        CASE WHEN c.birthdate IS NULL THEN NULL
             ELSE DATEDIFF(YEAR, c.birthdate, GETDATE())
        END AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),
 
customer_aggregation AS (
    -- 2) Roll up to one row per customer.
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number)               AS total_orders,
        SUM(sales_amount)                          AS total_sales,
        SUM(quantity)                              AS total_quantity,
        COUNT(DISTINCT product_key)                AS total_products,
        MAX(order_date)                            AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY customer_key, customer_number, customer_name, age
)
 
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE
        WHEN age IS NULL          THEN 'Unknown'
        WHEN age < 20             THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12                        THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,
    -- Average order value. NULLIF guards divide-by-zero; *1.0 forces decimal so
    -- AOV isn't silently integer-truncated (the original used integer division).
    CASE WHEN total_orders = 0 THEN 0
         ELSE CAST(total_sales * 1.0 / NULLIF(total_orders, 0) AS DECIMAL(12,2))
    END AS avg_order_value,
    -- Average monthly spend. A 0-month lifespan (single-month customer) is
    -- treated as one month, so their whole spend lands in that month rather
    -- than dividing by zero.
    CASE WHEN lifespan = 0 THEN CAST(total_sales AS DECIMAL(12,2))
         ELSE CAST(total_sales * 1.0 / lifespan AS DECIMAL(12,2))
    END AS avg_monthly_spend
FROM customer_aggregation;
GO
