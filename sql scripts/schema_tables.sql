-- Fact_Sales: grain = one row per invoice line =========================================================================================
SELECT
    InvoiceNo,
    StockCode,
    COALESCE(CustomerID, -1) AS CustomerKey,
    InvoiceDate,
    Quantity,
    UnitPrice,
    Revenue,
    Country
FROM clean_sales
WHERE (CustomerID IS NULL OR CustomerID NOT IN (14265, 12743, 12363, 16320, 15108))
  AND Country NOT IN ('European Community', 'Unspecified');







-- Dim_Customer: one row per customer, including Guest =========================================================================================
WITH customer_country AS (
    SELECT CustomerID, Country,
           ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY COUNT(*) DESC) AS rn
    FROM clean_sales
    WHERE CustomerID IS NOT NULL
      AND Country NOT IN ('European Community', 'Unspecified')
    GROUP BY CustomerID, Country
)
SELECT CAST(CustomerID AS VARCHAR(10)) AS CustomerKey, Country
FROM customer_country
WHERE rn = 1
UNION ALL
SELECT '-1', 'Unknown'   -- Guest placeholder, no country









-- Dim_Product: one row per StockCode, most frequent Description wins =========================================================================================
WITH product_desc AS (
    SELECT StockCode, Description, COUNT(*) AS freq
    FROM clean_sales
    GROUP BY StockCode, Description
)
SELECT StockCode, Description
FROM (
    SELECT StockCode, Description,
           ROW_NUMBER() OVER (PARTITION BY StockCode ORDER BY freq DESC, Description ASC) AS rn
    FROM product_desc
) x
WHERE rn = 1;



SELECT TOP 10 * FROM Fact_sales 
WHERE InvoiceDate = (SELECT MAX(InvoiceDate) FROM Fact_sales)
ORDER BY Quantity * UnitPrice DESC



SELECT CAST(InvoiceDate AS DATE) AS SaleDate, SUM(Quantity * UnitPrice) AS DailyRevenue
FROM Fact_sales
GROUP BY CAST(InvoiceDate AS DATE)
ORDER BY DailyRevenue DESC



SELECT CustomerKey, COUNT(DISTINCT InvoiceNo) AS Orders, SUM(Quantity*UnitPrice) AS Revenue
FROM Fact_sales WHERE CAST(InvoiceDate AS DATE) = '2011-12-09'
GROUP BY CustomerKey ORDER BY Revenue DESC


SELECT COUNT(DISTINCT InvoiceNo) AS TotalOrders, SUM(Quantity*UnitPrice) AS TotalRevenue
FROM Fact_sales WHERE CustomerKey = 16446