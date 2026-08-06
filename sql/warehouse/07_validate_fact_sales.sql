/*
    Target: Microsoft Fabric Warehouse WH_SCD2
    Purpose: Read-only validation for implemented dbo.FactSales.

    Integrity queries state their expected result. No query changes data.
*/

-- 1. Complete FactSales contents.
SELECT SalesKey, OrderNumber, CustomerKey, SalesAmount, OrderDate, CreatedDateTime
FROM dbo.FactSales
ORDER BY OrderNumber, SalesKey;

-- 2. Sales joined to the assigned DimCustomer version.
SELECT
    f.SalesKey, f.OrderNumber, f.SalesAmount, f.OrderDate,
    d.CustomerKey, d.CustomerID, d.CustomerName, d.City,
    d.EffectiveStartDate, d.EffectiveEndDate, d.IsCurrent
FROM dbo.FactSales AS f
INNER JOIN dbo.DimCustomer AS d ON d.CustomerKey = f.CustomerKey
ORDER BY f.OrderNumber, f.SalesKey;

-- 3. Unmatched facts. Expected result: zero rows.
SELECT f.SalesKey, f.OrderNumber, f.CustomerKey, f.SalesAmount, f.OrderDate
FROM dbo.FactSales AS f
LEFT JOIN dbo.DimCustomer AS d ON d.CustomerKey = f.CustomerKey
WHERE d.CustomerKey IS NULL
ORDER BY f.OrderNumber;

-- 4. Duplicate OrderNumber values. Expected result: zero rows.
SELECT OrderNumber, COUNT_BIG(*) AS DuplicateOrderCount
FROM dbo.FactSales
GROUP BY OrderNumber
HAVING COUNT_BIG(*) > 1
ORDER BY OrderNumber;

-- 5. Duplicate SalesKey values. Expected result: zero rows.
SELECT SalesKey, COUNT_BIG(*) AS DuplicateKeyCount
FROM dbo.FactSales
GROUP BY SalesKey
HAVING COUNT_BIG(*) > 1
ORDER BY SalesKey;

-- 6. Facts mapped to historical customer versions.
SELECT f.*, d.CustomerID, d.CustomerName, d.City,
    d.EffectiveStartDate, d.EffectiveEndDate
FROM dbo.FactSales AS f
INNER JOIN dbo.DimCustomer AS d ON d.CustomerKey = f.CustomerKey
WHERE d.IsCurrent = CAST(0 AS BIT)
ORDER BY f.OrderDate, f.OrderNumber;

-- 7. Facts mapped to current customer versions.
SELECT f.*, d.CustomerID, d.CustomerName, d.City,
    d.EffectiveStartDate, d.EffectiveEndDate
FROM dbo.FactSales AS f
INNER JOIN dbo.DimCustomer AS d ON d.CustomerKey = f.CustomerKey
WHERE d.IsCurrent = CAST(1 AS BIT)
ORDER BY f.OrderDate, f.OrderNumber;

-- 8. Total sales by customer version.
SELECT
    d.CustomerKey, d.CustomerID, d.CustomerName, d.City,
    d.EffectiveStartDate, d.EffectiveEndDate, d.IsCurrent,
    COUNT_BIG(*) AS SalesRowCount,
    SUM(f.SalesAmount) AS TotalSalesAmount
FROM dbo.FactSales AS f
INNER JOIN dbo.DimCustomer AS d ON d.CustomerKey = f.CustomerKey
GROUP BY
    d.CustomerKey, d.CustomerID, d.CustomerName, d.City,
    d.EffectiveStartDate, d.EffectiveEndDate, d.IsCurrent
ORDER BY d.CustomerID, d.EffectiveStartDate, d.CustomerKey;

-- 9. Direct row-count reconciliation. This comparison is meaningful only when
-- staging contains the complete cumulative order set; FactSales is cumulative.
SELECT
    (SELECT COUNT_BIG(*) FROM [LH_SCD2_Staging].[dbo].[Sales]) AS SourceSalesRowCount,
    (SELECT COUNT_BIG(*) FROM dbo.FactSales) AS FactSalesRowCount,
    (SELECT COUNT_BIG(*) FROM [LH_SCD2_Staging].[dbo].[Sales])
        - (SELECT COUNT_BIG(*) FROM dbo.FactSales) AS RowCountDifference;

-- 10. Facts outside their assigned dimension version. Expected: zero rows.
SELECT
    f.OrderNumber, f.OrderDate, f.CustomerKey,
    d.CustomerID, d.EffectiveStartDate, d.EffectiveEndDate
FROM dbo.FactSales AS f
INNER JOIN dbo.DimCustomer AS d ON d.CustomerKey = f.CustomerKey
WHERE f.OrderDate < CAST(d.EffectiveStartDate AS DATE)
   OR f.OrderDate >= CAST(d.EffectiveEndDate AS DATE)
ORDER BY f.OrderNumber;

-- 11. Recompute historical mapping through the assigned version's CustomerID.
-- Orders returned map to zero or multiple date-range versions. Expected: zero.
SELECT
    f.OrderNumber,
    f.OrderDate,
    assigned.CustomerID,
    COUNT_BIG(matched.CustomerKey) AS RecomputedVersionCount
FROM dbo.FactSales AS f
LEFT JOIN dbo.DimCustomer AS assigned
    ON assigned.CustomerKey = f.CustomerKey
LEFT JOIN dbo.DimCustomer AS matched
    ON matched.CustomerID = assigned.CustomerID
   AND f.OrderDate >= CAST(matched.EffectiveStartDate AS DATE)
   AND f.OrderDate < CAST(matched.EffectiveEndDate AS DATE)
GROUP BY f.OrderNumber, f.OrderDate, assigned.CustomerID
HAVING COUNT_BIG(matched.CustomerKey) <> 1
ORDER BY f.OrderNumber;

-- 12. Source orders missing from FactSales. Expected: zero after a successful load.
SELECT
    source.[Order Number] AS OrderNumber,
    source.[Customer] AS CustomerID,
    source.[Order Date] AS OrderDate,
    CAST(source.[Sales Amount] AS DECIMAL(18,2)) AS SalesAmount
FROM [LH_SCD2_Staging].[dbo].[Sales] AS source
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.FactSales AS f
    WHERE f.OrderNumber = source.[Order Number]
)
ORDER BY source.[Order Number];

-- 13. Fact orders absent from the current source snapshot. Rows may be valid
-- when staging is a current or rolling snapshot while FactSales is cumulative.
SELECT f.SalesKey, f.OrderNumber, f.CustomerKey, f.SalesAmount, f.OrderDate
FROM dbo.FactSales AS f
WHERE NOT EXISTS
(
    SELECT 1 FROM [LH_SCD2_Staging].[dbo].[Sales] AS source
    WHERE source.[Order Number] = f.OrderNumber
)
ORDER BY f.OrderNumber;

-- 14. Amount reconciliation for OrderNumber values present in both datasets.
SELECT
    source_totals.SourceSalesAmount,
    fact_totals.FactSalesAmount,
    source_totals.SourceSalesAmount - fact_totals.FactSalesAmount
        AS SalesAmountDifference
FROM
(
    SELECT COALESCE(SUM(CAST(source.[Sales Amount] AS DECIMAL(18,2))), 0)
        AS SourceSalesAmount
    FROM [LH_SCD2_Staging].[dbo].[Sales] AS source
    WHERE EXISTS
    (
        SELECT 1 FROM dbo.FactSales AS f
        WHERE f.OrderNumber = source.[Order Number]
    )
) AS source_totals
CROSS JOIN
(
    SELECT COALESCE(SUM(f.SalesAmount), 0) AS FactSalesAmount
    FROM dbo.FactSales AS f
    WHERE EXISTS
    (
        SELECT 1 FROM [LH_SCD2_Staging].[dbo].[Sales] AS source
        WHERE source.[Order Number] = f.OrderNumber
    )
) AS fact_totals;

-- 15. Concise historical-version proof for a portfolio review.
SELECT
    f.OrderNumber,
    f.OrderDate,
    d.CustomerID,
    d.CustomerKey,
    d.City,
    d.IsCurrent,
    d.EffectiveStartDate,
    d.EffectiveEndDate
FROM dbo.FactSales AS f
INNER JOIN dbo.DimCustomer AS d ON d.CustomerKey = f.CustomerKey
ORDER BY f.OrderDate, f.OrderNumber;
