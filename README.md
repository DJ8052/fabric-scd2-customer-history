# Microsoft Fabric SCD Type 2 Customer History Pipeline

## Project Overview

This portfolio project implements and validates a Slowly Changing Dimension (SCD) Type 2 customer-history solution in Microsoft Fabric. It stages customer and sales data in a Lakehouse, preserves customer attribute history in a Warehouse dimension, and assigns each sales order to the customer version valid on its order date.

Excel is only the demonstration source. The downstream architecture is source-agnostic: equivalent data could come from REST APIs, SQL Server, Azure SQL, Oracle, PostgreSQL, MySQL, Snowflake, Databricks, SAP, Salesforce, SharePoint, CSV, Parquet, cloud storage, ERP systems, CRM systems, or other operational platforms. No downstream SQL changes are required while the `dbo.Customers` and `dbo.Sales` staging contracts remain consistent.

## Business Problem

Operational systems commonly overwrite customer attributes. That destroys the historical context required to determine which customer name, city, or classification applied when a transaction occurred. This solution retains prior customer versions while maintaining one current version and resolves facts against that history.

## Architecture

Pipeline `PL_SCD2_EndToEnd` orchestrates Dataflow Gen2 `DF_SCD2_Staging_Live`, refreshes Lakehouse `LH_SCD2_Staging`, then calls `dbo.usp_LoadDimCustomer_SCD2` and `dbo.usp_LoadFactSales` in Warehouse `WH_SCD2`. Semantic modeling and reporting remain future phases.

## Technology Stack

- Microsoft Fabric workspace `WS_SCD2_Dev`
- Dataflow Gen2
- OneLake Lakehouse and its SQL analytics endpoint
- Fabric Warehouse and T-SQL
- Excel as demonstration input only
- Git and GitHub
- Power BI planned

## Repository Structure

```text
.
|-- data/
|   |-- source/                  # Demonstration workbook and source notes
|   `-- change-scenarios/        # Controlled SCD2 change inputs
|-- docs/                        # Architecture, environment, status, and evidence
|-- fabric/                      # Fabric artifact guidance
|-- power-bi/                    # Planned semantic-model and report assets
|-- sql/
|   `-- warehouse/               # Warehouse DDL, loads, migration, and validation
|-- AGENTS.md
|-- LICENSE
`-- README.md
```

## End-to-End Workflow

1. A replaceable operational source supplies customer and sales records.
2. The user runs `PL_SCD2_EndToEnd` once after saving source changes.
3. `Refresh_Staging_Dataflow` runs `DF_SCD2_Staging_Live`, loading `dbo.Customers` and `dbo.Sales` into `LH_SCD2_Staging`.
4. After the refresh succeeds, `Load_DimCustomer_SCD2` calls `dbo.usp_LoadDimCustomer_SCD2` in `WH_SCD2`.
5. After the dimension succeeds, `Load_FactSales` calls `dbo.usp_LoadFactSales` in `WH_SCD2`.
6. Fact loading resolves each order to exactly one customer version using inclusive-start and exclusive-end day-grain boundaries.
7. Read-only SQL verifies keys, mappings, totals, temporal attribution, reconciliation, and rerun behavior.

## Live Demo Workflow

1. Edit and save the demonstration workbook.
2. Run `PL_SCD2_EndToEnd`.
3. Verify the resulting customer history.
4. Verify new `dbo.FactSales` rows.
5. Verify historical customer attribution.

## Engineering Decisions

- Stable staging contracts decouple downstream SQL from the source platform.
- `Name` and `City` are tracked SCD2 attributes.
- `OrderNumber` is the FactSales grain and durable source identifier.
- Initial `1900-01-01` coverage is explicitly inferred rather than presented as authoritative history.
- Date-only sales use a documented day-grain temporal rule.
- Loads validate source and target integrity and are safely rerunnable for the tested snapshots.
- Surrogate keys use `MAX(...) + ROW_NUMBER()` and therefore require serialized execution.

## Implemented Components

| Component | Status |
|---|---|
| Dataflow Gen2 `DF_SCD2_Staging_Live` | Implemented and verified |
| Lakehouse `LH_SCD2_Staging` | Implemented and verified |
| Lakehouse `dbo.Customers`, `dbo.Sales` | Implemented and verified |
| Warehouse `WH_SCD2` | Implemented and verified |
| `dbo.DimCustomer` | Implemented and verified |
| `dbo.usp_LoadDimCustomer_SCD2` | Implemented and verified |
| `dbo.usp_LoadFactSales` | Implemented and verified |
| Initial temporal backfill | Implemented and verified |
| `dbo.FactSales` | Implemented and verified |
| Historical customer resolution | Implemented and verified |
| Dimension and fact rerun behavior | Implemented and verified |
| Pipeline `PL_SCD2_EndToEnd` | Implemented and verified |
| Semantic Model | Planned |
| Power BI Report | Planned |

## Validation Results

The original SCD2 scenario preserved Ryan Taylor's historical Houston version, created his Forney version, and inserted Charlie Taylor. Later pipeline runs added Ryan Taylor's Plano version, changed Joey Taylor from Los Angeles to Annapolis, and added Jammie Chappell, Taylor Jones, and Marie Peoples. `CustomerID` remained stable while each historical version received its own `CustomerKey`.

The initial FactSales load and unchanged rerun verified idempotency. Subsequent pipeline execution loaded sales through `OrderNumber = 1012`. All three pipeline activities succeeded, and order `1002` remained assigned to Ryan Taylor's historical Houston version (`CustomerID = 2`, `IsCurrent = 0`).

See [SCD Type 2 and FactSales test results](docs/scd2-test-results.md) for recorded evidence.

## Business Value

- Preserves customer history instead of overwriting it.
- Maintains historically correct sales attribution at the available day grain.
- Supports repeatable, dependency-controlled pipeline execution.
- Separates replaceable ingestion from stable dimensional processing.
- Provides auditable validation suitable for engineering review.

## Known Limitations

- `1900-01-01` is an inferred-history start, not proof that initial attributes were valid from that date.
- Source deletions are not implemented.
- Same-day customer changes and orders are ambiguous because `OrderDate` has no time component.
- Existing orders are treated as immutable by `OrderNumber`; changed source attributes for an already-loaded order are not updated.
- `MAX(...) + ROW_NUMBER()` surrogate-key generation assumes serialized execution.
- Automated post-load validation is not yet a pipeline activity.
- Monitoring, alerting, scheduling, and operational audit storage remain future work.
- The small synthetic dataset does not demonstrate production scale or performance.

## Future Enhancements

- Add an automated post-load validation activity.
- Add monitoring and alerting.
- Add an optional schedule or event-based trigger.
- Build the Semantic Model.
- Build the Power BI report.
- Capture source event timestamps for precise same-day ordering.
- Define source-deletion and changed-order policies, including an Unknown-member strategy.
- Add broader data-quality, failure, null-transition, and scale tests.
- Capture portfolio screenshots and complete presentation polish.

## Architecture Diagram

```mermaid
flowchart TD
    OperationalSource["Replaceable Source<br/>(Excel / API / Database / ERP / CRM / Files)"]
    PIPE["Pipeline<br/>PL_SCD2_EndToEnd"]
    DF["Refresh_Staging_Dataflow<br/>DF_SCD2_Staging_Live"]
    LH["Lakehouse<br/>LH_SCD2_Staging"]
    DIM["Load_DimCustomer_SCD2<br/>dbo.usp_LoadDimCustomer_SCD2"]
    FACT["Load_FactSales<br/>dbo.usp_LoadFactSales"]
    WH["Warehouse<br/>WH_SCD2"]
    SEM["Semantic Model<br/>(Planned)"]
    PBI["Power BI<br/>(Planned)"]

    PIPE -. orchestrates .-> DF
    PIPE -. orchestrates .-> DIM
    PIPE -. orchestrates .-> FACT
    OperationalSource --> DF
    DF --> LH
    LH --> DIM
    DIM --> FACT
    FACT --> WH
    WH --> SEM
    SEM --> PBI
```

## Git Workflow

FactSales was developed on `feature/fact-sales`, merged into `main`, and its feature branch was deleted. The current pipeline documentation work is on `feature/fabric-pipeline`; this branch has not yet been merged.

## Lessons Learned

- Historical facts require dimension coverage before the earliest business event.
- Inferred history can make a demonstration coherent only when the assumption is visible.
- Date-only events support day-grain attribution, not exact same-day sequencing.
- Idempotency requires duplicate prevention and explicit rerun evidence.
- Stable staging contracts keep dimensional SQL independent of the originating platform.

## Resume Here

The Dataflow, Lakehouse, Warehouse dimension, SCD2 procedure, FactSales procedure, and end-to-end pipeline are implemented and verified. Resume with automated post-load validation, monitoring, optional scheduling, the Semantic Model, Power BI report, screenshots, and portfolio polish. See [project status](docs/project-status.md) for the concise handoff.
