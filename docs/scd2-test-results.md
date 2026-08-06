# SCD Type 2 and FactSales Test Results

## Test Status

**Implemented and verified** in Microsoft Fabric Warehouse `WH_SCD2`.

## Dimension Initial Load and Change Processing

The initial load created three customer rows. The verified change snapshot changed Ryan Taylor's city from Houston to Forney, inserted Charlie Taylor in Miami, and left Devon Johnson and Joey Taylor unchanged.

| Metric | First change run | Unchanged rerun |
|---|---:|---:|
| `ExpiredRowCount` | 1 | 0 |
| `InsertedChangedVersionCount` | 1 | 0 |
| `InsertedNewCustomerCount` | 1 | 0 |

Ryan Taylor's Houston row remains historical and his Forney row is current. The unchanged rerun confirms dimension idempotency.

## Temporal-Coverage Update

The three original dimension versions were backdated to `1900-01-01` while preserving their actual `CreatedDateTime` values. Later SCD2 versions retain their real change timestamps. The backdate is an inferred-history assumption used solely to cover facts predating warehouse implementation; it does not establish that those customer attributes were genuinely valid since 1900.

Production alternatives include source-system inception dates, historical extracts, an Unknown dimension member, and source event timestamps.

## FactSales Load Results

| Metric | Initial load | Unchanged rerun |
|---|---:|---:|
| `SourceSalesRowCount` | 3 | 3 |
| `ExistingSalesSkippedCount` | 0 | 3 |
| `InsertedSalesCount` | 3 | 0 |

The unchanged rerun confirms FactSales idempotency at the `OrderNumber` grain.

## Integrity and Reconciliation

- Unmatched facts: 0
- Duplicate `SalesKey` values: 0
- Duplicate `OrderNumber` values: 0
- Source Sales Amount: `900.00`
- Warehouse SalesAmount: `900.00`
- Difference: `0.00`

## Historical-Version Proof

Order `1002` resolved to `CustomerID = 2`, Ryan Taylor, city Houston, with `IsCurrent = 0`. This confirms that the historical sale remains attached to the historical customer version rather than Ryan Taylor's current Forney attributes.

## Known Limitations

- `1900-01-01` is inferred history, not authoritative source history.
- Source deletions are not processed.
- Same-day order and customer-change sequencing is ambiguous because `OrderDate` is date-only.
- The verified rerun used an unchanged source snapshot; changed attributes for an existing `OrderNumber` are not updated by the current fact load.
- `MAX(CustomerKey)` and `MAX(SalesKey)` key generation require serialized execution.
- Pipeline orchestration and production retry handling remain future work.

Excel is only the demonstration source. The downstream staging contract and dimensional SQL are source-agnostic and can accept equivalent operational data without downstream SQL changes.

## Pipeline Orchestration Validation

Pipeline `PL_SCD2_EndToEnd` was executed successfully with all three activities completing in order:

1. `Refresh_Staging_Dataflow`
2. `Load_DimCustomer_SCD2`
3. `Load_FactSales`

Additional customer history and FactSales rows were created automatically after the source workbook was updated and saved. No manual execution of the dimension or fact procedures was required after the source update.

The pipeline added customer history including Ryan Taylor's Plano version and Joey Taylor's Annapolis version, added customers including Jammie Chappell, Taylor Jones, and Marie Peoples, and loaded sales through `OrderNumber = 1012`. `CustomerID` remained the stable business key while new historical versions received new `CustomerKey` values.
