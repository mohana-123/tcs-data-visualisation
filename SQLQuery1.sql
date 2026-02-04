-- DROP VIEW IF EXISTS dbo.online_retail;

-- create view online_retail as
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
-- where Quantity > 0 and UnitPrice > 0        -- 5,41,909 - 5,30,104 = 11,805 rows gone and filtered
--       AND InvoiceDate NOT BETWEEN '2010-12-01' AND '2010-12-31';        -- 488624


-- Q1. In which region are your products are generating more revenue? =========================================================================

-- SELECT
--     Country,
--     ROUND(SUM(Revenue) , 2) AS Total_revenue
-- FROM online_retail
-- GROUP BY Country
-- ORDER BY Total_revenue DESC

-- Revenue concentration risk
-- Expansion-friendly regions



-- Q2. Are there seasonal trends? ==========================================================================================================
SELECT
    month_name,
    Total_revenue,
    CASE WHEN Total_revenue <= AVG(Total_revenue) OVER() THEN 'organic growth'
         ELSE 'Holiday spikes'
    END AS flag_revenue
FROM
(
SELECT
    DATENAME(MONTH, InvoiceDate) as month_name,
    COUNT(CustomerID) Customer_count,
    ROUND(SUM(Revenue) , 2) AS Total_revenue
FROM online_retail
GROUP BY DATENAME(MONTH, InvoiceDate)
)t


-- Q3. Are we dependent on top customers? ==============================================================================================

-- WITH customer_revenue AS (
--     SELECT
--         CustomerID,
--         SUM(Revenue) AS total_revenue
--     FROM online_retail
--     GROUP BY CustomerID
--     ORDER BY CustomerID
--     OFFSET 1 ROW
-- )
-- SELECT
--     ROUND(SUM(CASE WHEN rank_pct <= 0.2 THEN total_revenue END) / SUM(total_revenue) , 2) AS top_20_percent_revenue_share
-- FROM (
--     SELECT
--         CustomerID,
--         total_revenue,
--         NTILE(5) OVER (ORDER BY total_revenue DESC) / 5.0 AS rank_pct
--     FROM customer_revenue
-- ) t;


-- Q4. Which months generate the lowest revenue?

-- SELECT
--     DATENAME(MONTH, InvoiceDate) as MONTH_name,
--     ROUND(SUM(Revenue), 2) as Revenue
-- FROM online_retail
-- WHERE InvoiceDate NOT BETWEEN '2010-12-01' AND '2010-12-31'
-- GROUP BY DATENAME(MONTH, InvoiceDate)
-- ORDER BY SUM(Revenue) ASC