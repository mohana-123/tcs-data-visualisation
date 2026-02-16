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

-- DROP TABLE retail_clean;


-- with nulls in customer_id column
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



-- without nulls in customer_id column
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

-- i know that we can just query the retail_clean_with_nulls... sorry...

-- 4847 rows with duplicates removed



-- SELECT * FROM retail_clean_with_out_nulls  -- 3,92,732 rows without nulls in customer_id column

-- SELECT * FROM retail_clean_with_nulls -- 5,26,051 rows with nulls in customer_id column