# Microsoft Fabric

The verified Fabric environment consists of workspace `WS_SCD2_Dev`, Dataflow Gen2 `DF_SCD2_Staging_Live`, Lakehouse `LH_SCD2_Staging`, Warehouse `WH_SCD2`, and pipeline `PL_SCD2_EndToEnd`.

## Pipeline Activities

1. `Refresh_Staging_Dataflow` — Dataflow activity running `DF_SCD2_Staging_Live`.
2. `Load_DimCustomer_SCD2` — Stored Procedure activity calling `WH_SCD2.dbo.usp_LoadDimCustomer_SCD2` after the Dataflow succeeds.
3. `Load_FactSales` — Stored Procedure activity calling `WH_SCD2.dbo.usp_LoadFactSales` after the dimension activity succeeds.

All three activities have completed successfully in an end-to-end pipeline run. The pipeline now replaces manual Dataflow refresh and procedure execution after each source update.

Excel is only the demonstration source. Equivalent data from APIs, relational databases, ERP systems, CRM systems, cloud storage, or other operational systems can use the same staging contract and Warehouse logic.

Automated validation, monitoring, alerting, scheduling, operational audit storage, the Semantic Model, Power BI assets, screenshots, and production hardening remain future work. No pipeline JSON export is stored in this repository.
