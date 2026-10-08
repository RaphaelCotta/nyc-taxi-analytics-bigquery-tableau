# Data Quality Rules

This document describes the data-quality approach used in the NYC Taxi Analytics project.

## Data flow

The pipeline uses the following BigQuery layers:

1. `Sales.raw_taxi_trips` — source trip-level records.
2. `Sales.Stage_taxi_trips` — transformed records and data-quality classification.
3. `Sales.analytics_taxi_daily` — daily, payment-type-level analytics.
4. `Sales.vw_taxi_dashboard` — reporting view consumed by Tableau.

## Validations

| Check | Rule or consideration | Purpose |
| --- | --- | --- |
| Timestamps | Detect missing timestamps and drop-off before pick-up | Prevent invalid durations |
| Trip distance | Flag negative distances; a zero-distance trip is not automatically invalid | Avoid excluding legitimate billed trips |
| Fare and revenue | Flag negative or anomalous financial values | Protect reporting metrics |
| Revenue inclusion | Exclude values at or below zero and above 10,000 from the revenue measure | Reduce distortion from invalid or extreme amounts |
| Trip duration | Calculate minutes between pick-up and drop-off where timestamps are valid | Support operational analysis |
| Deduplication | Use window-function logic before incremental merge | Avoid duplicate reporting-grain rows |

These rules describe the project's analytical approach. Exact SQL predicates should be verified against the saved BigQuery queries before publishing the implementation scripts.

## Analytics grain

The reporting table is aggregated by:

- `pickup_date`
- `payment_type`

Incremental `MERGE` logic matches this composite key and handles nullable key values.

## Metric integrity

To avoid averaging pre-aggregated averages in Tableau, the consumption view provides numerator and denominator fields. For example:

```text
Average Fare = SUM(Total Fare) / SUM(Qtd Valid Fares)
Average Distance = SUM(Total Distance) / SUM(Qtd Valid Distances)
```

This preserves weighted averages when users change filters or aggregate across dates and payment types.

## Publication note

The Tableau Public dashboard uses an extract. Scheduled BigQuery queries do not automatically refresh the published Tableau extract.

## Next step

Add the actual SQL used for RAW ingestion, STAGE transformations, incremental `MERGE`, and the reporting view after checking each query against its saved BigQuery version.
