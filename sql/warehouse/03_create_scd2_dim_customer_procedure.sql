/*
    Target: Microsoft Fabric Warehouse WH_SCD2
    Purpose: Create the proposed SCD Type 2 load procedure for dbo.DimCustomer.

    Assumptions:
    - Execute this script while connected to WH_SCD2.
    - LH_SCD2_Staging is in the same Microsoft Fabric workspace and can be
      referenced from the Warehouse with a three-part name.
    - LH_SCD2_Staging.dbo.Customers exposes CustomerID, Name, and City.
    - Existing CustomerKey values are unique, and procedure executions are serialized.

    Scope:
    - Name and City are the tracked SCD Type 2 attributes.
    - Source deletions are not processed by this version of the procedure.
    - Historical dimension rows are never deleted.
    - FactSales is outside the scope of this script.
*/

CREATE PROCEDURE dbo.usp_LoadDimCustomer_SCD2
AS
BEGIN
    SET NOCOUNT ON;

    -- Use one timestamp for every effective-date and audit change in this load.
    DECLARE @LoadDateTime DATETIME2(6) =
        CAST(SYSUTCDATETIME() AS DATETIME2(6));

    -- Capture result metrics for the final load summary.
    DECLARE @ExpiredRowCount INT = 0;
    DECLARE @InsertedChangedVersionCount INT = 0;
    DECLARE @InsertedNewCustomerCount INT = 0;
    DECLARE @MaxCustomerKey BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Reject source rows without the required customer business key.
        IF EXISTS
        (
            SELECT 1
            FROM [LH_SCD2_Staging].[dbo].[Customers]
            WHERE CustomerID IS NULL
        )
        BEGIN
            THROW 50001,
                'SCD Type 2 load stopped: source CustomerID cannot be null.',
                1;
        END;

        -- Reject duplicate business keys because the source must be one snapshot row per customer.
        IF EXISTS
        (
            SELECT CustomerID
            FROM [LH_SCD2_Staging].[dbo].[Customers]
            GROUP BY CustomerID
            HAVING COUNT_BIG(*) > 1
        )
        BEGIN
            THROW 50002,
                'SCD Type 2 load stopped: source CustomerID must be unique.',
                1;
        END;

        -- Reject null names because dbo.DimCustomer.CustomerName is required.
        IF EXISTS
        (
            SELECT 1
            FROM [LH_SCD2_Staging].[dbo].[Customers]
            WHERE [Name] IS NULL
        )
        BEGIN
            THROW 50003,
                'SCD Type 2 load stopped: source Name cannot be null.',
                1;
        END;

        -- Reject an invalid target state with multiple current versions per customer.
        IF EXISTS
        (
            SELECT CustomerID
            FROM dbo.DimCustomer
            WHERE IsCurrent = CAST(1 AS BIT)
            GROUP BY CustomerID
            HAVING COUNT_BIG(*) > 1
        )
        BEGIN
            THROW 50004,
                'SCD Type 2 load stopped: target contains multiple current rows for a CustomerID.',
                1;
        END;

        -- Capture the key boundary before adding changed versions or new customers.
        SELECT @MaxCustomerKey = COALESCE(MAX(CustomerKey), CAST(0 AS BIGINT))
        FROM dbo.DimCustomer;

        -- Expire current rows only when Name or City differs, including null transitions.
        UPDATE target
        SET
            target.IsCurrent = CAST(0 AS BIT),
            target.EffectiveEndDate = @LoadDateTime,
            target.UpdatedDateTime = @LoadDateTime
        FROM dbo.DimCustomer AS target
        INNER JOIN [LH_SCD2_Staging].[dbo].[Customers] AS source
            ON source.CustomerID = target.CustomerID
        WHERE target.IsCurrent = CAST(1 AS BIT)
          AND
          (
              target.CustomerName <> source.[Name]
              OR (target.CustomerName IS NULL AND source.[Name] IS NOT NULL)
              OR (target.CustomerName IS NOT NULL AND source.[Name] IS NULL)
              OR target.City <> source.City
              OR (target.City IS NULL AND source.City IS NOT NULL)
              OR (target.City IS NOT NULL AND source.City IS NULL)
          );

        SET @ExpiredRowCount = @@ROWCOUNT;

        -- Insert one new current version for each row expired by this execution.
        INSERT INTO dbo.DimCustomer
        (
            CustomerKey,
            CustomerID,
            CustomerName,
            City,
            EffectiveStartDate,
            EffectiveEndDate,
            IsCurrent,
            CreatedDateTime,
            UpdatedDateTime
        )
        SELECT
            @MaxCustomerKey
                + CAST(ROW_NUMBER() OVER (ORDER BY source.CustomerID) AS BIGINT),
            source.CustomerID,
            source.[Name],
            source.City,
            @LoadDateTime,
            CAST('9999-12-31' AS DATETIME2(6)),
            CAST(1 AS BIT),
            @LoadDateTime,
            CAST(NULL AS DATETIME2(6))
        FROM [LH_SCD2_Staging].[dbo].[Customers] AS source
        INNER JOIN dbo.DimCustomer AS expired
            ON expired.CustomerID = source.CustomerID
        WHERE expired.CustomerKey <= @MaxCustomerKey
          AND expired.IsCurrent = CAST(0 AS BIT)
          AND expired.EffectiveEndDate = @LoadDateTime
          AND expired.UpdatedDateTime = @LoadDateTime;

        SET @InsertedChangedVersionCount = @@ROWCOUNT;

        -- Insert customers whose business key has never appeared in the dimension.
        INSERT INTO dbo.DimCustomer
        (
            CustomerKey,
            CustomerID,
            CustomerName,
            City,
            EffectiveStartDate,
            EffectiveEndDate,
            IsCurrent,
            CreatedDateTime,
            UpdatedDateTime
        )
        SELECT
            @MaxCustomerKey
                + CAST(@InsertedChangedVersionCount AS BIGINT)
                + CAST(ROW_NUMBER() OVER (ORDER BY source.CustomerID) AS BIGINT),
            source.CustomerID,
            source.[Name],
            source.City,
            @LoadDateTime,
            CAST('9999-12-31' AS DATETIME2(6)),
            CAST(1 AS BIT),
            @LoadDateTime,
            CAST(NULL AS DATETIME2(6))
        FROM [LH_SCD2_Staging].[dbo].[Customers] AS source
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.DimCustomer AS target
            WHERE target.CustomerID = source.CustomerID
        );

        SET @InsertedNewCustomerCount = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Return auditable metrics; an unchanged rerun returns zero for every count.
        SELECT
            @ExpiredRowCount AS ExpiredRowCount,
            @InsertedChangedVersionCount AS InsertedChangedVersionCount,
            @InsertedNewCustomerCount AS InsertedNewCustomerCount,
            @LoadDateTime AS LoadDateTime;
    END TRY
    BEGIN CATCH
        -- Undo all target changes and preserve the original Fabric Warehouse error.
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
