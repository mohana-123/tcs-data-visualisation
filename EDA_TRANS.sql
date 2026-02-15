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

-- SELECT DISTINCT *, Quantity*UnitPrice AS Revenue
-- INTO retail_clean
-- FROM online_retail
-- WHERE InvoiceNo NOT LIKE 'C%'
-- AND InvoiceNo NOT LIKE 'A%'
-- AND Quantity >= 0
-- AND UnitPrice >= 0


-- 4847 rows with duplicates removed

SELECT * FROM retail_clean