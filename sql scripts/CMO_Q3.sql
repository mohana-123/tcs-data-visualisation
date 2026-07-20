SELECT TOP 20 * FROM dbo.Dim_Product;

SELECT TOP 5 * FROM dbo.Fact_sales;




WITH CustomerInvoiceCounts AS (
    SELECT
        CustomerKey,
        COUNT(DISTINCT InvoiceNo) AS InvoiceCount
    FROM Fact_sales
    WHERE CustomerKey <> -1
    GROUP BY CustomerKey
),
ProductTotalRevenue AS (
    SELECT
        fs.StockCode,
        dp.Description,
        SUM(fs.Revenue) AS TotalProductRevenue
    FROM Fact_sales fs
    INNER JOIN Dim_Product dp ON fs.StockCode = dp.StockCode
    INNER JOIN CustomerInvoiceCounts cic ON fs.CustomerKey = cic.CustomerKey
    WHERE fs.CustomerKey <> -1
    GROUP BY fs.StockCode, dp.Description
),
Top10Products AS (
    SELECT TOP 10
        StockCode,
        Description,
        TotalProductRevenue
    FROM ProductTotalRevenue
    ORDER BY TotalProductRevenue DESC
),
SegmentedRevenue AS (
    SELECT
        fs.StockCode,
        CASE 
            WHEN cic.InvoiceCount >= 2 THEN 'Repeat'
            ELSE 'One-time'
        END AS CustomerSegment,
        SUM(fs.Revenue) AS SegmentRevenue
    FROM Fact_sales fs
    INNER JOIN CustomerInvoiceCounts cic ON fs.CustomerKey = cic.CustomerKey
    WHERE fs.CustomerKey <> -1 
        AND fs.StockCode IN (SELECT StockCode FROM Top10Products)
    GROUP BY fs.StockCode, CASE 
            WHEN cic.InvoiceCount >= 2 THEN 'Repeat'
            ELSE 'One-time'
        END
)
SELECT
    t10.Description,
    sr.CustomerSegment,
    sr.SegmentRevenue,
    t10.TotalProductRevenue
FROM SegmentedRevenue sr
INNER JOIN Top10Products t10 ON sr.StockCode = t10.StockCode
ORDER BY t10.TotalProductRevenue DESC, sr.CustomerSegment;


























-- before building in powerBI


-- CREATE VIEW dbo.vw_ProductMixBySegment AS
-- WITH CustomerInvoiceCounts AS (
--     SELECT
--         CustomerKey,
--         COUNT(DISTINCT InvoiceNo) AS InvoiceCount
--     FROM Fact_sales
--     WHERE CustomerKey <> -1
--     GROUP BY CustomerKey
-- ),
-- ProductTotalRevenue AS (
--     SELECT
--         fs.StockCode,
--         dp.Description,
--         SUM(fs.Revenue) AS TotalProductRevenue
--     FROM Fact_sales fs
--     INNER JOIN Dim_Product dp ON fs.StockCode = dp.StockCode
--     INNER JOIN CustomerInvoiceCounts cic ON fs.CustomerKey = cic.CustomerKey
--     WHERE fs.CustomerKey <> -1
--     GROUP BY fs.StockCode, dp.Description
-- ),
-- Top10Products AS (
--     SELECT TOP 10
--         StockCode,
--         Description,
--         TotalProductRevenue
--     FROM ProductTotalRevenue
--     ORDER BY TotalProductRevenue DESC
-- ),
-- SegmentedRevenue AS (
--     SELECT
--         fs.StockCode,
--         t10.Description,
--         t10.TotalProductRevenue,
--         CASE 
--             WHEN cic.InvoiceCount >= 2 THEN 'Repeat'
--             ELSE 'One-time'
--         END AS CustomerSegment,
--         SUM(fs.Revenue) AS SegmentRevenue
--     FROM Fact_sales fs
--     INNER JOIN CustomerInvoiceCounts cic ON fs.CustomerKey = cic.CustomerKey
--     INNER JOIN Top10Products t10 ON fs.StockCode = t10.StockCode
--     WHERE fs.CustomerKey <> -1
--     GROUP BY fs.StockCode, t10.Description, t10.TotalProductRevenue, CASE 
--             WHEN cic.InvoiceCount >= 2 THEN 'Repeat'
--             ELSE 'One-time'
--         END
-- )
-- SELECT
--     Description,
--     CustomerSegment,
--     SegmentRevenue,
--     TotalProductRevenue,
--     ROUND(
--         CAST(SUM(CASE WHEN CustomerSegment = 'Repeat' THEN SegmentRevenue ELSE 0 END) 
--              OVER (PARTITION BY Description) AS FLOAT)
--         / TotalProductRevenue * 100, 
--         1
--     ) AS RepeatPercentage
-- FROM SegmentedRevenue;






















DROP TABLE IF EXISTS dbo.ProductMixBySegment;

WITH CustomerInvoiceCounts AS (
    SELECT CustomerKey, COUNT(DISTINCT InvoiceNo) AS InvoiceCount
    FROM Fact_sales
    WHERE CustomerKey <> -1
    GROUP BY CustomerKey
),
ProductTotalRevenue AS (
    SELECT fs.StockCode, dp.Description, SUM(fs.Revenue) AS TotalProductRevenue
    FROM Fact_sales fs
    INNER JOIN Dim_Product dp ON fs.StockCode = dp.StockCode
    INNER JOIN CustomerInvoiceCounts cic ON fs.CustomerKey = cic.CustomerKey
    WHERE fs.CustomerKey <> -1
    GROUP BY fs.StockCode, dp.Description
),
Top10Products AS (
    SELECT TOP 10 StockCode, Description, TotalProductRevenue
    FROM ProductTotalRevenue
    ORDER BY TotalProductRevenue DESC
),
SegmentedRevenue AS (
    SELECT
        fs.StockCode,
        t10.Description,
        t10.TotalProductRevenue,
        CASE WHEN cic.InvoiceCount >= 2 THEN 'Repeat' ELSE 'One-time' END AS CustomerSegment,
        SUM(fs.Revenue) AS SegmentRevenue
    FROM Fact_sales fs
    INNER JOIN CustomerInvoiceCounts cic ON fs.CustomerKey = cic.CustomerKey
    INNER JOIN Top10Products t10 ON fs.StockCode = t10.StockCode
    WHERE fs.CustomerKey <> -1
    GROUP BY fs.StockCode, t10.Description, t10.TotalProductRevenue, CASE WHEN cic.InvoiceCount >= 2 THEN 'Repeat' ELSE 'One-time' END
),
ProductRepeatTotals AS (
    SELECT
        Description,
        TotalProductRevenue,
        SUM(CASE WHEN CustomerSegment = 'Repeat' THEN SegmentRevenue ELSE 0 END) AS RepeatRevenue
    FROM SegmentedRevenue
    GROUP BY Description, TotalProductRevenue
),
WithRepeatPct AS (
    SELECT
        sr.Description,
        sr.CustomerSegment,
        sr.SegmentRevenue,
        sr.TotalProductRevenue,
        ROUND(CAST(prt.RepeatRevenue AS FLOAT) / sr.TotalProductRevenue * 100, 1) AS RepeatPercentage,
        -- FIXED: Replaced alias with expression & switched to DENSE_RANK()
        DENSE_RANK() OVER (ORDER BY CAST(prt.RepeatRevenue AS FLOAT) / sr.TotalProductRevenue DESC) AS SortOrder
    FROM SegmentedRevenue sr
    INNER JOIN ProductRepeatTotals prt ON sr.Description = prt.Description
)
SELECT
    Description,
    CustomerSegment,
    SegmentRevenue,
    TotalProductRevenue,
    RepeatPercentage,
    SortOrder
INTO dbo.ProductMixBySegment
FROM WithRepeatPct;

-- Verify it created
SELECT * FROM dbo.ProductMixBySegment;
