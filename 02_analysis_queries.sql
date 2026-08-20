
-- E-COMMERCE BUSINESS LOGIC & ANALYSIS QUERIES

-- REVENUE & SALES TRENDS — Month-over-Month Growth

WITH MoM_sales AS 
(
    SELECT 
        DATE_FORMAT(order_date,'%Y-%m') AS Monthly_sales,
        SUM(total_amount) AS Total_revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY DATE_FORMAT(order_date,'%Y-%m')
),
MoM_growth AS
(
    SELECT 
        Monthly_sales,
        Total_revenue,
        LAG(Total_revenue) OVER(ORDER BY Monthly_sales) AS Prev_month_revenue
    FROM MoM_sales
)
SELECT 
    Monthly_sales,
    Total_revenue,
    COALESCE(Prev_month_revenue,0) AS Prev_month_revenue,
    COALESCE(ROUND(100*(Total_revenue-Prev_month_revenue)/NULLIF(Prev_month_revenue,0),2),0) AS MoM_pct
FROM MoM_growth
ORDER BY Monthly_sales;

-- ==================================================================

-- REVENUE & SALES TRENDS — Quarter-over-Quarter Growth

WITH QoQ_revenue AS (
    SELECT 
        YEAR(order_date)                                    AS order_year,
        QUARTER(order_date)                                 AS order_quarter,
        CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS period_label,
        COUNT(order_id)                                     AS total_orders,
        SUM(total_amount)                                   AS total_revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY 
        YEAR(order_date),
        QUARTER(order_date),
        CONCAT(YEAR(order_date), '-Q', QUARTER(order_date))
), 
QoQ_growth AS (
    SELECT 
        period_label,
        total_orders,
        total_revenue,
        LAG(total_revenue) OVER (ORDER BY order_year, order_quarter) AS prev_quarter
    FROM QoQ_revenue
)
SELECT
    period_label,
    total_orders,
    total_revenue,
    COALESCE(prev_quarter, 0) AS prev_quarter,
    ROUND(
        COALESCE(100.0 * (total_revenue - prev_quarter) / NULLIF(prev_quarter, 0), 0), 
        2
    ) AS QoQ_pct
FROM QoQ_growth;  

-- ==================================================================

-- REVENUE & SALES TRENDS — Year-over-Year Growth

WITH YoY_revenue AS
(
	SELECT 
		YEAR(order_date) AS Order_year,
        SUM(total_amount) AS Total_revenue,
        COUNT(order_id) AS Total_orders
	FROM Orders
    WHERE Order_status = 'Delivered'
    GROUP BY YEAR(order_date)
), YoY_growth AS
(
	SELECT
		Order_year,
        Total_revenue,
        Total_orders,
        COALESCE(LAG(Total_revenue) OVER (ORDER BY Order_year),0) AS Prev_year
	FROM YoY_revenue
)
	SELECT 
		Order_year,
        Total_revenue,
        Total_orders,
        Prev_year,
        ROUND(COALESCE(100*(Total_revenue-Prev_year)/NULLIF(Prev_year,0),0),2) AS YoY_pct
	FROM YoY_growth; 

-- ==================================================================

-- CUSTOMER VALUE — CLV Ranking

SELECT 
	C.customer_id,
    C.customer_name,
    COUNT(DISTINCT O.Order_id) AS Total_orders,
	SUM(O.total_Amount) AS Total_spent,
    ROUND(SUM(O.total_Amount) / COUNT(DISTINCT O.Order_id), 2) AS avg_order_value,
    RANK() OVER (ORDER BY SUM(O.total_Amount) DESC) AS clv_rank
    FROM Customers C
    JOIN Orders O
    ON C.customer_id = O.customer_id
WHERE O.order_status = 'Delivered'
GROUP BY C.customer_id,C.customer_name
ORDER BY SUM(O.total_Amount) DESC;

-- ==================================================================

-- PRODUCT PERFORMANCE — Revenue Leakage (cancellations & returns)

WITH product_leakage AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        SUM(o.total_amount) AS gross_revenue,
        SUM(CASE WHEN o.order_status = 'Delivered' THEN o.total_amount ELSE 0 END) AS net_revenue,
        SUM(CASE WHEN o.order_status = 'Cancelled' THEN o.total_amount ELSE 0 END) AS cancelled_revenue,
        SUM(CASE WHEN o.order_status = 'Returned'  THEN o.total_amount ELSE 0 END) AS returned_revenue,
        COUNT(CASE WHEN o.order_status = 'Cancelled' THEN 1 END) AS cancelled_orders,
        COUNT(CASE WHEN o.order_status = 'Returned'  THEN 1 END) AS returned_orders,
        COUNT(*) AS total_orders
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT 
    product_id,
    product_name,
    category,
    total_orders,
    gross_revenue,
    net_revenue,
    cancelled_revenue,
    returned_revenue,
    (cancelled_revenue + returned_revenue) AS total_leakage,
    ROUND(100 * cancelled_revenue / NULLIF(gross_revenue,0), 2) AS cancellation_pct,
    ROUND(100 * returned_revenue  / NULLIF(gross_revenue,0), 2) AS return_pct,
    ROUND(100 * (cancelled_revenue + returned_revenue) / NULLIF(gross_revenue,0), 2) AS total_leakage_pct,
    RANK() OVER (ORDER BY (cancelled_revenue + returned_revenue) DESC) AS leakage_rank
FROM product_leakage
WHERE gross_revenue > 0
ORDER BY total_leakage DESC;

-- ==================================================================

-- RETENTION — New vs Repeat Customer Revenue Split (by month)

WITH first_order AS (
    SELECT 
    customer_id, 
    MIN(order_date) AS first_order_date
    FROM Orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    DATE_FORMAT(O.order_date, '%Y-%m') AS order_month,
    CASE
        WHEN DATE_FORMAT(O.order_date, '%Y-%m') = DATE_FORMAT(F.first_order_date, '%Y-%m') THEN 'New' 
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(DISTINCT O.customer_id) AS customers,
    SUM(O.total_Amount)           AS revenue
FROM Orders O
JOIN first_order F ON O.customer_id = F.customer_id
WHERE O.order_status = 'Delivered'
GROUP BY order_month, customer_type
ORDER BY order_month, customer_type;

-- ==================================================================

--  RETENTION — Churn Flag (days since last order)

SELECT
    C.customer_id,
    C.customer_name,
    MAX(O.order_date)                          AS last_order_date,
    DATEDIFF(CURDATE(), MAX(O.order_date))     AS days_since_last_order
FROM Customers C
JOIN Orders O ON C.customer_id = O.customer_id
GROUP BY C.customer_id, C.customer_name
ORDER BY DATEDIFF(CURDATE(), MAX(O.order_date)) DESC;

-- ==================================================================

-- CUSTOMER REVENUE BY COUNTRY & DEMOGRAPHICS

SELECT
    C.country,
    C.gender,
    C.age_group,
    COUNT(DISTINCT C.customer_id) AS customers,
    SUM(O.total_Amount) AS total_revenue,
    ROUND(SUM(O.total_Amount) / COUNT(DISTINCT C.customer_id), 2) AS avg_revenue_per_customer
FROM Customers C
JOIN Orders O ON C.customer_id = O.customer_id
WHERE O.order_status = 'Delivered'
GROUP BY C.country, C.gender, C.age_group
ORDER BY total_revenue DESC;

-- ==================================================================

-- COHORT ANALYSIS — Customer Retention Rate by Cohort Month

WITH cohort_base AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS cohort_month
    FROM orders
    GROUP BY customer_id
),
cohort_data AS (
    SELECT
        o.customer_id,
        cb.cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS order_month,
        TIMESTAMPDIFF(
            MONTH,
            cb.cohort_month,
            DATE_FORMAT(o.order_date, '%Y-%m-01')
        ) AS period_number
    FROM orders o
    JOIN cohort_base cb
        ON o.customer_id = cb.customer_id
),
cohort_counts AS (
    SELECT
        cohort_month,
        period_number,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_data
    GROUP BY cohort_month, period_number
),
cohort_size AS (
    SELECT
        cohort_month,
        active_customers AS num_customers
    FROM cohort_counts
    WHERE period_number = 0
)
SELECT
    cc.cohort_month,
    cc.period_number,
    cs.num_customers        AS cohort_size,
    cc.active_customers,
    ROUND(cc.active_customers / cs.num_customers * 100, 2) AS retention_rate_pct
FROM cohort_counts cc
JOIN cohort_size cs
    ON cc.cohort_month = cs.cohort_month
ORDER BY cc.cohort_month, cc.period_number;

-- ==================================================================

-- COHORT ANALYSIS — Revenue-Based Cohort View

WITH cohort_base AS (
    SELECT customer_id, DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS cohort_month
    FROM orders
    GROUP BY customer_id
)
SELECT
    cb.cohort_month,
    ROUND(SUM(o.total_amount), 2) AS total_cohort_revenue,
    COUNT(DISTINCT o.customer_id) AS total_active_customers,
    ROUND(SUM(o.total_amount) / COUNT(DISTINCT o.customer_id), 2) AS avg_revenue_per_customer
FROM orders o
JOIN cohort_base cb ON o.customer_id = cb.customer_id
GROUP BY cb.cohort_month
ORDER BY cb.cohort_month;

-- ==================================================================
