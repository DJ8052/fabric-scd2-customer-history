# SQL

This folder contains the implemented Microsoft Fabric Warehouse SQL for the current SCD Type 2 Customer Dimension milestone and read-only validation queries.

## Warehouse

- [`warehouse/01_create_dim_customer.sql`](warehouse/01_create_dim_customer.sql): implemented and verified creation of `dbo.DimCustomer`. The script is safely rerunnable and contains no enforced key constraints.
- [`warehouse/02_initial_load_dim_customer.sql`](warehouse/02_initial_load_dim_customer.sql): implemented and verified initial load of three current customer rows from `LH_SCD2_Staging.dbo.Customers`.
- [`warehouse/03_create_scd2_dim_customer_procedure.sql`](warehouse/03_create_scd2_dim_customer_procedure.sql): implemented and verified `dbo.usp_LoadDimCustomer_SCD2` processing for changed and new customers.
- [`warehouse/04_validate_scd2_results.sql`](warehouse/04_validate_scd2_results.sql): read-only queries for history review, current and historical rows, version counts, current-row integrity, surrogate-key uniqueness, and status totals.

`FactSales`, orchestration, source-delete handling, additional scenarios, Power BI, and production hardening remain planned.
