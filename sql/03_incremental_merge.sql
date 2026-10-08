-- NYC Taxi Analytics | 03 - STAGE to ANALYTICS incremental MERGE
-- Updated to match the current analytics_taxi_daily schema.
-- Tested manually for 2022-07-01; the BigQuery MERGE completed successfully.
-- The scheduled query "Taxi - Staging to Analytics" was updated in BigQuery.
--
-- Source: learning-bigquery-509717.sales.Stage_taxi_trips
-- Target: learning-bigquery-509717.sales.analytics_taxi_daily
-- Grain: pickup_date + payment_type
--
-- NOTE: The date is intentionally fixed to 2022-07-01 for this lab.
-- A daily schedule with this fixed filter reprocesses the same date,
-- not the current day. Parameterize the date before claiming a
-- rolling daily incremental pipeline.
-- NOTE: The RAW -> STAGE scheduled query previously supplied writes
-- to Stage_taxi_test, not Stage_taxi_trips. Reconcile this mismatch.
-- NOTE: Nonnegative trip duration and tip are the assumed validity
-- rules in this corrected query; confirm against business requirements.

MERGE `learning-bigquery-509717.sales.analytics_taxi_daily` AS target
USING (
  SELECT
    pickup_date,
    payment_type,
    COUNT(*) AS qtd_trips,
    SUM(CASE
      WHEN total_amount > 0 AND total_amount <= 10000
      THEN total_amount
    END) AS total_revenue,
    SUM(CASE WHEN fare_amount > 0 THEN fare_amount END) AS total_fare,
    COUNTIF(fare_amount > 0) AS qtd_valid_fares,
    SUM(CASE WHEN trip_distance >= 0 THEN trip_distance END) AS total_distance,
    COUNTIF(trip_distance >= 0) AS qtd_valid_distances,
    SUM(CASE
      WHEN trip_duration_minutes >= 0 THEN trip_duration_minutes
    END) AS total_trip_minutes,
    COUNTIF(trip_duration_minutes >= 0) AS qtd_valid_durations,
    SUM(CASE WHEN tip_amount >= 0 THEN tip_amount END) AS total_tip,
    COUNTIF(tip_amount >= 0) AS qtd_valid_tips
  FROM `learning-bigquery-509717.sales.Stage_taxi_trips`
  WHERE pickup_date = '2022-07-01'
  GROUP BY pickup_date, payment_type
) AS source
ON target.pickup_date = source.pickup_date
  AND target.payment_type IS NOT DISTINCT FROM source.payment_type
WHEN MATCHED THEN UPDATE SET
  qtd_trips = source.qtd_trips,
  total_revenue = source.total_revenue,
  total_fare = source.total_fare,
  qtd_valid_fares = source.qtd_valid_fares,
  total_distance = source.total_distance,
  qtd_valid_distances = source.qtd_valid_distances,
  total_trip_minutes = source.total_trip_minutes,
  qtd_valid_durations = source.qtd_valid_durations,
  total_tip = source.total_tip,
  qtd_valid_tips = source.qtd_valid_tips
WHEN NOT MATCHED THEN INSERT (
  pickup_date, payment_type, qtd_trips, total_revenue,
  total_fare, qtd_valid_fares,
  total_distance, qtd_valid_distances,
  total_trip_minutes, qtd_valid_durations,
  total_tip, qtd_valid_tips
)
VALUES (
  source.pickup_date, source.payment_type, source.qtd_trips,
  source.total_revenue, source.total_fare, source.qtd_valid_fares,
  source.total_distance, source.qtd_valid_distances,
  source.total_trip_minutes, source.qtd_valid_durations,
  source.total_tip, source.qtd_valid_tips
);
