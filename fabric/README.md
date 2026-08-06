# Microsoft Fabric

The verified Fabric environment consists of workspace `WS_SCD2_Dev`, Dataflow Gen2 `DF_SCD2_Staging`, Lakehouse `LH_SCD2_Staging`, and Warehouse `WH_SCD2`.

Implemented and verified Warehouse objects include `dbo.DimCustomer`, `dbo.FactSales`, and `dbo.usp_LoadDimCustomer_SCD2`. The Lakehouse contains verified `dbo.Customers` and `dbo.Sales` staging tables.

Excel is only the demonstration source; equivalent systems can use the same downstream staging contract and dimensional logic.

Fabric Pipeline orchestration, the Semantic Model, Power BI report assets, screenshots, and production hardening remain planned. Future Fabric artifact definitions and deployment guidance belong in this folder.
