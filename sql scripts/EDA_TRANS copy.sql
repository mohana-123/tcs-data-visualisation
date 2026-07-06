-- the process of cleaning the raw tables ####################################################################################################
-- The original table cotnains 541909 rows
-- SELECT * FROM Online_Retail


-- Remove Exact duplicates => 4879 rows

-- SELECT *, COUNT(*)
-- FROM Online_Retail
-- GROUP BY InvoiceNo, StockCode, [Description], Quantity, InvoiceDate, UnitPrice, CustomerID, Country
-- HAVING COUNT(*) > 1


-- Handle cancelled and negetive quantity and unitprice values transactions

-- SELECT * 
-- FROM 
-- Online_Retail
-- WHERE Quantity <= 0 OR UnitPrice <= 0
-- AND InvoiceNo LIKE 'C%'
-- AND InvoiceNo LIKE 'A%'

-- 9288
-- 10624
-- 11803

-- DROP TABLE retail_clean_with_nulls;


-- -- with nulls in customer_id column
-- SELECT 
--     DISTINCT *, 
--     Quantity*UnitPrice AS Revenue,
--     MONTH(InvoiceDate) AS InvoiceMonth,
--     YEAR(InvoiceDate) AS InvoiceYear
-- INTO retail_clean_with_nulls
-- FROM online_retail
-- WHERE InvoiceNo NOT LIKE 'C%'
-- AND InvoiceNo NOT LIKE 'A%'
-- AND Quantity >= 0
-- AND UnitPrice >= 0
-- ORDER BY InvoiceDate



-- -- without nulls in customer_id column
-- SELECT 
--     DISTINCT *, 
--     Quantity*UnitPrice AS Revenue,
--     MONTH(InvoiceDate) AS InvoiceMonth,
--     YEAR(InvoiceDate) AS InvoiceYear
-- INTO retail_clean_with_out_nulls
-- FROM online_retail
-- WHERE InvoiceNo NOT LIKE 'C%'
-- AND InvoiceNo NOT LIKE 'A%'
-- AND Quantity >= 0
-- AND UnitPrice >= 0
-- AND CustomerID IS NOT NULL
-- ORDER BY InvoiceDate

-- -- i know that we can just query the retail_clean_with_nulls... sorry...

-- -- 4847 rows with duplicates removed



-- SELECT * FROM retail_clean_with_out_nulls  -- 3,92,732 rows without nulls in customer_id column

-- SELECT * FROM retail_clean_with_nulls -- 5,26,051 rows with nulls in customer_id column





-- Identify purchase rows that are fully offset by a later matching cancellation
-- WITH matched_cancels AS (
--     SELECT
--         p.InvoiceNo AS Purchase_InvoiceNo
--     FROM Online_Retail p
--     JOIN Online_Retail c
--         ON p.CustomerID = c.CustomerID
--         AND p.StockCode = c.StockCode
--         AND p.UnitPrice = c.UnitPrice
--         AND p.Quantity = -c.Quantity
--         AND c.InvoiceNo LIKE 'C%'
--         AND p.InvoiceNo NOT LIKE 'C%'
--         AND c.InvoiceDate > p.InvoiceDate
-- )
-- SELECT
--     DISTINCT *,
--     Quantity * UnitPrice AS Revenue,
--     MONTH(InvoiceDate) AS InvoiceMonth,
--     YEAR(InvoiceDate) AS InvoiceYear
-- INTO retail_clean_netted
-- FROM Online_Retail
-- WHERE InvoiceNo NOT LIKE 'C%'
--   AND InvoiceNo NOT LIKE 'A%'
--   AND Quantity >= 0
--   AND UnitPrice >= 0
--   AND CustomerID IS NOT NULL
--   AND InvoiceNo NOT IN (SELECT Purchase_InvoiceNo FROM matched_cancels);





-- ################################################################################################################################################################




-- CEO Q3 (Pareto)


-- SELECT
--     CustomerID,
--     SUM(Revenue) AS Customer_Revenue,
--     ROUND(
--         SUM(SUM(Revenue)) OVER (
--             ORDER BY SUM(Revenue) DESC
--             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--         ) * 100.0 / SUM(SUM(Revenue)) OVER (),
--         2
--     ) AS Cumulative_Revenue_Pct
-- FROM retail_clean_with_out_nulls
-- GROUP BY CustomerID
-- ORDER BY Customer_Revenue DESC;



-- ==============================================================================================================

-- CREATE VIEW vw_customer_purchase_days AS
-- SELECT DISTINCT
--     CustomerID,
--     CAST(InvoiceDate AS DATE) AS PurchaseDate
-- FROM retail_clean_with_out_nulls;

-- ==============================================================================================================


-- VIEWs for CMO Q2

-- CREATE VIEW vw_customer_repeat_gap AS
-- WITH gap_calc AS (
--     SELECT
--         CustomerID,
--         PurchaseDate,
--         LAG(PurchaseDate) OVER (
--             PARTITION BY CustomerID ORDER BY PurchaseDate
--         ) AS Previous_Purchase_Date
--     FROM vw_customer_purchase_days
-- )
-- SELECT
--     CustomerID,
--     PurchaseDate,
--     Previous_Purchase_Date,
--     DATEDIFF(DAY, Previous_Purchase_Date, PurchaseDate) AS Days_Between_Purchases
-- FROM gap_calc
-- WHERE Previous_Purchase_Date IS NOT NULL;


-- sanity checks 

-- SELECT COUNT(DISTINCT CustomerID) AS Total_Customers FROM retail_clean_with_out_nulls;
-- SELECT COUNT(DISTINCT CustomerID) AS Repeat_Customers FROM vw_customer_repeat_gap;


-- Step 2 — SQL: summary stats (don't stop at the mean)

-- SELECT
--     AVG(Days_Between_Purchases * 1.0) AS Mean_Gap,
--     (SELECT AVG(Days_Between_Purchases * 1.0)
--      FROM (SELECT TOP 50 PERCENT Days_Between_Purchases
--            FROM vw_customer_repeat_gap ORDER BY Days_Between_Purchases) t) AS Median_Approx,
--     SUM(CASE WHEN Days_Between_Purchases <= 30 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Pct_Within_30d
-- FROM vw_customer_repeat_gap;




-- ==============================================================================================================



-- CMO Q2


-- WITH customer_revenue AS (
--     SELECT CustomerID, SUM(Revenue) AS Total_Revenue
--     FROM retail_clean_netted
--     GROUP BY CustomerID
-- ),
-- ranked AS (
--     SELECT *,
--         NTILE(5) OVER (ORDER BY Total_Revenue DESC) AS revenue_group
--     FROM customer_revenue
-- )
-- SELECT * FROM ranked WHERE revenue_group = 1;