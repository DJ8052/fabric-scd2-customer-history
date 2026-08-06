/*
    Target: Microsoft Fabric Warehouse WH_SCD2
    Purpose: Incrementally load implemented dbo.FactSales from Lakehouse staging.
    Grain: one row per source sales order, identified by Order Number.

    Day-grain temporal rule:
    Source Order Date is date-only, while DimCustomer boundaries contain time.
    The lookup casts both boundaries to DATE, uses an inclusive start and an
    exclusive end, and treats a version beginning on a date as valid for that
    entire date. The previous version is excluded on that date. Same-day event
    ordering cannot be resolved accurately without an order timestamp. This is
    acceptable for the demo; production ingestion should capture event times.

    Execute while connected to WH_SCD2 after loading dbo.DimCustomer. Existing
    keys must be valid, and executions must be serialized because MAX(SalesKey)
    surrogate-key generation is not concurrency-safe.
*/

SET NOCOUNT ON;

DECLARE @LoadDateTime DATETIME2(6) = CAST(SYSUTCDATETIME() AS DATETIME2(6));
DECLARE @SourceSalesRowCount BIGINT = 0;
DECLARE @ExistingSalesSkippedCount BIGINT = 0;
DECLARE @InsertedSalesCount INT = 0;
DECLARE @MaxSalesKey BIGINT;

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT @SourceSalesRowCount = COUNT_BIG(*)
    FROM [LH_SCD2_Staging].[dbo].[Sales];

    -- Required source fields must be present.
    IF EXISTS
    (
        SELECT 1
        FROM [LH_SCD2_Staging].[dbo].[Sales]
        WHERE [Order Number] IS NULL
           OR [Customer] IS NULL
           OR [Order Date] IS NULL
           OR [Sales Amount] IS NULL
    )
    BEGIN
        THROW 50101, 'FactSales load stopped: required source values cannot be null.', 1;
    END;

    IF EXISTS
    (
        SELECT 1 FROM [LH_SCD2_Staging].[dbo].[Sales]
        WHERE [Sales Amount] < 0
    )
    BEGIN
        THROW 50105, 'FactSales load stopped: Sales Amount must be greater than or equal to zero.', 1;
    END;

    IF EXISTS
    (
        SELECT 1 FROM [LH_SCD2_Staging].[dbo].[Sales]
        WHERE [Order Number] <= 0
    )
    BEGIN
        THROW 50106, 'FactSales load stopped: Order Number must be greater than zero.', 1;
    END;

    IF EXISTS
    (
        SELECT 1 FROM [LH_SCD2_Staging].[dbo].[Sales]
        WHERE [Customer] <= 0
    )
    BEGIN
        THROW 50107, 'FactSales load stopped: Customer must be greater than zero.', 1;
    END;

    IF EXISTS
    (
        SELECT [Order Number]
        FROM [LH_SCD2_Staging].[dbo].[Sales]
        GROUP BY [Order Number]
        HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        THROW 50102, 'FactSales load stopped: duplicate Order Number values exist in the source.', 1;
    END;

    -- Reject corrupt target key and business-key states before generating keys.
    IF EXISTS
    (
        SELECT OrderNumber FROM dbo.FactSales
        GROUP BY OrderNumber HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        THROW 50108, 'FactSales load stopped: dbo.FactSales contains duplicate OrderNumber values.', 1;
    END;

    IF EXISTS
    (
        SELECT SalesKey FROM dbo.FactSales
        GROUP BY SalesKey HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        THROW 50109, 'FactSales load stopped: dbo.FactSales contains duplicate SalesKey values.', 1;
    END;

    IF EXISTS
    (
        SELECT CustomerKey FROM dbo.DimCustomer
        GROUP BY CustomerKey HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        THROW 50110, 'FactSales load stopped: dbo.DimCustomer contains duplicate CustomerKey values.', 1;
    END;

    IF EXISTS
    (
        SELECT CustomerID FROM dbo.DimCustomer
        WHERE IsCurrent = CAST(1 AS BIT)
        GROUP BY CustomerID HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        THROW 50111, 'FactSales load stopped: a CustomerID has multiple current DimCustomer rows.', 1;
    END;

    -- Every source sale must resolve to exactly one day-grain dimension version.
    IF EXISTS
    (
        SELECT 1
        FROM [LH_SCD2_Staging].[dbo].[Sales] AS source
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.DimCustomer AS customer
            WHERE source.[Customer] = customer.CustomerID
              AND source.[Order Date] >= CAST(customer.EffectiveStartDate AS DATE)
              AND source.[Order Date] < CAST(customer.EffectiveEndDate AS DATE)
        )
    )
    BEGIN
        THROW 50103, 'FactSales load stopped: a source sale maps to zero customer versions.', 1;
    END;

    IF EXISTS
    (
        SELECT source.[Order Number]
        FROM [LH_SCD2_Staging].[dbo].[Sales] AS source
        INNER JOIN dbo.DimCustomer AS customer
            ON source.[Customer] = customer.CustomerID
           AND source.[Order Date] >= CAST(customer.EffectiveStartDate AS DATE)
           AND source.[Order Date] < CAST(customer.EffectiveEndDate AS DATE)
        GROUP BY source.[Order Number]
        HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        THROW 50104, 'FactSales load stopped: a source sale maps to multiple customer versions.', 1;
    END;

    SELECT @ExistingSalesSkippedCount = COUNT_BIG(*)
    FROM [LH_SCD2_Staging].[dbo].[Sales] AS source
    WHERE EXISTS
    (
        SELECT 1 FROM dbo.FactSales AS target
        WHERE target.OrderNumber = source.[Order Number]
    );

    SELECT @MaxSalesKey = COALESCE(MAX(SalesKey), CAST(0 AS BIGINT))
    FROM dbo.FactSales;

    -- Define the exact insert scope before ROW_NUMBER so keys are generated only
    -- for source orders that will actually be inserted.
    ;WITH NewSales AS
    (
        SELECT
            source.[Order Number] AS OrderNumber,
            customer.CustomerKey,
            CAST(source.[Sales Amount] AS DECIMAL(18,2)) AS SalesAmount,
            source.[Order Date] AS OrderDate
        FROM [LH_SCD2_Staging].[dbo].[Sales] AS source
        INNER JOIN dbo.DimCustomer AS customer
            ON source.[Customer] = customer.CustomerID
           AND source.[Order Date] >= CAST(customer.EffectiveStartDate AS DATE)
           AND source.[Order Date] < CAST(customer.EffectiveEndDate AS DATE)
        WHERE NOT EXISTS
        (
            SELECT 1 FROM dbo.FactSales AS target
            WHERE target.OrderNumber = source.[Order Number]
        )
    ),
    NumberedNewSales AS
    (
        SELECT
            @MaxSalesKey
                + CAST(ROW_NUMBER() OVER (ORDER BY OrderNumber) AS BIGINT) AS SalesKey,
            OrderNumber, CustomerKey, SalesAmount, OrderDate
        FROM NewSales
    )
    INSERT INTO dbo.FactSales
    (
        SalesKey, OrderNumber, CustomerKey, SalesAmount, OrderDate, CreatedDateTime
    )
    SELECT
        SalesKey, OrderNumber, CustomerKey, SalesAmount, OrderDate, @LoadDateTime
    FROM NumberedNewSales;

    SET @InsertedSalesCount = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT
        @SourceSalesRowCount AS SourceSalesRowCount,
        @ExistingSalesSkippedCount AS ExistingSalesSkippedCount,
        @InsertedSalesCount AS InsertedSalesCount,
        @LoadDateTime AS LoadDateTime;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
