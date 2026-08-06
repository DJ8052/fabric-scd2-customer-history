/*
    Target: Microsoft Fabric Warehouse WH_SCD2
    Purpose: Provide read-only portfolio demonstration queries.

    Every statement is read-only. The queries do not execute procedures or
    create, update, or delete Warehouse objects or data.
*/

-- A. Complete customer history: shows every version in effective-date order.
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

-- B. Current customer rows: shows the latest version for each customer.
SELECT
    CustomerKey,
    CustomerID,
    CustomerName,
    City,
    EffectiveStartDate,
    EffectiveEndDate
FROM dbo.DimCustomer
WHERE IsCurrent = CAST(1 AS BIT)
ORDER BY CustomerID;

-- C. Historical customer rows: demonstrates preserved prior attributes.
SELECT
    CustomerKey,
    CustomerID,
    CustomerName,
    City,
    EffectiveStartDate,
    EffectiveEndDate
FROM dbo.DimCustomer
WHERE IsCurrent = CAST(0 AS BIT)
ORDER BY CustomerID, EffectiveStartDate;

-- D. Complete FactSales contents: shows the one-row-per-order fact grain.
SELECT
    SalesKey,
    OrderNumber,
    CustomerKey,
    SalesAmount,
    OrderDate,
    CreatedDateTime
FROM dbo.FactSales
ORDER BY OrderNumber;

-- E. Historical attribution: shows facts assigned to noncurrent customer versions.
SELECT
    fact.OrderNumber,
    fact.OrderDate,
    fact.SalesAmount,
    customer.CustomerID,
    customer.CustomerKey,
    customer.CustomerName,
    customer.City,
    customer.IsCurrent,
    customer.EffectiveStartDate,
    customer.EffectiveEndDate
FROM dbo.FactSales AS fact
INNER JOIN dbo.DimCustomer AS customer
    ON customer.CustomerKey = fact.CustomerKey
WHERE customer.IsCurrent = CAST(0 AS BIT)
ORDER BY fact.OrderDate, fact.OrderNumber;

-- F. CustomerID 2 history: provides a focused Ryan Taylor SCD2 walkthrough.
SELECT
    CustomerKey,
    CustomerID,
    CustomerName,
    City,
    EffectiveStartDate,
    EffectiveEndDate,
    IsCurrent
FROM dbo.DimCustomer
WHERE CustomerID = CAST(2 AS BIGINT)
ORDER BY EffectiveStartDate, CustomerKey;

-- G. Duplicate OrderNumber check. Expected result: zero rows.
SELECT
    OrderNumber,
    COUNT_BIG(*) AS DuplicateOrderCount
FROM dbo.FactSales
GROUP BY OrderNumber
HAVING COUNT_BIG(*) > 1
ORDER BY OrderNumber;

-- H. Duplicate CustomerKey check. Expected result: zero rows.
SELECT
    CustomerKey,
    COUNT_BIG(*) AS DuplicateCustomerKeyCount
FROM dbo.DimCustomer
GROUP BY CustomerKey
HAVING COUNT_BIG(*) > 1
ORDER BY CustomerKey;

-- I. Customer-version and order summary: connects each version to fact activity.
SELECT
    customer.CustomerID,
    customer.CustomerKey,
    customer.CustomerName,
    customer.City,
    customer.IsCurrent,
    customer.EffectiveStartDate,
    customer.EffectiveEndDate,
    COUNT_BIG(fact.SalesKey) AS OrderCount,
    COALESCE(SUM(fact.SalesAmount), CAST(0 AS DECIMAL(18,2))) AS TotalSalesAmount
FROM dbo.DimCustomer AS customer
LEFT JOIN dbo.FactSales AS fact
    ON fact.CustomerKey = customer.CustomerKey
GROUP BY
    customer.CustomerID,
    customer.CustomerKey,
    customer.CustomerName,
    customer.City,
    customer.IsCurrent,
    customer.EffectiveStartDate,
    customer.EffectiveEndDate
ORDER BY customer.CustomerID, customer.EffectiveStartDate, customer.CustomerKey;

-- J. Latest orders: presents the most recent staged business events first.
SELECT
    fact.OrderNumber,
    fact.OrderDate,
    fact.SalesAmount,
    customer.CustomerID,
    customer.CustomerName,
    customer.City,
    customer.CustomerKey,
    customer.IsCurrent
FROM dbo.FactSales AS fact
INNER JOIN dbo.DimCustomer AS customer
    ON customer.CustomerKey = fact.CustomerKey
ORDER BY fact.OrderDate DESC, fact.OrderNumber DESC;
