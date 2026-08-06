# Project Status

## Current Milestone

The Customer Dimension and FactSales implementation is complete and verified in Microsoft Fabric workspace `WS_SCD2_Dev`.

## Completed

- Dataflow Gen2 `DF_SCD2_Staging`
- Lakehouse `LH_SCD2_Staging`
- Warehouse `WH_SCD2`
- SCD Type 2 Customer Dimension
- FactSales table and load
- Historical customer resolution
- Dimension and fact validation
- Idempotent ETL reruns
- GitHub repository workflow

## Verified Results

- Ryan Taylor: Houston history preserved and Forney made current.
- Charlie Taylor: inserted as a new customer.
- Dimension rerun: zero expired, changed-version, and new-customer rows.
- Initial FactSales load: 3 source, 0 skipped, 3 inserted.
- FactSales rerun: 3 source, 3 skipped, 0 inserted.
- No unmatched facts or duplicate fact keys.
- Source and Warehouse sales totals: `900.00`; difference: `0.00`.
- Order `1002` resolves to Ryan Taylor's historical Houston version.

## Remaining

- Fabric Pipeline
- Semantic Model
- Power BI Report
- Portfolio screenshots
- Portfolio polish

## Limitations

The `1900-01-01` start is inferred for demo coverage, source deletions are not handled, and date-only orders cannot resolve same-day event sequence. Existing facts are treated as immutable by `OrderNumber`, and maximum-based key generation requires serialized execution.
