-- SELECT * FROM clean_sales_with_null_customerID      -- 522566 rows

-- SELECT * FROM clean_sales_with_out_null_customerID      -- 391148 rows


-- #######################################################################################################################


-- CEO

-- 1. UK revenue concentration vs. other markets

SELECT Country,
       SUM(Quantity*UnitPrice) AS Revenue,
       COUNT(DISTINCT InvoiceNo) AS Orders,
       COUNT(DISTINCT CustomerID) AS Customers
FROM clean_sales_with_null_customerID
GROUP BY Country
ORDER BY Revenue DESC;


-- 2. Product/SKU revenue concentration + Pareto cut

WITH product_rev AS (
  SELECT StockCode, Description, SUM(Quantity*UnitPrice) AS Revenue
  FROM clean_sales
  GROUP BY StockCode, Description
)
SELECT StockCode, Description, Revenue,
       SUM(Revenue) OVER (ORDER BY Revenue DESC) * 1.0
         / SUM(Revenue) OVER () AS RunningRevenuePct
FROM product_rev
ORDER BY Revenue DESC;



-- 3. Monthly revenue trend


SELECT DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1) AS Month,
       SUM(Quantity*UnitPrice) AS Revenue,
       COUNT(DISTINCT InvoiceNo) AS Orders
FROM clean_sales
GROUP BY DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1)
ORDER BY Month;


-- 4. Top-N customer revenue dependency

WITH cust_rev AS (
  SELECT CustomerID, SUM(Quantity*UnitPrice) AS Revenue
  FROM clean_sales_with_out_null_customerID
  GROUP BY CustomerID
),
ranked AS (
  SELECT *, SUM(Revenue) OVER (ORDER BY Revenue DESC) * 1.0
              / SUM(Revenue) OVER () AS RunningRevenuePct
  FROM cust_rev
)
SELECT * FROM ranked ORDER BY Revenue DESC;



-- #######################################################################################################################


-- CMO


-- 5. Repeat vs. one-time customer revenue split


WITH cust_orders AS (
  SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS OrderCount,
         SUM(Quantity*UnitPrice) AS Revenue
  FROM clean_sales_with_out_null_customerID
  GROUP BY CustomerID
)
SELECT CASE WHEN OrderCount > 1 THEN 'Repeat' ELSE 'One-time' END AS CustomerType,
       COUNT(*) AS Customers,
       SUM(Revenue) AS Revenue
FROM cust_orders
GROUP BY CASE WHEN OrderCount > 1 THEN 'Repeat' ELSE 'One-time' END;



-- 6. Reorder gap


WITH order_dates AS (
  SELECT CustomerID, InvoiceNo, MIN(InvoiceDate) AS OrderDate
  FROM clean_sales_with_out_null_customerID
  GROUP BY CustomerID, InvoiceNo
),
gaps AS (
  SELECT CustomerID, OrderDate,
         DATEDIFF(day, LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate), OrderDate) AS GapDays
  FROM order_dates
)
SELECT DISTINCT -- DISTINCT is needed because PERCENTILE_CONT returns a value for every row
       AVG(GapDays * 1.0) OVER () AS AvgGapDays,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY GapDays) OVER (PARTITION BY 1) AS MedianGapDays
FROM gaps
WHERE GapDays IS NOT NULL;



-- 7. First-purchase product vs. repeat behavior


WITH first_invoice AS (
  SELECT CustomerID, MIN(InvoiceNo) AS FirstInvoice
  FROM clean_sales_with_out_null_customerID
  GROUP BY CustomerID
),
cust_status AS (
  SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS OrderCount
  FROM clean_sales_with_out_null_customerID
  GROUP BY CustomerID
)
SELECT r.StockCode, r.Description,
       SUM(CASE WHEN cs.OrderCount > 1 THEN 1 ELSE 0 END) AS BecameRepeatBuyer,
       SUM(CASE WHEN cs.OrderCount = 1 THEN 1 ELSE 0 END) AS StayedOneTime,
       SUM(CASE WHEN cs.OrderCount > 1 THEN 1 ELSE 0 END) * 1.0
         / NULLIF(COUNT(*), 0) AS RepeatConversionRate
FROM clean_sales_with_out_null_customerID r
JOIN first_invoice f ON r.CustomerID = f.CustomerID AND r.InvoiceNo = f.FirstInvoice
JOIN cust_status cs ON r.CustomerID = cs.CustomerID
GROUP BY r.StockCode, r.Description
HAVING COUNT(*) >= 20
ORDER BY RepeatConversionRate DESC;




-- 8. Ex-UK revenue-per-customer / repeat rate


WITH cust_country AS (
  SELECT CustomerID, Country,
         COUNT(DISTINCT InvoiceNo) AS OrderCount,
         SUM(Quantity*UnitPrice) AS Revenue
  FROM clean_sales_with_out_null_customerID
  WHERE Country != 'United Kingdom'
  GROUP BY CustomerID, Country
)
SELECT Country,
       COUNT(*) AS Customers,
       AVG(Revenue) AS AvgRevPerCustomer,
       AVG(CASE WHEN OrderCount > 1 THEN 1.0 ELSE 0 END) AS RepeatRate
FROM cust_country
GROUP BY Country
HAVING COUNT(*) >= 10
ORDER BY AvgRevPerCustomer DESC;








-- to be remembered for interview


SELECT SUM(Revenue) AS TotalRevenue_AllRows FROM clean_sales;


SELECT SUM(Revenue) AS TotalRevenue_KnownCustomers FROM clean_sales_with_out_null_customerID;


SELECT 
  (SELECT SUM(Revenue) FROM clean_sales) AS TotalRevenue_AllRows,
  (SELECT SUM(Revenue) FROM clean_sales_with_out_null_customerID) AS TotalRevenue_KnownCustomers,
  (SELECT SUM(Revenue) FROM clean_sales) - (SELECT SUM(Revenue) FROM clean_sales_with_out_null_customerID) AS RevenueGap;


SELECT TOP (1000) [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
      ,[Revenue]
  FROM [tcs_db].[dbo].[clean_sales]


-- InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country, Revenue


SELECT DISTINCT Country FROM clean_sales ORDER BY Country;












-- #######################################################################################################################


-- schema tables for powerBI

-- Dim_Customer: one row per customer, including Guest
WITH customer_country AS (
    SELECT CustomerID, Country,
           ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY COUNT(*) DESC) AS rn
    FROM clean_sales
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID, Country
)
SELECT CAST(CustomerID AS VARCHAR(10)) AS CustomerKey, Country
FROM customer_country
WHERE rn = 1
UNION ALL
SELECT '-1', 'Unknown'   -- Guest placeholder, no country
;

-- Dim_Product: one row per StockCode, most frequent Description wins
WITH product_desc AS (
    SELECT StockCode, Description,
           ROW_NUMBER() OVER (PARTITION BY StockCode ORDER BY COUNT(*) DESC) AS rn
    FROM clean_sales
    GROUP BY StockCode, Description
)
SELECT StockCode, Description
FROM product_desc
WHERE rn = 1;

-- Fact_Sales: grain = one row per invoice line
SELECT
    InvoiceNo,
    StockCode,
    CAST(COALESCE(CustomerID, -1) AS VARCHAR(10)) AS CustomerKey,
    InvoiceDate,
    Quantity,
    UnitPrice,
    Revenue
FROM clean_sales;


