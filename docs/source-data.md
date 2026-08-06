# Source Data

## Source System

The supplied source is a Microsoft Excel workbook. The originating operational system, workbook owner, extraction method, and delivery schedule are not specified in the file or repository.

## File

- **File name:** `SCD2_Stored_Procedure_Sample_Data.xlsx`
- **Canonical location:** `data/source/SCD2_Stored_Procedure_Sample_Data.xlsx`
- **Format:** Microsoft Excel workbook (`.xlsx`)
- **Worksheets:** `Sales`, `Sheet2`

## Business Purpose

The workbook provides the baseline customer and sales dataset for the implemented Microsoft Fabric SCD Type 2 Customer Dimension. `Sheet2` contains customer attributes used to create change snapshots, while `Sales` provides transactions that reference those customers.

## Expected Row Counts

The current baseline workbook contains the following counts. Header rows are excluded from data-row counts.

| Worksheet | Header rows | Data rows | Total populated rows |
|---|---:|---:|---:|
| `Sales` | 1 | 3 | 4 |
| `Sheet2` | 1 | 3 | 4 |

These counts describe the supplied baseline file. Future change-scenario files may have different counts and should document their expected results separately.

## Data Dictionary

### `Sales`

| Column | Inferred source type | Nullable in supplied data | Description |
|---|---|---|---|
| `Order Number` | Integer | No | Identifier for a sales order. Values are unique in the supplied worksheet. |
| `Sales Amount` | Numeric | No | Amount associated with the sales order. The workbook does not specify a currency. |
| `Customer` | Integer | No | Customer reference. All supplied values match `Sheet2.CustomerID`. |
| `Order Date` | Date | No | Date of the sales order. Supplied dates range from 2026-06-18 through 2026-08-01. |

### `Sheet2`

| Column | Inferred source type | Nullable in supplied data | Description |
|---|---|---|---|
| `CustomerID` | Integer | No | Identifier for a customer. Values are unique in the supplied worksheet. |
| `Name` | Text | No | Customer name. |
| `City` | Text | No | Customer city. |

Types are inferred from the populated cells and are not a declared source-system schema.

## Primary and Business Keys

- **Sales business key:** `Sales.Order Number`
- **Customer business key:** `Sheet2.CustomerID`
- **Observed relationship:** `Sales.Customer` references `Sheet2.CustomerID`

The workbook does not declare database constraints. Key designations are based on column meaning, uniqueness in the supplied rows, and the observed relationship between worksheets.

## Potential Data Quality Issues

No nulls, duplicate candidate keys, or unmatched customer references were observed in the supplied six data rows. The following items should still be addressed during ingestion and validation:

- `Sheet2` is a generic worksheet name and does not communicate that it contains customer data.
- Column naming is inconsistent: some headers contain spaces, while `CustomerID` does not.
- `Sales.Customer` is an ambiguous name for a customer identifier.
- The workbook does not specify the currency or precision for `Sales Amount`.
- `Name` is stored as one free-text value, so given and family names cannot be reliably separated from the supplied data alone.
- `City` is free text and has no accompanying state, region, or country, which can make geographic interpretation ambiguous.
- The customer worksheet contains no source change timestamp, effective date, or deletion indicator.
- The workbook contains only three rows per worksheet, so broader null, format, duplicate, and referential-integrity cases are not represented.

## Implemented Staging Tables

Dataflow Gen2 `DF_SCD2_Staging` has loaded the current source snapshot into the `dbo` schema of Lakehouse `LH_SCD2_Staging`:

| Source worksheet | Implemented Lakehouse table | Purpose |
|---|---|---|
| `Sales` | `dbo.Sales` | Holds the current staged sales snapshot for downstream processing. |
| `Sheet2` | `dbo.Customers` | Holds the current staged customer snapshot for future SCD Type 2 Customer Dimension comparison. |

## Implemented Mappings and Remaining Assumptions

The current customer mapping has been exercised by the implemented ingestion and SCD Type 2 flow. Sales remains staged for future `FactSales` work.

- `Sheet2` is used as the customer source snapshot.
- `Sheet2.CustomerID` maps to the customer business key.
- `Name` maps to `dbo.DimCustomer.CustomerName`, and `City` maps to `dbo.DimCustomer.City`.
- The verified flow preserved source text for `Name` and `City`; no additional standardization rule is documented.
- `Sales.Customer` is expected to map to the same customer identifier represented by `Sheet2.CustomerID`; this remains relevant to planned `FactSales` work.
- `Order Number`, `Customer`, and `CustomerID` are represented as whole-number identifiers in the supplied workbook.
- Precision, scale, and currency for `Sales Amount` remain to be defined before `FactSales` implementation.
- `Order Date` is represented as a date without a time component in the source documentation.

## Ingestion Status and Future Process

The baseline workbook was loaded through `DF_SCD2_Staging` into `LH_SCD2_Staging.dbo.Customers` and `LH_SCD2_Staging.dbo.Sales`. The staged customer snapshot was then processed successfully into `WH_SCD2.dbo.DimCustomer`.

## Verified Change Snapshot

The verified change snapshot updated Ryan Taylor's city from `Houston` to `Forney` and added Charlie Taylor in `Miami`. Devon Johnson and Joey Taylor remained unchanged. The stored procedure produced one expired row, one changed-version insert, and one new-customer insert. An unchanged rerun produced zero changes.

See the [SCD Type 2 test results](scd2-test-results.md) for the verified dimension state and limitations.

## Future Ingestion Work

1. Confirm file, worksheet, column, row-count, key, and data-type validation in the Dataflow Gen2 process.
2. Define ingestion audit metadata and invalid-row handling.
3. Store additional modified workbook snapshots under `data/change-scenarios/` for repeatable change tests.
4. Add orchestration and operational monitoring after the manual workflow is finalized.
