/*
    Target: Microsoft Fabric Warehouse WH_SCD2
    Purpose: One-time, safely rerunnable migration for the already-loaded demo.

    This migration backdates only the three original dimension rows to the
    inferred-history start 1900-01-01. It does not assert that their attributes
    were truly valid since 1900; it provides coverage for demo facts predating
    warehouse implementation. Later SCD Type 2 versions are not changed.
*/

SET NOCOUNT ON;

DECLARE @InferredHistoryStart DATETIME2(6) =
    CAST('1900-01-01' AS DATETIME2(6));
DECLARE @UpdatedInitialDimensionRowCount INT = 0;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Stop if the conservative qualifying rules identify multiple initial rows
    -- for the same business key; that state requires manual investigation.
    IF EXISTS
    (
        SELECT CustomerID
        FROM dbo.DimCustomer
        WHERE CustomerKey <= CAST(3 AS BIGINT)
          AND EffectiveStartDate = CreatedDateTime
          AND EffectiveStartDate > @InferredHistoryStart
        GROUP BY CustomerID
        HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        THROW 50011,
            'Initial-date migration stopped: a qualifying CustomerID has multiple qualifying rows.',
            1;
    END;

    IF
    (
        SELECT COUNT_BIG(*)
        FROM dbo.DimCustomer
        WHERE CustomerKey <= CAST(3 AS BIGINT)
          AND EffectiveStartDate = CreatedDateTime
          AND EffectiveStartDate > @InferredHistoryStart
    ) > 3
    BEGIN
        THROW 50012,
            'Initial-date migration stopped: more than three initial rows qualify.',
            1;
    END;

    UPDATE dbo.DimCustomer
    SET EffectiveStartDate = @InferredHistoryStart
    WHERE CustomerKey <= CAST(3 AS BIGINT)
      AND EffectiveStartDate = CreatedDateTime
      AND EffectiveStartDate > @InferredHistoryStart;

    SET @UpdatedInitialDimensionRowCount = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @UpdatedInitialDimensionRowCount AS UpdatedInitialDimensionRowCount;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
