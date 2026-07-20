-- I want the actual numbers before I recommend a visual design (histogram bucket size and threshold choice both depend on the distribution shape):

WITH CustomerInvoices AS (
    SELECT DISTINCT
        CustomerKey,
        InvoiceNo,
        InvoiceDate
    FROM Fact_sales
    WHERE CustomerKey <> -1
),
OrderGaps AS (
    SELECT
        CustomerKey,
        InvoiceNo,
        InvoiceDate,
        LAG(InvoiceDate) OVER (PARTITION BY CustomerKey ORDER BY InvoiceDate) AS PrevInvoiceDate
    FROM CustomerInvoices
)
SELECT
    CustomerKey,
    InvoiceNo,
    InvoiceDate,
    PrevInvoiceDate,
    DATEDIFF(day, PrevInvoiceDate, InvoiceDate) AS GapDays
INTO dbo.OrderGaps_Staging
FROM OrderGaps
WHERE PrevInvoiceDate IS NOT NULL;

-- Validation: how many customers actually have a gap, and what's the shape?
SELECT
    COUNT(DISTINCT CustomerKey) AS CustomersWithGaps,
    COUNT(*) AS TotalGapEvents,
    MIN(GapDays) AS MinGap,
    MAX(GapDays) AS MaxGap,
    AVG(GapDays * 1.0) AS AvgGap,
    STDEV(GapDays) AS StdDevGap
FROM OrderGaps_Staging;












-- Also run this to size the censoring problem — how many customers' last invoice falls in the final 30/60/90 days of the dataset:

WITH MaxDateCTE AS (
    -- Step 1: Get the absolute maximum date from the entire dataset
    SELECT MAX(InvoiceDate) AS MaxDatasetDate 
    FROM Fact_sales
),
CustomerLastOrder AS (
    -- Step 2: Get the last invoice date per customer
    SELECT 
        CustomerKey, 
        MAX(InvoiceDate) AS LastInvoiceDate
    FROM Fact_sales
    WHERE CustomerKey <> -1
    GROUP BY CustomerKey
),
BucketAssignment AS (
    -- Step 3: Calculate the day difference and assign buckets
    SELECT 
        c.CustomerKey,
        CASE 
            WHEN DATEDIFF(day, c.LastInvoiceDate, m.MaxDatasetDate) <= 30 THEN 'Last order within 30d of dataset end'
            WHEN DATEDIFF(day, c.LastInvoiceDate, m.MaxDatasetDate) <= 90 THEN 'Last order within 90d of dataset end'
            ELSE 'Last order earlier'
        END AS CensorBucket
    FROM CustomerLastOrder c
    CROSS JOIN MaxDateCTE m
)
-- Step 4: Aggregate the final counts by bucket
SELECT 
    CensorBucket, 
    COUNT(*) AS CustomerCount
FROM BucketAssignment
GROUP BY CensorBucket;










-- Run this before I recommend bucket sizes or a threshold line — I need the actual shape, not just mean/stdev:


SELECT
    CASE 
        WHEN GapDays = 0 THEN '0 days (same-day)'
        WHEN GapDays BETWEEN 1 AND 7 THEN '1-7 days'
        WHEN GapDays BETWEEN 8 AND 14 THEN '8-14 days'
        WHEN GapDays BETWEEN 15 AND 30 THEN '15-30 days'
        WHEN GapDays BETWEEN 31 AND 60 THEN '31-60 days'
        WHEN GapDays BETWEEN 61 AND 90 THEN '61-90 days'
        ELSE '90+ days'
    END AS GapBucket,
    COUNT(*) AS EventCount
FROM dbo.OrderGaps_Staging
GROUP BY CASE 
        WHEN GapDays = 0 THEN '0 days (same-day)'
        WHEN GapDays BETWEEN 1 AND 7 THEN '1-7 days'
        WHEN GapDays BETWEEN 8 AND 14 THEN '8-14 days'
        WHEN GapDays BETWEEN 15 AND 30 THEN '15-30 days'
        WHEN GapDays BETWEEN 31 AND 60 THEN '31-60 days'
        WHEN GapDays BETWEEN 61 AND 90 THEN '61-90 days'
        ELSE '90+ days'
    END
ORDER BY MIN(GapDays);








-- And get the median (percentiles are more honest than mean/stdev for a skewed distribution like this):


SELECT DISTINCT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY GapDays) OVER () AS MedianGap,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY GapDays) OVER () AS P75Gap,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY GapDays) OVER () AS P90Gap
FROM dbo.OrderGaps_Staging;




-- Before you build anything, check whether these are genuinely same calendar-date, different-invoice orders:


SELECT TOP 20
    CustomerKey,
    InvoiceDate,
    COUNT(DISTINCT InvoiceNo) AS InvoicesThatDay
FROM Fact_sales
WHERE CustomerKey <> -1
GROUP BY CustomerKey, InvoiceDate
HAVING COUNT(DISTINCT InvoiceNo) > 1
ORDER BY InvoicesThatDay DESC;


-- view


-- CREATE VIEW dbo.vw_OrderGapBuckets AS
-- SELECT
--     GapDays,
--     CASE 
--         WHEN GapDays = 0 THEN 'Same-day (multiple invoices)'
--         WHEN GapDays BETWEEN 1 AND 7 THEN '1-7 days'
--         WHEN GapDays BETWEEN 8 AND 14 THEN '8-14 days'
--         WHEN GapDays BETWEEN 15 AND 30 THEN '15-30 days'
--         WHEN GapDays BETWEEN 31 AND 60 THEN '31-60 days'
--         WHEN GapDays BETWEEN 61 AND 90 THEN '61-90 days'
--         ELSE '90+ days'
--     END AS GapBucket,
--     CASE 
--         WHEN GapDays = 0 THEN 0
--         WHEN GapDays BETWEEN 1 AND 7 THEN 1
--         WHEN GapDays BETWEEN 8 AND 14 THEN 2
--         WHEN GapDays BETWEEN 15 AND 30 THEN 3
--         WHEN GapDays BETWEEN 31 AND 60 THEN 4
--         WHEN GapDays BETWEEN 61 AND 90 THEN 5
--         ELSE 6
--     END AS BucketOrder
-- FROM dbo.OrderGaps_Staging;






-- SELECT * FROM vw_OrderGapBuckets



















DROP TABLE IF EXISTS dbo.OrderGaps_Staging;

WITH CustomerInvoices AS (
    SELECT DISTINCT
        CustomerKey,
        InvoiceDate
    FROM Fact_sales
    WHERE CustomerKey <> -1
),
OrderGaps AS (
    SELECT
        CustomerKey,
        InvoiceDate,
        LAG(InvoiceDate) OVER (PARTITION BY CustomerKey ORDER BY InvoiceDate) AS PrevInvoiceDate
    FROM CustomerInvoices
)
SELECT
    CustomerKey,
    InvoiceDate,
    PrevInvoiceDate,
    DATEDIFF(day, PrevInvoiceDate, InvoiceDate) AS GapDays
INTO dbo.OrderGaps_Staging
FROM OrderGaps
WHERE PrevInvoiceDate IS NOT NULL;

SELECT COUNT(*) AS TotalGapEvents FROM dbo.OrderGaps_Staging;
















DROP VIEW IF EXISTS dbo.vw_OrderGapBuckets;

-- CREATE VIEW dbo.vw_OrderGapBuckets AS
-- SELECT
--     GapDays,
--     CASE 
--         WHEN GapDays = 0 THEN 'Same-day repeat order'
--         WHEN GapDays BETWEEN 1 AND 7 THEN '1-7 days'
--         WHEN GapDays BETWEEN 8 AND 14 THEN '8-14 days'
--         WHEN GapDays BETWEEN 15 AND 30 THEN '15-30 days'
--         WHEN GapDays BETWEEN 31 AND 60 THEN '31-60 days'
--         WHEN GapDays BETWEEN 61 AND 90 THEN '61-90 days'
--         ELSE '90+ days'
--     END AS GapBucket,
--     CASE 
--         WHEN GapDays = 0 THEN 0
--         WHEN GapDays BETWEEN 1 AND 7 THEN 1
--         WHEN GapDays BETWEEN 8 AND 14 THEN 2
--         WHEN GapDays BETWEEN 15 AND 30 THEN 3
--         WHEN GapDays BETWEEN 31 AND 60 THEN 4
--         WHEN GapDays BETWEEN 61 AND 90 THEN 5
--         ELSE 6
--     END AS BucketOrder
-- FROM dbo.OrderGaps_Staging;

SELECT GapBucket, BucketOrder, COUNT(*) AS EventCount
FROM dbo.vw_OrderGapBuckets
GROUP BY GapBucket, BucketOrder
ORDER BY BucketOrder;

SELECT DISTINCT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY GapDays) OVER () AS MedianGap,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY GapDays) OVER () AS P75Gap,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY GapDays) OVER () AS P90Gap
FROM dbo.OrderGaps_Staging;
