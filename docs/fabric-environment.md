# Microsoft Fabric Environment

## Current State

The Customer Dimension and FactSales solution is implemented and verified in Microsoft Fabric. Pipeline orchestration and reporting remain future phases.

## Verified Objects

| Layer | Object | Status |
|---|---|---|
| Workspace | `WS_SCD2_Dev` | Implemented and verified |
| Dataflow Gen2 | `DF_SCD2_Staging` | Implemented and verified |
| Lakehouse | `LH_SCD2_Staging` | Implemented and verified |
| Lakehouse table | `dbo.Customers` | Implemented and verified |
| Lakehouse table | `dbo.Sales` | Implemented and verified |
| Warehouse | `WH_SCD2` | Implemented and verified |
| Warehouse table | `dbo.DimCustomer` | Implemented and verified |
| Warehouse table | `dbo.FactSales` | Implemented and verified |
| Stored procedure | `dbo.usp_LoadDimCustomer_SCD2` | Implemented and verified |

## Verified Behavior

Dimension processing preserved Ryan Taylor's Houston history, created his current Forney version, inserted Charlie Taylor, and produced zero changes on an unchanged rerun. The original dimension versions were backdated to inferred date `1900-01-01` while their actual creation timestamps were preserved.

The initial FactSales load inserted all three source orders. An unchanged rerun skipped all three and inserted zero. Validation found no unmatched facts or duplicate keys, reconciled `900.00` between source and Warehouse, and confirmed order `1002` points to Ryan Taylor's historical Houston version.

## Source Contract

Excel is only the demonstration source. The downstream `dbo.Customers` and `dbo.Sales` contracts are source-agnostic and can accept equivalent data from APIs, databases, ERP/CRM platforms, files, or cloud storage without downstream SQL changes.

## Planned Components

- Fabric Pipeline
- Semantic Model
- Power BI Report
- Portfolio screenshots and polish

## Current Limitations

- `1900-01-01` is inferred rather than authoritative history.
- Source deletions are not processed.
- Date-only orders cannot resolve exact same-day event sequence.
- Existing fact rows are not updated when attributes for an already-loaded `OrderNumber` change in staging.
- Maximum-based surrogate-key generation requires serialized execution.
- Capacity, deployment, access, monitoring, and production retry strategies need further documentation and hardening.
