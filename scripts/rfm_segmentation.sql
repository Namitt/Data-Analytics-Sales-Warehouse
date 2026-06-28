/* ----------------------------------------------------------------------------
   RFM Segmentation (Recency, Frequency, Monetary)
   Project: Sales Analytics
 
   Why this isn't in the core set: the existing customer_segment is one rule
   (tenure + spend). RFM is the standard marketing-analytics framework — it
   scores each customer 1-5 on three independent axes and combines them into
   actionable groups (Champions, At-Risk, Lost, etc). This is the kind of
   segmentation a real CRM/growth team uses, and it's entirely my addition.
 
   Method: NTILE(5) buckets customers into fifths on each axis. Recency is
   reverse-scored (more recent = better = 5). I anchor recency to the latest
   order in the data, not GETDATE(), so the historical dataset doesn't make
   everyone look equally stale.
---------------------------------------------------------------------------- */
 
WITH customer_rfm AS (
    SELECT
        customer_key,
        DATEDIFF(DAY, MAX(order_date),
                 (SELECT MAX(order_date) FROM gold.fact_sales)) AS recency_days,
        COUNT(DISTINCT order_number)                            AS frequency,
        SUM(sales_amount)                                       AS monetary
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY customer_key
),
rfm_scored AS (
    SELECT
        customer_key,
        recency_days,
        frequency,
        monetary,
        -- Recency reversed: smallest gap gets the top score of 5.
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
    FROM customer_rfm
)
SELECT
    customer_key,
    recency_days,
    frequency,
    monetary,
    r_score, f_score, m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_cell,
    -- Map score combinations to plain-language segments a team can act on.
    CASE
        WHEN r_score >= 4 AND f_score >= 4              THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 2              THEN 'Loyal'
        WHEN r_score >= 4 AND f_score = 1              THEN 'New / Promising'
        WHEN r_score BETWEEN 2 AND 3 AND f_score >= 3   THEN 'Needs Attention'
        WHEN r_score <= 2 AND f_score >= 4              THEN 'At Risk (was loyal)'
        WHEN r_score <= 2 AND f_score <= 2              THEN 'Lost / Dormant'
        ELSE 'Other'
    END AS rfm_segment
FROM rfm_scored
ORDER BY monetary DESC;
GO
 
-- Roll-up: how many customers and how much revenue sit in each RFM segment.
-- This is the version you'd actually put in front of someone.
WITH customer_rfm AS (
    SELECT
        customer_key,
        DATEDIFF(DAY, MAX(order_date),
                 (SELECT MAX(order_date) FROM gold.fact_sales)) AS recency_days,
        COUNT(DISTINCT order_number)                            AS frequency,
        SUM(sales_amount)                                       AS monetary
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY customer_key
),
rfm_scored AS (
    SELECT
        customer_key, monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score
    FROM customer_rfm
)
SELECT
    CASE
        WHEN r_score >= 4 AND f_score >= 4            THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 2            THEN 'Loyal'
        WHEN r_score >= 4 AND f_score = 1            THEN 'New / Promising'
        WHEN r_score BETWEEN 2 AND 3 AND f_score >= 3 THEN 'Needs Attention'
        WHEN r_score <= 2 AND f_score >= 4            THEN 'At Risk (was loyal)'
        WHEN r_score <= 2 AND f_score <= 2            THEN 'Lost / Dormant'
        ELSE 'Other'
    END AS rfm_segment,
    COUNT(*)        AS customers,
    SUM(monetary)   AS segment_revenue
FROM rfm_scored
GROUP BY
    CASE
        WHEN r_score >= 4 AND f_score >= 4            THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 2            THEN 'Loyal'
        WHEN r_score >= 4 AND f_score = 1            THEN 'New / Promising'
        WHEN r_score BETWEEN 2 AND 3 AND f_score >= 3 THEN 'Needs Attention'
        WHEN r_score <= 2 AND f_score >= 4            THEN 'At Risk (was loyal)'
        WHEN r_score <= 2 AND f_score <= 2            THEN 'Lost / Dormant'
        ELSE 'Other'
    END
ORDER BY segment_revenue DESC;
GO
