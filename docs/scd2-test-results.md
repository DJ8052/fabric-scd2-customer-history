# SCD Type 2 Test Results

## Test Status

**Implemented and Verified**

The current SCD Type 2 Customer Dimension implementation was executed and verified in Microsoft Fabric Warehouse `WH_SCD2` using `dbo.usp_LoadDimCustomer_SCD2`.

## Initial-Load Result

The initial load inserted three current rows into `dbo.DimCustomer`:

- Devon Johnson
- Ryan Taylor
- Joey Taylor

Each customer had one current dimension version before the change scenario was applied.

## Change-Scenario Input

The Lakehouse customer snapshot was changed as follows:

- Ryan Taylor's `City` changed from `Houston` to `Forney`.
- Charlie Taylor was added as a new customer in `Miami`.
- Devon Johnson and Joey Taylor remained unchanged.

## First Stored-Procedure Result

The first execution of `dbo.usp_LoadDimCustomer_SCD2` returned:

| Metric | Result |
|---|---:|
| `ExpiredRowCount` | 1 |
| `InsertedChangedVersionCount` | 1 |
| `InsertedNewCustomerCount` | 1 |

## Final DimCustomer Expected State

The verified result matches the expected final state of five dimension rows: four current rows and one historical row.

| Customer | City | Version state | Expected versions |
|---|---|---|---:|
| Devon Johnson | Unchanged from initial load | Current | 1 |
| Ryan Taylor | Houston | Historical | 2 across both Ryan Taylor rows |
| Ryan Taylor | Forney | Current | 2 across both Ryan Taylor rows |
| Joey Taylor | Unchanged from initial load | Current | 1 |
| Charlie Taylor | Miami | Current | 1 |

The historical Ryan Taylor row has `IsCurrent = 0`; the Forney version has `IsCurrent = 1`. Devon Johnson and Joey Taylor were not updated, and Charlie Taylor was inserted as one new current row.

## Idempotency Result

A second execution against the unchanged scenario snapshot returned zero for all three metrics:

| Metric | Result |
|---|---:|
| `ExpiredRowCount` | 0 |
| `InsertedChangedVersionCount` | 0 |
| `InsertedNewCustomerCount` | 0 |

This verifies idempotency for the tested snapshot.

## Known Limitations

- Source deletions are not processed. A customer missing from a later source snapshot is not expired or otherwise changed by the current procedure.
- Surrogate keys are generated from `MAX(CustomerKey)` plus deterministic `ROW_NUMBER()` values. Procedure executions must be serialized to prevent concurrent executions from selecting the same starting key.
- Only the documented city-change and new-customer scenario has been verified. Additional attribute, null-handling, validation-error, and operational scenarios remain planned.
