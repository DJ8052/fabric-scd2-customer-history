# Fabric SCD Type 2 Customer History Demo

## Project Overview

This portfolio project demonstrates a Slowly Changing Dimension (SCD) Type 2 Customer Dimension solution in Microsoft Fabric. The current implementation preserves historical customer attributes, exposes current and prior versions, and provides a traceable path from the source workbook into a Fabric Warehouse.

## Business Problem

Operational customer records are updated as addresses, contact details, classifications, and other attributes change. Overwriting those values removes the historical context needed to answer questions such as:

- What information was known about a customer at a specific point in time?
- When did a customer attribute change?
- Which customer version was active when a business event occurred?

The implemented Customer Dimension models these changes so analysts can distinguish current and historical customer states. A reporting layer remains planned.

## Objectives

- Demonstrate a clear, reproducible SCD Type 2 workflow in Microsoft Fabric.
- Detect relevant changes between incoming customer data and stored history.
- Retain prior customer versions while identifying the current version.
- Support point-in-time analysis with effective-date metadata.
- Document design decisions, assumptions, validation, and operating guidance.
- Present the resulting Customer Dimension history through a Power BI reporting layer.

## Completed Architecture

The implemented and verified solution flow is:

1. The Excel source workbook provides customer and sales snapshots.
2. Dataflow Gen2 `DF_SCD2_Staging` loads the snapshots into `LH_SCD2_Staging.dbo.Customers` and `LH_SCD2_Staging.dbo.Sales`.
3. Warehouse `WH_SCD2` contains `dbo.DimCustomer`.
4. Stored procedure `dbo.usp_LoadDimCustomer_SCD2` detects tracked customer changes, expires prior versions, and inserts changed or new current versions.
5. Read-only validation queries and documented test evidence verify the current SCD Type 2 behavior.

`FactSales`, automated orchestration, additional validation, and Power BI remain planned extensions to this architecture.

## Technology Stack

- Microsoft Fabric
- OneLake
- Fabric Lakehouse and/or Warehouse
- Dataflow Gen2
- Fabric Data Factory pipelines (planned)
- SQL
- Power BI
- Git and Markdown for version control and documentation

## Repository Structure

```text
.
|-- data/
|   |-- source/             # Representative source datasets
|   `-- change-scenarios/   # Controlled customer-change inputs
|-- docs/                   # Architecture and implementation documentation
|-- fabric/                 # Versioned Fabric artifact definitions and guidance
|-- sql/                    # Implemented Warehouse SQL and validation queries
|-- power-bi/               # Power BI model and report assets
|-- AGENTS.md               # Repository guidance for coding agents
|-- LICENSE                 # Project license
`-- README.md               # Project overview
```

## Project Documentation

- [Source data](docs/source-data.md): workbook metadata, field definitions, mapping assumptions, and ingestion plans.
- [Microsoft Fabric environment](docs/fabric-environment.md): implemented environment and planned solution components.
- [Solution architecture](docs/solution-architecture.md): implemented data flow and planned extensions.
- [SCD Type 2 test results](docs/scd2-test-results.md): verified change processing and idempotency evidence.

## Current Implementation Status

**In Development**

The current Microsoft Fabric SCD Type 2 milestone is implemented and verified in workspace `WS_SCD2_Dev`. It includes Dataflow Gen2 `DF_SCD2_Staging`, Lakehouse `LH_SCD2_Staging`, staging tables `dbo.Customers` and `dbo.Sales`, Warehouse `WH_SCD2`, Customer Dimension table `dbo.DimCustomer`, and stored procedure `dbo.usp_LoadDimCustomer_SCD2`.

Scripts `01_create_dim_customer.sql`, `02_initial_load_dim_customer.sql`, and `03_create_scd2_dim_customer_procedure.sql` have been implemented and verified in Microsoft Fabric.

## Verified SCD Type 2 Behavior

- The initial load inserted three current customer rows.
- Ryan Taylor's city change from Houston to Forney expired the Houston version and inserted a new current Forney version.
- Charlie Taylor was inserted as a new current customer in Miami.
- Devon Johnson and Joey Taylor remained unchanged.
- The first procedure run reported one expired row, one changed-version insert, and one new-customer insert.

## Idempotency

A second procedure execution against the same source snapshot returned zero expired rows, zero changed-version inserts, and zero new-customer inserts. This verifies idempotency for the tested scenario.

## Current Limitations

- Source deletions are not processed.
- `MAX(CustomerKey)` plus `ROW_NUMBER()` key generation requires serialized procedure executions.
- `FactSales` has not been created.
- Pipeline orchestration, broader scenario coverage, Power BI, and production hardening have not been implemented.

## Next Planned Work

1. Create and validate `FactSales`.
2. Add orchestration with a Microsoft Fabric Data Pipeline.
3. Add customer-name, null-transition, validation-error, and operational test scenarios.
4. Build the Semantic Model and Power BI Report.
5. Complete production hardening, documentation, and portfolio polish.

## Project Phases

| Phase | Status |
|---|---|
| Phase 1 - Repository Foundation | Complete |
| Phase 2 - Source Data Ingestion | Complete |
| Phase 3 - Fabric Lakehouse Staging | Complete |
| Phase 4 - Fabric Warehouse Design | In Progress |
| Phase 5 - SCD Type 2 Stored Procedure | Complete |
| Phase 6 - Pipeline Orchestration | Planned |
| Phase 7 - Validation & Testing | In Progress |
| Phase 8 - Power BI Reporting | Planned |
| Phase 9 - Documentation & Portfolio Polish | Planned |
