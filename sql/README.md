# SQL

This folder contains the implemented and verified Microsoft Fabric Warehouse SQL for the SCD Type 2 Customer Dimension and FactSales solution.

Excel is only the demonstration source. These scripts depend on the Lakehouse staging contract, not the originating platform, so equivalent data can arrive from APIs, relational databases, ERP/CRM systems, files, or cloud storage without downstream SQL changes.

## Warehouse Scripts

| Script | Purpose | Status |
|---|---|---|
| [`01_create_dim_customer.sql`](warehouse/01_create_dim_customer.sql) | Safely creates `dbo.DimCustomer` without enforced key constraints. | Implemented and verified |
| [`02_initial_load_dim_customer.sql`](warehouse/02_initial_load_dim_customer.sql) | Loads the first known customer versions using inferred `1900-01-01` effective starts while preserving actual creation timestamps. | Implemented and verified |
| [`03_create_scd2_dim_customer_procedure.sql`](warehouse/03_create_scd2_dim_customer_procedure.sql) | Creates `dbo.usp_LoadDimCustomer_SCD2` for changed and new customers. | Implemented and verified |
| [`04_validate_scd2_results.sql`](warehouse/04_validate_scd2_results.sql) | Validates complete history, current/historical rows, version counts, and key integrity. | Implemented and verified |
| [`05_create_fact_sales.sql`](warehouse/05_create_fact_sales.sql) | Safely creates `dbo.FactSales` at one row per source sales order. | Implemented and verified |
| [`05a_backfill_initial_dimension_start_dates.sql`](warehouse/05a_backfill_initial_dimension_start_dates.sql) | Backdates only qualifying original dimension rows to the inferred-history start. | Implemented and verified |
| [`06_load_fact_sales.sql`](warehouse/06_load_fact_sales.sql) | Validates and idempotently loads sales with historical day-grain `CustomerKey` resolution. | Implemented and verified |
| [`07_validate_fact_sales.sql`](warehouse/07_validate_fact_sales.sql) | Validates fact integrity, temporal assignment, reconciliation, totals, and historical proof. | Implemented and verified |

## Execution Notes

- Recommended script order: `01`, `02`, `03`, `05`, `05a`, `04`, `06`, then `07`. Script `05a` safely updates zero rows after a fresh `02` load and exists primarily for the previously loaded demo environment. Execute the SCD2 procedure as required before loading facts, then use `04` to validate the resulting dimension state.
- Submit `05a` and `06` as complete batches so `BEGIN TRANSACTION`, `COMMIT`, and `ROLLBACK` execute in the same Fabric query-editor session.
- The initial `1900-01-01` boundary is inferred for demonstration coverage and is not authoritative history.
- Same-day event order remains ambiguous while source `OrderDate` is date-only.
- Existing facts are treated as immutable by `OrderNumber`; the fact load does not update an already-loaded order.
- `MAX(CustomerKey)` and `MAX(SalesKey)` plus `ROW_NUMBER()` require serialized executions.
- Source deletions and automated pipeline orchestration are not implemented.
