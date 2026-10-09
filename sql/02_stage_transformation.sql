-- Scheduled-query version configured October 2026.
-- @run_time maps the scheduled execution date to a historical date starting
-- at 2022-07-01 on 2026-10-09 (America/Sao_Paulo), capped at 2022-12-31.
-- Execute as a BigQuery Scheduled Query; manual runs require @run_time.
-- This calendar-based mapping does not automatically retry missed dates.
-- Ten-minute scheduling gaps do not guarantee upstream completion.
-- Tableau Public uses a static extract, not an automatically refreshed live view.

MERGE `learning-bigquery-509717.sales.Stage_taxi_trips` AS target
USING (
  SELECT
    *,
    DATE(pickup_datetime) AS pickup_date,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS trip_duration_minutes,
    CASE
      WHEN trip_distance < 0 THEN 'INVALID_DISTANCE'
      WHEN fare_amount <= 0 THEN 'INVALID_FARE'
      ELSE 'VALID'
    END AS data_quality_status
  FROM `learning-bigquery-509717.sales.raw_taxi_trips`
  WHERE DATE(pickup_datetime) = DATE_ADD(
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
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY
      pickup_datetime,
      dropoff_datetime,
      trip_distance,
      fare_amount,
      payment_type,
      passenger_count,
      tip_amount,
      total_amount
  ) = 1
) AS source
ON target.pickup_datetime = source.pickup_datetime
  AND target.dropoff_datetime = source.dropoff_datetime
  AND target.trip_distance = source.trip_distance
  AND target.fare_amount = source.fare_amount
  AND target.payment_type = source.payment_type
  AND target.passenger_count IS NOT DISTINCT FROM source.passenger_count
  AND target.tip_amount = source.tip_amount
  AND target.total_amount = source.total_amount
WHEN NOT MATCHED THEN
  INSERT (
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    payment_type,
    fare_amount,
    tip_amount,
    tolls_amount,
    total_amount,
    loaded_at,
    pickup_date,
    trip_duration_minutes,
    data_quality_status
  )
  VALUES (
    source.pickup_datetime,
    source.dropoff_datetime,
    source.passenger_count,
    source.trip_distance,
    source.payment_type,
    source.fare_amount,
    source.tip_amount,
    source.tolls_amount,
    source.total_amount,
    source.loaded_at,
    source.pickup_date,
    source.trip_duration_minutes,
    source.data_quality_status
  );
