# Change Scenarios

This folder is reserved for modified source files that simulate SCD Type 2 Customer Dimension changes across successive loads. The first change scenario has been applied and verified in Microsoft Fabric; additional scenario files remain planned.

The unchanged baseline workbook belongs only in `data/source/`. Each modified scenario will be documented with its expected outcome when implementation begins.

## Verified Scenario: City Change and New Customer

**Status: Implemented and Verified**

The verified source snapshot made two changes:

- Ryan Taylor's city changed from `Houston` to `Forney`.
- Charlie Taylor was added as a new customer in `Miami`.
- Devon Johnson and Joey Taylor remained unchanged.

The first stored-procedure execution produced:

- One existing current row expired.
- One changed customer version was inserted.
- One new customer was inserted.

Ryan Taylor now has a historical Houston version and a current Forney version. Charlie Taylor has one current Miami version. A second procedure execution returned zero expired rows, zero changed-version inserts, and zero new-customer inserts.

Detailed evidence is documented in [`docs/scd2-test-results.md`](../../docs/scd2-test-results.md).

## Planned Additional Scenarios

- Customer name changes
- Multiple tracked attributes changing together
- Null and non-null city transitions
- Source validation failures
- Additional idempotency and operational tests
