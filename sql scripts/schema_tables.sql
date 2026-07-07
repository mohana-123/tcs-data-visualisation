-- Fact_Sales: grain = one row per invoice line =========================================================================================
SELECT
    InvoiceNo,
    StockCode,
    CAST(COALESCE(CustomerID, -1) AS VARCHAR(10)) AS CustomerKey,
    InvoiceDate,
    Quantity,
    UnitPrice,
    Revenue   
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
INTO Dim_Product
FROM (
    SELECT StockCode, Description,
           ROW_NUMBER() OVER (PARTITION BY StockCode ORDER BY freq DESC, Description ASC) AS rn
    FROM product_desc
) x
WHERE rn = 1;