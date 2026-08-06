/*
    Target: Microsoft Fabric Warehouse WH_SCD2
    Purpose: Provide read-only validation queries for dbo.DimCustomer.

    Each result set is independent. The integrity checks are written to return
    only violations, so an empty result confirms that the tested rule holds.
*/

-- 1. Complete customer history in business-key and effective-date order.
SELECT
    CustomerKey,
    CustomerID,
    CustomerName,
    City,
    EffectiveStartDate,
    EffectiveEndDate,
    IsCurrent,
    CreatedDateTime,
    UpdatedDateTime
FROM dbo.DimCustomer
ORDER BY CustomerID, EffectiveStartDate, CustomerKey;

-- 2. Current customer rows.
SELECT
    CustomerKey,
    CustomerID,
    CustomerName,
    City,
    EffectiveStartDate,
    EffectiveEndDate,
    CreatedDateTime,
    UpdatedDateTime
FROM dbo.DimCustomer
WHERE IsCurrent = CAST(1 AS BIT)
ORDER BY CustomerID, CustomerKey;

-- 3. Historical customer rows.
SELECT
    CustomerKey,
    CustomerID,
    CustomerName,
    City,
    EffectiveStartDate,
    EffectiveEndDate,
    CreatedDateTime,
    UpdatedDateTime
FROM dbo.DimCustomer
WHERE IsCurrent = CAST(0 AS BIT)
ORDER BY CustomerID, EffectiveStartDate, CustomerKey;

-- 4. Customers with more than one dimension version.
SELECT
    CustomerID,
    COUNT_BIG(*) AS VersionCount
FROM dbo.DimCustomer
GROUP BY CustomerID
HAVING COUNT_BIG(*) > 1
ORDER BY CustomerID;

-- 5. Current-row integrity check. Expected result: zero rows.
SELECT
    CustomerID,
    SUM(CASE WHEN IsCurrent = CAST(1 AS BIT) THEN 1 ELSE 0 END) AS CurrentRowCount
FROM dbo.DimCustomer
GROUP BY CustomerID
HAVING SUM(CASE WHEN IsCurrent = CAST(1 AS BIT) THEN 1 ELSE 0 END) <> 1
ORDER BY CustomerID;

-- 6. Surrogate-key uniqueness check. Expected result: zero rows.
SELECT
    CustomerKey,
    COUNT_BIG(*) AS DuplicateKeyCount
FROM dbo.DimCustomer
GROUP BY CustomerKey
HAVING COUNT_BIG(*) > 1
ORDER BY CustomerKey;

-- 7. Row counts by current and historical status.
SELECT
    IsCurrent,
    CASE
        WHEN IsCurrent = CAST(1 AS BIT) THEN 'Current'
        ELSE 'Historical'
    END AS VersionStatus,
    COUNT_BIG(*) AS RowCount
FROM dbo.DimCustomer
GROUP BY IsCurrent
ORDER BY IsCurrent DESC;

