# Source Data

## Source System

The supplied source is a Microsoft Excel workbook. The originating operational system, workbook owner, extraction method, and delivery schedule are not specified in the file or repository.

## File

- **File name:** `SCD2_Stored_Procedure_Sample_Data.xlsx`
- **Canonical location:** `data/source/SCD2_Stored_Procedure_Sample_Data.xlsx`
- **Format:** Microsoft Excel workbook (`.xlsx`)
- **Worksheets:** `Sales`, `Sheet2`

## Business Purpose

The workbook provides a small customer and sales dataset for the planned Microsoft Fabric SCD Type 2 Customer Dimension implementation. `Sheet2` contains customer attributes that can be varied in future source snapshots, while `Sales` provides transactions that reference those customers.

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

## Planned Staging Tables

The following logical staging tables are planned; they are documentation only and have not been created:

| Worksheet | Planned staging table | Purpose |
|---|---|---|
| `Sales` | `stg_Sales` | Preserve and validate incoming sales records before downstream processing. |
| `Sheet2` | `stg_Customer` | Preserve and validate the incoming customer snapshot before SCD Type 2 Customer Dimension comparison. |

## Mapping Assumptions

These assumptions are proposed for the future ingestion design and must be validated during implementation:

- `Sheet2` represents the customer source snapshot because its columns describe customer identifiers and attributes.
- `Sheet2.CustomerID` maps to the staged customer business key without transformation.
- `Sales.Customer` maps to the same customer identifier represented by `Sheet2.CustomerID`.
- `Order Number`, `Customer`, and `CustomerID` will be ingested as whole-number identifiers.
- `Sales Amount` will be ingested as a fixed-precision numeric value; precision, scale, and currency remain to be defined.
- `Order Date` will be ingested as a date without a time component.
- `Name` and `City` will initially preserve source text. Any trimming, casing, or standardization rules must be documented before use in change detection.
- Row counts and key checks will be evaluated per worksheet, with the current file serving as the baseline snapshot.

## Future Ingestion Process

1. Place the unchanged baseline workbook in `data/source/` using the documented file name.
2. Validate the file name, required worksheets, required columns, and readable workbook format.
3. Load each worksheet into its corresponding staging table without altering the source workbook.
4. Capture operational metadata such as source file name and ingestion timestamp outside the source columns.
5. Validate row counts, required values, candidate-key uniqueness, data types, and customer referential integrity.
6. Quarantine or reject invalid rows according to rules established during implementation.
7. Use the staged customer snapshot as input to the future SCD Type 2 process.
8. Store intentionally modified workbook snapshots under `data/change-scenarios/` for repeatable change tests.
