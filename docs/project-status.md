# Project Status

## Current Milestone

End-to-end orchestration is implemented and verified in Microsoft Fabric workspace `WS_SCD2_Dev` through pipeline `PL_SCD2_EndToEnd`.

## Completed

- Dataflow Gen2 `DF_SCD2_Staging_Live`
- Lakehouse `LH_SCD2_Staging`
- Warehouse `WH_SCD2`
- SCD Type 2 Customer Dimension
- FactSales table and load
- `dbo.usp_LoadDimCustomer_SCD2`
- `dbo.usp_LoadFactSales`
- Fabric pipeline creation
- Dataflow activity `Refresh_Staging_Dataflow`
- Dimension activity `Load_DimCustomer_SCD2`
- Fact activity `Load_FactSales`
- End-to-end pipeline execution
- Historical customer resolution and idempotent loading

## Verified Pipeline Result

All three activities completed successfully in dependency order. Source changes flowed through the live Dataflow into Lakehouse staging, customer changes were processed automatically, and new sales were loaded without manual procedure execution.

The verified Warehouse now includes customer history through Ryan Taylor's Plano version and Joey Taylor's Annapolis version, new customers including Jammie Chappell, Taylor Jones, and Marie Peoples, and sales through `OrderNumber = 1012`.

## Next Phase

- Automated post-load validation activity
- Semantic Model
- Power BI Report
- Monitoring and alerting
- Optional scheduling or event-based trigger
- Portfolio screenshots and final polish

## Limitations

The `1900-01-01` start remains inferred, source deletions are not handled, and date-only orders cannot resolve same-day sequence. Existing facts are immutable by `OrderNumber`, maximum-based key generation requires serialized execution, and operational audit storage is not yet implemented.
