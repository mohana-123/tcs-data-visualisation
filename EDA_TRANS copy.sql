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


-- VIEWs

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


