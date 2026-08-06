# Microsoft Fabric Environment

## Current State

The current SCD Type 2 environment has been implemented and verified in Microsoft Fabric. It includes a workspace, Dataflow Gen2, a Lakehouse staging layer, a Warehouse, `dbo.DimCustomer`, and `dbo.usp_LoadDimCustomer_SCD2`. A Data Pipeline, `FactSales`, a Semantic Model, and a Power BI Report remain planned.

## Business Objective

**Status: Implemented and Verified for the Current Milestone**

The implemented solution preserves changes to customer attributes so current and historical Customer Dimension records can be examined. The path from the supplied Excel workbook through the Lakehouse and into the Warehouse has been verified. Analytical reporting in Power BI remains planned.

## Workspace

**Status: Implemented and Verified**

`WS_SCD2_Dev` is the implemented Microsoft Fabric development workspace. Capacity assignment, access model, deployment process, and additional environment strategy are not documented yet.

## Lakehouse

**Status: Implemented and Verified**

`LH_SCD2_Staging` is the implemented staging Lakehouse. Its `dbo` schema contains verified tables `dbo.Customers` and `dbo.Sales`. The customer snapshot used for the verified SCD Type 2 scenario includes Ryan Taylor in Forney and new customer Charlie Taylor in Miami. Retention rules and additional operational metadata are not documented yet.

## Warehouse

**Status: Implemented and Verified**

`WH_SCD2`, `dbo.DimCustomer`, and `dbo.usp_LoadDimCustomer_SCD2` are implemented and verified. The initial load inserted three current customer rows. The tested change snapshot produced one expired row, one changed-version insert, and one new-customer insert; an unchanged rerun produced zero changes. No `FactSales` table has been created.

## Dataflow Gen2

**Status: Implemented and Verified**

`DF_SCD2_Staging` is the implemented Dataflow Gen2 used for the initial ingestion layer. It has loaded the current source snapshot into `LH_SCD2_Staging.dbo.Customers` and `LH_SCD2_Staging.dbo.Sales`. Configuration details beyond these confirmed objects are not documented here.

## Planned Data Pipeline

**Status: Planned / Future Implementation**

A Microsoft Fabric Data Pipeline is still planned for future orchestration. No pipeline currently exists. Activities, parameters, triggers, dependencies, error handling, and monitoring behavior remain future implementation decisions.

## Planned Semantic Model

**Status: Planned / Future Implementation**

A Power BI Semantic Model is planned to expose the future Customer Dimension and sales data for analysis. Relationships, measures, date behavior, security, refresh configuration, and naming conventions have not yet been designed.

## Planned Power BI Report

**Status: Planned / Future Implementation**

A Power BI Report is planned to present current-state and historical customer analysis. Report pages, visuals, filters, measures, navigation, and audience-specific requirements remain to be defined during future implementation.

## Current Limitations

- Source deletions are not processed by `dbo.usp_LoadDimCustomer_SCD2`.
- Surrogate-key generation requires serialized procedure executions.
- `FactSales`, pipeline orchestration, additional change scenarios, the Semantic Model, Power BI, and production hardening remain planned.
