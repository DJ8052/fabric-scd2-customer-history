/*
    Target: Microsoft Fabric Warehouse WH_SCD2
    Purpose: Create the proposed SCD Type 2 Customer Dimension table.

    Execute this script while connected to WH_SCD2. The script intentionally
    defines no enforced primary-key or unique constraint because Fabric
    Warehouse does not enforce those constraints.
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.tables AS t
    INNER JOIN sys.schemas AS s
        ON s.schema_id = t.schema_id
    WHERE s.name = 'dbo'
      AND t.name = 'DimCustomer'
)
BEGIN
    CREATE TABLE dbo.DimCustomer
    (
        -- Surrogate key; future load logic must generate and validate uniqueness.
        CustomerKey BIGINT NOT NULL,

        -- Stable source-system business key used to identify a customer.
        CustomerID BIGINT NOT NULL,

        -- Tracked SCD Type 2 attributes. A Name or City change creates a new version.
        CustomerName VARCHAR(200) NOT NULL,
        City VARCHAR(100) NULL,

        -- Inclusive timestamp from which this dimension version is effective.
        EffectiveStartDate DATETIME2(6) NOT NULL,

        -- End of this version's effective range. Current rows must use 9999-12-31.
        EffectiveEndDate DATETIME2(6) NOT NULL,

        -- Identifies the active version for a CustomerID; 1=current, 0=historical.
        IsCurrent BIT NOT NULL,

        -- Audit timestamps for creation and the most recent update of this row.
        CreatedDateTime DATETIME2(6) NOT NULL,
        UpdatedDateTime DATETIME2(6) NULL
    );
END;

