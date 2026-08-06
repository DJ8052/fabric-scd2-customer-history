/*
    Target: Microsoft Fabric Warehouse WH_SCD2
    Purpose: Create the implemented and verified sales fact table.

    Grain: one row per source sales order. OrderNumber is the durable source
    business identifier and acts as a degenerate dimension in the fact table.

    CustomerKey identifies the historical dbo.DimCustomer version valid on
    OrderDate. The table intentionally uses no IDENTITY, SEQUENCE, enforced
    foreign key, or enforced unique constraint. Load and validation logic
    generate keys and enforce the applicable relationship and uniqueness rules.
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.tables AS t
    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name = 'dbo' AND t.name = 'FactSales'
)
BEGIN
    CREATE TABLE dbo.FactSales
    (
        SalesKey BIGINT NOT NULL,
        OrderNumber BIGINT NOT NULL,
        CustomerKey BIGINT NOT NULL,
        SalesAmount DECIMAL(18,2) NOT NULL,
        OrderDate DATE NOT NULL,
        CreatedDateTime DATETIME2(6) NOT NULL
    );
END;
