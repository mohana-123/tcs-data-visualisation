-- -- create view online_retail as
-- select
-- 	InvoiceNo,
-- 	InvoiceDate,
-- 	CustomerID,
-- 	Country,
-- 	StockCode,
-- 	Quantity,
-- 	UnitPrice,
-- 	Quantity * UnitPrice as Revenue
-- from [Online Retail]
-- where Quantity > 0 and UnitPrice > 0;  -- 5,41,909 - 5,30,104 = 11,805 rows gone and filtered


-- In which region are your products are generating more revenue? =========================================================================

-- SELECT
--     Country,
--     ROUND(SUM(Revenue) , 2) AS Total_revenue
-- FROM online_retail
-- GROUP BY Country
-- ORDER BY Total_revenue DESC

-- Q2. Are there seasonal trends? ==========================================================================================================

-- SELECT
--     MONTH(InvoiceDate) as month_name,
--     ROUND(SUM(Revenue) , 2) AS Total_revenue
-- FROM online_retail
-- GROUP BY MONTH(InvoiceDate)
-- ORDER BY MONTH(InvoiceDate)


-- Q3. Are we dependent on top customers? ==============================================================================================

-- SELECT
--     CustomerID,
--     ROUND(SUM(Revenue) , 2) AS Total_revenue
-- FROM online_retail
-- GROUP BY CustomerID
-- ORDER BY Total_revenue DESC


WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(revenue) AS total_revenue
    FROM online_retail
    GROUP BY CustomerID
)
SELECT
    SUM(CASE WHEN rank_pct <= 0.2 THEN total_revenue END) 
        / SUM(total_revenue) AS top_20_percent_revenue_share
FROM (
    SELECT
        CustomerID,
        total_revenue,
        NTILE(5) OVER (ORDER BY total_revenue DESC) / 5.0 AS rank_pct
    FROM customer_revenue
) t;
