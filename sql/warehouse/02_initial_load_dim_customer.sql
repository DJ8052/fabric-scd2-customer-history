/*
    Target: Microsoft Fabric Warehouse WH_SCD2
    Purpose: Perform the one-time initial load of dbo.DimCustomer.

    Assumptions:
    - Execute this script while connected to WH_SCD2.
    - LH_SCD2_Staging is in the same Microsoft Fabric workspace and can be
      referenced from the Warehouse with a three-part name.
    - LH_SCD2_Staging.dbo.Customers exposes CustomerID, Name, and City.
    - CustomerID is unique and non-null in the current source snapshot.
*/

-- Capture one UTC audit timestamp for every row inserted by this execution.
DECLARE @LoadDateTime DATETIME2(6) = CAST(SYSUTCDATETIME() AS DATETIME2(6));

-- Guard the one-time load. If any target row exists, no rows are inserted.
IF NOT EXISTS
(
    SELECT 1
    FROM dbo.DimCustomer
)
BEGIN
    -- Insert the source snapshot using the target column order explicitly.
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
    -- Generate the initial surrogate keys and initialize the SCD Type 2 fields.
    -- 1900-01-01 is an inferred-history start for the first known version. It
    -- lets facts predating warehouse implementation resolve to that version,
    -- but does not prove these attributes were valid since 1900. Production
    -- alternatives include a reliable source-system inception date, historical
    -- extracts, or an Unknown dimension member.
    SELECT
        CAST(ROW_NUMBER() OVER (ORDER BY CustomerID) AS BIGINT) AS CustomerKey,
        CustomerID,
        [Name] AS CustomerName,
        City,
        CAST('1900-01-01' AS DATETIME2(6)) AS EffectiveStartDate,
        CAST('9999-12-31' AS DATETIME2(6)) AS EffectiveEndDate,
        CAST(1 AS BIT) AS IsCurrent,
        @LoadDateTime AS CreatedDateTime,
        CAST(NULL AS DATETIME2(6)) AS UpdatedDateTime
    -- Read the implemented Lakehouse staging table through its SQL endpoint.
    FROM [LH_SCD2_Staging].[dbo].[Customers];
END;
