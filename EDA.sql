-- Part-1 of EDA ######################################################################################################################################3

-- SELECT [InvoiceNo]
--       ,[StockCode]
--       ,[Description]
--       ,[Quantity]
--       ,[InvoiceDate]
--       ,[UnitPrice]
--       ,[CustomerID]
--       ,[Country]
--   FROM [tcs_db].[dbo].[Online_Retail]


-- =================================================================================================================

-- Total rows
-- SELECT COUNT(*) FROM Online_Retail  -- 5,41,909 lakh rows

-- =================================================================================================================

-- How many unique customers, products, invoices?

-- 4,373 rows => unique customers along with nulls
-- SELECT
--   distinct CustomerID
-- FROM Online_Retail
-- ORDER BY CustomerID

-- 3,958 rows => unique products
-- SELECT
--   distinct StockCode
-- FROM Online_Retail
-- ORDER BY StockCode

-- 25,900 rows => invoices generated

-- SELECT
--   distinct InvoiceNo
-- FROM Online_Retail


-- SELECT
--   *
-- FROM Online_Retail
-- WHERE InvoiceNo LIKE 'C%' -- 9288 rows
-- AND Quantity < 0    -- 9288 rows


-- SELECT
--   *
-- FROM Online_Retail
-- WHERE InvoiceNo LIKE 'A%' -- 3 rows => Adjust bad debt


-- =================================================================================================================

-- Date range (min/max InvoiceDate)

-- SELECT MAX(InvoiceDate) as max_date FROM Online_Retail
-- SELECT MIN(InvoiceDate) as min_date FROM Online_Retail

-- SELECT 
--     DATENAME(Month, MIN(InvoiceDate)) as min_date_month,
--     DATENAME(Month, MAX(InvoiceDate)) as max_date_month
-- FROM Online_Retail

-- =================================================================================================================
-- Distinct customers

-- SELECT
--     distinct CustomerID
-- FROM Online_Retail
-- WHERE CustomerID is NULL

-- 4,373 rows
-- includes nulls


-- =================================================================================================================

-- SELECT distinct InvoiceNo FROM Online_Retail
-- WHERE LEN(InvoiceNo) = 6
-- 22,061 unique invoice numbers

-- =================================================================================================================


-- SELECT * FROM Online_Retail
-- WHERE InvoiceNo LIKE 'A%' OR InvoiceNo LIKE 'C%' AND Quantity <= 0

-- =================================================================================================================



-- How many countries are present? => 38 countries

-- SELECT
--   distinct Country
-- FROM Online_Retail



