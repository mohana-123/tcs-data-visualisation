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



-- CREATE VIEW cleaned_sales AS
-- SELECT *
-- FROM retail_clean_with_out_nulls


-- Q1
-- Get each customer's purchase sequence
-- Calculate difference in days


-- SELECT
--     CustomerID,
--     InvoiceDate,
--     LAG(InvoiceDate) OVER (PARTITION BY CustomerID ORDER BY InvoiceDate) AS Previous_Purchase_Date
-- FROM cleaned_sales;


-- with purchase_gap AS(
-- SELECT
--     CustomerID,
--     InvoiceDate,
--     LAG(InvoiceDate) OVER (PARTITION BY CustomerID ORDER BY InvoiceDate) AS Previous_Purchase_Date,
--     DATEDIFF(DAY, LAG(InvoiceDate) OVER (PARTITION BY CustomerID ORDER BY InvoiceDate),InvoiceDate) AS Days_Between_Purchases
-- FROM cleaned_sales
-- )


-- SELECT *
-- FROM purchase_gap
-- WHERE Days_Between_Purchases IS NOT NULL;

-- SELECT 
--     AVG(Days_Between_Purchases) AS Avg_Repeat_Duration_Days
-- FROM purchase_gap
-- WHERE Days_Between_Purchases IS NOT NULL;




-- create a view


-- CREATE VIEW vw_customer_repeat_gap AS
-- WITH purchase_gap AS (
--     SELECT
--         CustomerID,
--         InvoiceDate,
--         DATEDIFF(DAY,
--             LAG(InvoiceDate) OVER (
--                 PARTITION BY CustomerID
--                 ORDER BY InvoiceDate
--             ),
--             InvoiceDate
--         ) AS Days_Between_Purchases
--     FROM cleaned_sales
-- )
-- SELECT *
-- FROM purchase_gap
-- WHERE Days_Between_Purchases IS NOT NULL;




-- Q2 =>  part-1 => Who are the top 20% customers revenue?


-- SELECT * FROM
-- (SELECT 
--     CustomerID,
--     SUM(Revenue) AS Total_Revenue,
--     NTILE(5) OVER (ORDER BY SUM(Revenue) DESC) AS revenue_group
-- FROM cleaned_sales
-- GROUP BY CustomerID)t
-- WHERE revenue_group = 1
-- ORDER BY Total_Revenue DESC


-- Q2 =>  part-2 =>  what are the top 5 products they are buying frequently?

-- WITH base_data AS (
--     SELECT 
--         *
--     FROM cleaned_sales
-- ),

-- customer_revenue AS (
--     SELECT 
--         CustomerID,
--         SUM(Revenue) AS Total_Revenue
--     FROM base_data
--     GROUP BY CustomerID
-- ),

-- ranked_customers AS (
--     SELECT 
--         CustomerID,
--         NTILE(5) OVER (ORDER BY Total_Revenue DESC) AS revenue_group
--     FROM customer_revenue
-- ),

-- top_customers AS (
--     SELECT CustomerID
--     FROM ranked_customers
--     WHERE revenue_group = 1
-- )

-- SELECT TOP 5
--     b.StockCode,
--     b.Description,
--     SUM(b.Quantity) AS Total_Quantity_Purchased
-- FROM base_data b
-- JOIN top_customers t
--     ON b.CustomerID = t.CustomerID
-- GROUP BY b.StockCode, b.Description
-- ORDER BY Total_Quantity_Purchased DESC

-- SELECT TOP 5
--     StockCode,
--     [Description],
--     SUM(Quantity) AS Total_Quantity_Purchased
-- FROM base_data
-- GROUP BY StockCode, [Description]
-- ORDER BY Total_Quantity_Purchased DESC







-- WITH customer_revenue AS (
--     SELECT 
--         CustomerID,
--         SUM(Revenue) AS Total_Revenue
--     FROM cleaned_sales
--     GROUP BY CustomerID
-- ),

-- ranked AS (
--     SELECT *,
--            NTILE(5) OVER (ORDER BY Total_Revenue DESC) AS grp
--     FROM customer_revenue
-- )

-- SELECT 
--     SUM(CASE WHEN grp = 1 THEN Total_Revenue END) * 100.0 
--         / SUM(Total_Revenue) AS Top20_Revenue_Percentage
-- FROM ranked;






-- Q3 =>  what are the top 5 products they are buying frequently?



-- SELECT
--     Country,
--     SUM(Revenue) AS Total_Revenue
-- FROM cleaned_sales
-- GROUP BY Country
-- ORDER BY Total_Revenue DESC


-- Top Region by Order Volume

-- SELECT 
--     Country,
--     COUNT(DISTINCT InvoiceNo) AS Total_Orders
-- FROM cleaned_sales
-- GROUP BY Country
-- ORDER BY Total_Orders DESC;



-- Top Region by Customer Base

-- SELECT 
--     Country,
--     COUNT(DISTINCT CustomerID) AS Unique_Customers
-- FROM cleaned_sales
-- GROUP BY Country
-- ORDER BY Unique_Customers DESC;



-- Combine All Metrics (Best Practice for Executive View)

-- SELECT 
--     Country,
--     SUM(Revenue) AS Total_Revenue,
--     COUNT(DISTINCT InvoiceNo) AS Total_Orders,
--     COUNT(DISTINCT CustomerID) AS Unique_Customers
-- FROM cleaned_sales
-- GROUP BY Country
-- ORDER BY Total_Revenue DESC;


-- SELECT 
--     Country,
--     SUM(Revenue) AS Total_Revenue,
--     ROUND(
--         SUM(Revenue) * 100.0 / 
--         SUM(SUM(Revenue)) OVER(), 
--         2
--     ) AS Revenue_Percentage
-- FROM cleaned_sales
-- GROUP BY Country
-- ORDER BY Total_Revenue DESC;










-- Q4 => are there are any conditions that affecting the sales despite of effective promotions of some low monetary products during some timelines?


-- Monthly sales trend
-- SELECT 
--     YEAR(InvoiceDate) AS Year,
--     MONTH(InvoiceDate) AS Month,
--     SUM(Quantity * UnitPrice) AS Revenue
-- FROM cleaned_sales
-- GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
-- ORDER BY Year, Month;


-- Low price product revenue

-- SELECT 
--     [Description],
--     UnitPrice,
--     ROUND(AVG(UnitPrice), 3) AS AvgPrice,
--     ROUND(SUM(Revenue), 3) AS Total_Revenue
-- FROM cleaned_sales
-- GROUP BY [Description]
-- ORDER BY AvgPrice ASC;


-- SELECT
--     InvoiceMonth,
--     SUM(Revenue) AS Total_Revenue,
--     SUM(Quantity) AS Total_Quantity
-- FROM retail_clean_with_nulls
-- GROUP BY InvoiceMonth
-- ORDER BY InvoiceMonth ASC;
