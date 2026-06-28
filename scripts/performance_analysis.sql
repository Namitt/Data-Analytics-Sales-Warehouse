/* ----------------------------------------------------------------------------
   Performance Analysis — year-over-year, and vs the product's own average
   Project: Sales Analytics

   Why: ranking shows who's on top now; this shows direction. For each product
   I compare a year's sales against (a) that product's average year — is this a
   strong or weak year for it — and (b) its previous year — is it growing or
   declining. Two different questions, so two separate benchmark columns.

   Note on YoY: LAG returns NULL for each product's first year (nothing prior to
   compare to), so those rows show 'n/a' rather than a fake 0% — a first year
   isn't a decline, it's just a baseline.
---------------------------------------------------------------------------- */

WITH yearly_product_sales AS (
    SELECT
        YEAR(f.order_date)  AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_name
),
benchmarked AS (
    -- Compute each window value once here, then label/percentage them below.
    SELECT
        order_year,
        product_name,
        current_sales,
        AVG(current_sales) OVER (PARTITION BY product_name)                       AS avg_sales,
        LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)   AS py_sales
    FROM yearly_product_sales
)
SELECT
    order_year,
    product_name,
    current_sales,

    -- Benchmark 1: this year vs the product's own average year.
    avg_sales,
    current_sales - avg_sales AS diff_avg,
    CASE
        WHEN current_sales > avg_sales THEN 'Above Avg'
        WHEN current_sales < avg_sales THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,

    -- Benchmark 2: this year vs the prior year (YoY).
    py_sales,
    current_sales - py_sales AS diff_py,
    -- YoY growth as a percentage, which is the number a stakeholder actually
    -- reads. NULLIF guards against divide-by-zero if a prior year was 0.
    CASE
        WHEN py_sales IS NULL THEN NULL
        ELSE CAST(100.0 * (current_sales - py_sales) / NULLIF(py_sales, 0) AS DECIMAL(10,1))
    END AS py_growth_pct,
    CASE
        WHEN py_sales IS NULL              THEN 'n/a (first year)'
        WHEN current_sales > py_sales      THEN 'Increase'
        WHEN current_sales < py_sales      THEN 'Decrease'
        ELSE 'No Change'
    END AS py_change
FROM benchmarked
ORDER BY product_name, order_year;
