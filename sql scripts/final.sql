-- SELECT * FROM Online_Retail


-- how much revenue is sitting in these duplicate groups?
-- WITH dupes AS (
--     SELECT InvoiceNo, StockCode, Quantity, InvoiceDate, UnitPrice, CustomerID, COUNT(*) AS cnt
--     FROM online_retail
--     GROUP BY InvoiceNo, StockCode, Quantity, InvoiceDate, UnitPrice, CustomerID
--     HAVING COUNT(*) > 1
-- )
-- SELECT SUM((cnt - 1) * Quantity * UnitPrice) AS RevenueAtRiskIfDeduped,
--        SUM(cnt - 1) AS ExtraRowsToRemove
-- FROM dupes;



WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY InvoiceNo, StockCode, Quantity, InvoiceDate, UnitPrice, CustomerID
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM Online_Retail
)
SELECT * FROM ranked WHERE rn <> 1;


WITH ranked AS (
    SELECT
        StockCode,
        Description,
        COUNT(*) AS freq,
        ROW_NUMBER() OVER (
            PARTITION BY StockCode
            ORDER BY COUNT(*) DESC, Description ASC
        ) AS rn
    FROM clean_sales
    GROUP BY StockCode, Description
)
SELECT StockCode, Description
FROM ranked
WHERE rn = 1;

-- SELECT * INTO online_retail_dedup FROM ranked WHERE rn = 1;



-- SELECT DISTINCT StockCode, Description
-- FROM online_retail_dedup
-- WHERE StockCode IN ('POST','DOT','M','BANK CHARGES','AMAZONFEE','C2','PADS')
--    OR (StockCode NOT LIKE '%[^A-Za-z]%' AND LEN(StockCode) > 0);


-- SELECT * FROM online_retail_dedup
-- WHERE UnitPrice <= 0 AND LEFT(InvoiceNo,1) <> 'C';





-- -- confirm dedup worked as expected
-- SELECT COUNT(*) FROM online_retail_dedup;  -- should be 541909 - 5270 = 536639

-- -- now isolate each filter's contribution
-- SELECT
--     SUM(CASE WHEN LEFT(InvoiceNo,1) = 'C' THEN 1 ELSE 0 END) AS CancelledRows,
--     SUM(CASE WHEN LEFT(InvoiceNo,1) <> 'C' AND Quantity <= 0 THEN 1 ELSE 0 END) AS NegQtyNotCancelled,
--     SUM(CASE WHEN UnitPrice <= 0 AND LEFT(InvoiceNo,1) <> 'C' THEN 1 ELSE 0 END) AS ZeroOrNegPrice,
--     SUM(CASE WHEN StockCode IN ('POST','DOT','M','BANK CHARGES','AMAZONFEE','C2','PADS') THEN 1 ELSE 0 END) AS NonProductCodes
-- FROM online_retail_dedup;


-- SELECT DISTINCT StockCode, Description, COUNT(*) AS Row_Count
-- FROM online_retail_dedup
-- WHERE StockCode NOT LIKE '[0-9]%' AND
-- StockCode NOT IN ('POST','DOT','M','BANK CHARGES','AMAZONFEE','C2','PADS','DCGS%','S','CRUK','B') 
-- GROUP BY StockCode, Description
-- ORDER BY Row_Count DESC;




-- -- 1. Check NULL-description DCGS rows follow the same adjustment pattern
-- SELECT * FROM online_retail_dedup
-- WHERE StockCode IN ('DCGS0055','DCGS0057','DCGS0066P','DCGS0070','DCGS0071','DCGS0072','DCGS0074')
--   AND Description IS NULL;

-- -- 2. Check the corrupted gift_0001_20 row
-- SELECT * FROM online_retail_dedup
-- WHERE StockCode = 'gift_0001_20' AND Description LIKE 'to push%';



-- CREATE VIEW clean_sales AS
-- WITH ranked AS (
--     SELECT *,
--            ROW_NUMBER() OVER (
--                PARTITION BY InvoiceNo, StockCode, Quantity, InvoiceDate, UnitPrice, CustomerID
--                ORDER BY (SELECT NULL)
--            ) AS rn
--     FROM online_retail
-- )
-- SELECT InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country,
--        Quantity * UnitPrice AS Revenue
-- FROM ranked
-- WHERE rn = 1
--   AND Quantity > 0
--   AND UnitPrice > 0
--   AND StockCode NOT IN ('POST','DOT','M','BANK CHARGES','AMAZONFEE','C2','PADS','D','S','CRUK','B');


-- WITH ranked AS (
--     SELECT *,
--            ROW_NUMBER() OVER (
--                PARTITION BY InvoiceNo, StockCode, Quantity, InvoiceDate, UnitPrice, CustomerID
--                ORDER BY (SELECT NULL)
--            ) AS rn
--     FROM online_retail
-- )
-- SELECT InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country,
--        Quantity * UnitPrice AS Revenue
-- INTO clean_sales -- This creates the new table in SQL Server
-- FROM ranked
-- WHERE rn = 1
--   AND Quantity > 0
--   AND UnitPrice > 0
--   AND StockCode NOT IN ('POST','DOT','M','BANK CHARGES','AMAZONFEE','C2','PADS','D','S','CRUK','B');


-- SELECT * FROM clean_sales  -- 533566 rows with nulls
-- WHERE CustomerID IS NOT NULL  -- 391148 rows without nulls


-- SELECT
--   *
-- INTO clean_sales_with_null_customerID
-- FROM clean_sales;


-- SELECT
--   *
-- INTO clean_sales_with_out_null_customerID
-- FROM clean_sales
-- WHERE CustomerID IS NOT NULL;




-- #################################################################################################################################

-- CEO

-- 1. UK concentration / regional dependency

-- SELECT Country,
--        SUM(Revenue) AS TotalRevenue,
--        ROUND(SUM(Revenue) * 100.0 / SUM(SUM(Revenue)) OVER (), 2) AS PctOfTotal
-- FROM clean_sales
-- GROUP BY Country
-- ORDER BY TotalRevenue DESC;




SELECT Country,
       SUM(Quantity*UnitPrice) AS Revenue,
       COUNT(DISTINCT InvoiceNo) AS Orders,
       COUNT(DISTINCT CustomerID) AS Customers,
       SUM(Quantity*UnitPrice) / NULLIF(COUNT(DISTINCT CustomerID),0) AS RevPerCustomer
FROM clean_sales
GROUP BY Country
ORDER BY Revenue DESC;



-- 2. Top products/categories by revenue


-- SELECT TOP 20 StockCode, Description,
--        SUM(Revenue) AS TotalRevenue,
--        SUM(Quantity) AS UnitsSold
-- FROM clean_sales
-- GROUP BY StockCode, Description
-- ORDER BY TotalRevenue DESC



SELECT StockCode, Description,
       SUM(Quantity*UnitPrice) AS Revenue,
       SUM(Quantity) AS UnitsSold
FROM clean_sales
GROUP BY StockCode, Description
ORDER BY Revenue DESC;


-- 3. Monthly revenue trend / seasonality


-- SELECT 
--     FORMAT(InvoiceDate, 'yyyy-MMM') AS Month, 
--     SUM(Revenue) AS TotalRevenue
-- FROM clean_sales 
-- GROUP BY FORMAT(InvoiceDate, 'yyyy-MMM') 
-- ORDER BY Month;


SELECT DATETRUNC(month, InvoiceDate) AS Month,
       SUM(Quantity*UnitPrice) AS Revenue,
       COUNT(DISTINCT InvoiceNo) AS Orders
FROM clean_sales
GROUP BY DATETRUNC(month, InvoiceDate)
ORDER BY Month;



-- 4. Customer concentration / dependency risk

-- WITH customer_rev AS (
--     SELECT 
--         CustomerID,
--         SUM(Revenue) AS Revenue
--     FROM clean_sales
--     WHERE CustomerID IS NOT NULL
--     GROUP BY CustomerID
-- ),
-- ranked AS (
--     SELECT *,
--            SUM(Revenue) OVER (ORDER BY Revenue DESC) * 100.0 /
--            SUM(Revenue) OVER () AS CumulativePct
--     FROM customer_rev
-- )
-- SELECT * FROM ranked ORDER BY Revenue DESC



SELECT TOP 20 CustomerID,
       SUM(Quantity*UnitPrice) AS Revenue
FROM clean_sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY Revenue DESC;






-- #################################################################################################################################

-- CMO


-- 1. Repeat vs one-time customer revenue split



-- WITH customer_orders AS (
--     SELECT 
--         CustomerID,
--         COUNT(DISTINCT InvoiceNo) AS OrderCount,
--         SUM(Revenue) AS Revenue
--     FROM clean_sales
--     WHERE CustomerID IS NOT NULL
--     GROUP BY CustomerID
-- )
-- SELECT
--     CASE WHEN OrderCount > 1 THEN 'Repeat' ELSE 'One-time' END AS Segment,
--     COUNT(*) AS CustomerCount,
--     SUM(Revenue) AS TotalRevenue,
--     SUM(Revenue) * 100.0 / SUM(SUM(Revenue)) OVER () AS PctOfRevenue
-- FROM customer_orders
-- GROUP BY CASE WHEN OrderCount > 1 THEN 'Repeat' ELSE 'One-time' END;




WITH cust_orders AS (
  SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS OrderCount,
         SUM(Quantity*UnitPrice) AS Revenue
  FROM clean_sales
  WHERE CustomerID IS NOT NULL
  GROUP BY CustomerID
)
SELECT CASE WHEN OrderCount > 1 THEN 'Repeat' ELSE 'One-time' END AS CustomerType,
       COUNT(*) AS Customers,
       SUM(Revenue) AS Revenue
FROM cust_orders
GROUP BY CASE WHEN OrderCount > 1 THEN 'Repeat' ELSE 'One-time' END;


-- 2. Gap between orders for repeat customers



-- WITH order_dates AS (
--     SELECT DISTINCT CustomerID, InvoiceNo, MIN(InvoiceDate) AS OrderDate
--     FROM clean_sales
--     WHERE CustomerID IS NOT NULL
--     GROUP BY CustomerID, InvoiceNo
-- ),
-- gaps AS (
--     SELECT CustomerID, OrderDate,
--            LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PrevOrderDate
--     FROM order_dates
-- )
-- SELECT AVG(DATEDIFF(day, PrevOrderDate, OrderDate)) AS AvgDaysBetweenOrders
-- FROM gaps
-- WHERE PrevOrderDate IS NOT NULL;



WITH order_dates AS (
  SELECT CustomerID, InvoiceNo, MIN(InvoiceDate) AS OrderDate
  FROM clean_sales
  GROUP BY CustomerID, InvoiceNo
),
gaps AS (
  SELECT CustomerID, OrderDate,
         DATEDIFF(day, LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate), OrderDate) AS GapDays
  FROM order_dates
),
metrics_window AS (
  SELECT 
    -- We calculate the average and median as window functions over the whole dataset
    AVG(CAST(GapDays AS FLOAT)) OVER() AS AvgGapDays,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY GapDays) OVER() AS MedianGapDays
  FROM gaps
  WHERE GapDays IS NOT NULL
)
-- Selecting TOP 1 reduces the final output to a single row
SELECT TOP 1 AvgGapDays, MedianGapDays
FROM metrics_window;





-- 3. Products correlated with repeat behavior


-- WITH customer_orders AS (
--     SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS OrderCount
--     FROM clean_sales WHERE CustomerID IS NOT NULL
--     GROUP BY CustomerID
-- )
-- SELECT TOP 20 s.StockCode, s.Description,
--        SUM(CASE WHEN c.OrderCount > 1 THEN s.Revenue ELSE 0 END) AS RepeatCustomerRevenue,
--        SUM(CASE WHEN c.OrderCount = 1 THEN s.Revenue ELSE 0 END) AS OneTimeCustomerRevenue
-- FROM clean_sales s
-- JOIN customer_orders c ON s.CustomerID = c.CustomerID
-- GROUP BY s.StockCode, s.Description
-- ORDER BY RepeatCustomerRevenue DESC;



WITH cust_first_order AS (
  SELECT CustomerID, MIN(InvoiceNo) AS FirstInvoice
  FROM clean_sales
  GROUP BY CustomerID
),
cust_status AS (
  SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS OrderCount
  FROM clean_sales
  GROUP BY CustomerID
)
SELECT r.StockCode, r.Description,
       SUM(CASE WHEN cs.OrderCount > 1 THEN 1 ELSE 0 END) AS RepeatBuyers,
       SUM(CASE WHEN cs.OrderCount = 1 THEN 1 ELSE 0 END) AS OneTimeBuyers
FROM clean_sales r
JOIN cust_first_order f ON r.CustomerID = f.CustomerID AND r.InvoiceNo = f.FirstInvoice
JOIN cust_status cs ON r.CustomerID = cs.CustomerID
GROUP BY r.StockCode, r.Description
ORDER BY RepeatBuyers DESC;


-- 4. Revenue-per-customer / repeat rate by country (ex-UK)


-- WITH customer_orders AS (
--     SELECT CustomerID, Country, COUNT(DISTINCT InvoiceNo) AS OrderCount, SUM(Revenue) AS Revenue
--     FROM clean_sales
--     WHERE CustomerID IS NOT NULL AND Country <> 'United Kingdom'
--     GROUP BY CustomerID, Country
-- )
-- SELECT Country,
--        COUNT(*) AS Customers,
--        SUM(Revenue) / COUNT(*) AS RevenuePerCustomer,
--        SUM(CASE WHEN OrderCount > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS RepeatRatePct
-- FROM customer_orders
-- GROUP BY Country
-- ORDER BY RevenuePerCustomer DESC;



WITH cust_country AS (
  SELECT CustomerID, Country, COUNT(DISTINCT InvoiceNo) AS OrderCount,
         SUM(Quantity*UnitPrice) AS Revenue
  FROM clean_sales
  WHERE Country != 'United Kingdom' AND CustomerID IS NOT NULL
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