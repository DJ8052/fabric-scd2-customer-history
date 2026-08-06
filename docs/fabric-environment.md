# Microsoft Fabric Environment

## Current State

The Customer Dimension, FactSales, and end-to-end orchestration solution is implemented and verified in workspace `WS_SCD2_Dev`.

## Verified Objects

| Layer | Object | Status |
|---|---|---|
| Workspace | `WS_SCD2_Dev` | Implemented and verified |
| Dataflow Gen2 | `DF_SCD2_Staging_Live` | Implemented and verified |
| Lakehouse | `LH_SCD2_Staging` | Implemented and verified |
| Lakehouse tables | `dbo.Customers`, `dbo.Sales` | Implemented and verified |
| Warehouse | `WH_SCD2` | Implemented and verified |
| Warehouse tables | `dbo.DimCustomer`, `dbo.FactSales` | Implemented and verified |
| Stored procedures | `dbo.usp_LoadDimCustomer_SCD2`, `dbo.usp_LoadFactSales` | Implemented and verified |
| Pipeline | `PL_SCD2_EndToEnd` | Implemented and verified |

## Pipeline Activities

| Order | Activity | Type | Selection | Dependency |
|---:|---|---|---|---|
| 1 | `Refresh_Staging_Dataflow` | Dataflow | `DF_SCD2_Staging_Live` | Pipeline start |
| 2 | `Load_DimCustomer_SCD2` | Stored Procedure | `WH_SCD2`; `dbo.usp_LoadDimCustomer_SCD2` | Runs after staging refresh succeeds |
| 3 | `Load_FactSales` | Stored Procedure | `WH_SCD2`; `dbo.usp_LoadFactSales` | Runs after dimension load succeeds |

Retry settings were not supplied in the verified implementation notes and are not asserted here. Retry configuration remains an operational-hardening item.

## Verified Execution

All three activities completed successfully. Workbook changes flowed through `DF_SCD2_Staging_Live` to the Lakehouse, customer history was processed through the SCD2 procedure, and new sales were loaded through `dbo.usp_LoadFactSales`. Manual procedure execution is no longer required after each source update.

## Source Contract

Excel is only the demonstration source. The downstream `dbo.Customers` and `dbo.Sales` contracts are source-agnostic and could receive equivalent data from APIs, relational databases, ERP systems, CRM systems, cloud storage, or other operational systems.

## Planned Components

- Automated post-load validation activity
- Monitoring, alerting, scheduling, and operational audit storage
- Semantic Model and Power BI Report
- Portfolio screenshots and polish

## Current Limitations

- `1900-01-01` is inferred rather than authoritative history.
- Source deletions are not processed.
- Date-only orders cannot resolve exact same-day event sequence.
- Maximum-based surrogate-key generation requires serialized execution.
- Retry settings, monitoring, alerting, triggers, and audit storage require further implementation or documentation.
