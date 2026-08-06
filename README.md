# Fabric SCD Type 2 Customer History Demo

## Project Overview

This portfolio project will demonstrate how to build and communicate a Slowly Changing Dimension (SCD) Type 2 Customer Dimension solution in Microsoft Fabric. The completed solution will preserve historical customer attributes, expose both current and prior versions, and provide a traceable path from source data through analytics.

## Business Problem

Operational customer records are updated as addresses, contact details, classifications, and other attributes change. Overwriting those values removes the historical context needed to answer questions such as:

- What information was known about a customer at a specific point in time?
- When did a customer attribute change?
- Which customer version was active when a business event occurred?

The planned Customer Dimension will model these changes so analysts can report accurately against both current and historical customer states.

## Objectives

- Demonstrate a clear, reproducible SCD Type 2 workflow in Microsoft Fabric.
- Detect relevant changes between incoming customer data and stored history.
- Retain prior customer versions while identifying the current version.
- Support point-in-time analysis with effective-date metadata.
- Document design decisions, assumptions, validation, and operating guidance.
- Present the resulting Customer Dimension history through a Power BI reporting layer.

## Planned Architecture

The planned data flow is:

1. Representative customer source data and controlled change scenarios.
2. Ingestion and staging in Microsoft Fabric.
3. Change detection and SCD Type 2 Customer Dimension processing.
4. Curated Customer Dimension history in a Warehouse for analytics.
5. Validation, monitoring, and documented test scenarios.
6. A Power BI semantic model and report for current-state and point-in-time analysis.

Implementation details and Fabric object definitions will be added as the project develops.

## Planned Technology Stack

- Microsoft Fabric
- OneLake
- Fabric Lakehouse and/or Warehouse
- Fabric Data Factory pipelines
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
|-- sql/                    # Future SQL scripts
|-- power-bi/               # Power BI model and report assets
|-- AGENTS.md               # Repository guidance for coding agents
|-- LICENSE                 # Project license
`-- README.md               # Project overview
```

Detailed workbook metadata, field definitions, mapping assumptions, and ingestion plans are available in the [source data documentation](docs/source-data.md).

## Project Status

**In Development**

The repository currently contains the project structure, the baseline source workbook, and source-data planning documentation. SQL implementation, pipelines, Microsoft Fabric Lakehouse and Warehouse objects, validation evidence, and Power BI reports are planned for later phases and do not currently exist.

## Project Phases

| Phase | Status |
|---|---|
| Phase 1 - Repository Foundation | Complete |
| Phase 2 - Source Data Ingestion | Planned |
| Phase 3 - Fabric Lakehouse Staging | Planned |
| Phase 4 - Fabric Warehouse Design | Planned |
| Phase 5 - SCD Type 2 Stored Procedure | Planned |
| Phase 6 - Pipeline Orchestration | Planned |
| Phase 7 - Validation & Testing | Planned |
| Phase 8 - Power BI Reporting | Planned |
| Phase 9 - Documentation & Portfolio Polish | Planned |
