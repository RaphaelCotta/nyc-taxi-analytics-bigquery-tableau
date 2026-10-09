-- Scheduled-query version configured October 2026.
-- @run_time maps the scheduled execution date to a historical date starting
-- at 2022-07-01 on 2026-10-09 (America/Sao_Paulo), capped at 2022-12-31.
-- Execute as a BigQuery Scheduled Query; manual runs require @run_time.
-- This calendar-based mapping does not automatically retry missed dates.
-- Ten-minute scheduling gaps do not guarantee upstream completion.
-- Tableau Public uses a static extract, not an automatically refreshed live view.

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
  WHERE pickup_date = DATE_ADD(
    DATE '2022-07-01',
    INTERVAL DATE_DIFF(
      DATE(@run_time, 'America/Sao_Paulo'),
      DATE '2026-10-09',
      DAY
    ) DAY
  )
    AND DATE_ADD(
    DATE '2022-07-01',
    INTERVAL DATE_DIFF(
      DATE(@run_time, 'America/Sao_Paulo'),
      DATE '2026-10-09',
      DAY
    ) DAY
  ) BETWEEN DATE '2022-07-01' AND DATE '2022-12-31'
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
