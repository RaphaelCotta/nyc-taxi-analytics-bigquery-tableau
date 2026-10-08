-- NYC Taxi Analytics | 03 - STAGE to ANALYTICS incremental MERGE
-- Recovered from the scheduled query "Taxi - Staging to Analytics".
-- Source: learning-bigquery-509717.sales.Stage_taxi_trips
-- Target: learning-bigquery-509717.sales.analytics_taxi_daily
--
-- IMPORTANT:
-- 1. The scheduled RAW -> STAGE query previously supplied writes to
--    Stage_taxi_test, whereas this query reads Stage_taxi_trips.
--    Verify which staging table is populated in the active pipeline.
-- 2. The processing date is hard-coded to 2022-07-01.
-- 3. This MERGE expects the target to contain avg_fare, avg_distance,
--    avg_minutes_trip and avg_tip columns; verify its current schema.
-- 4. The average trip duration and tip calculations below do not
--    explicitly filter invalid values.

MERGE `learning-bigquery-509717.sales.analytics_taxi_daily` AS target
USING (
  SELECT
    pickup_date,
    payment_type,
    COUNT(*) AS qtd_trips,
    SUM(
      CASE
        WHEN total_amount > 0 AND total_amount <= 10000 THEN total_amount
        ELSE NULL
      END
    ) AS total_revenue,
    AVG(
      CASE
        WHEN fare_amount > 0 THEN fare_amount
        ELSE NULL
      END
    ) AS avg_fare,
    AVG(
      CASE
        WHEN trip_distance >= 0 THEN trip_distance
        ELSE NULL
      END
    ) AS avg_distance,
    AVG(trip_duration_minutes) AS avg_minutes_trip,
    AVG(tip_amount) AS avg_tip
  FROM `learning-bigquery-509717.sales.Stage_taxi_trips`
  WHERE pickup_date = '2022-07-01'
  GROUP BY pickup_date, payment_type
) AS source
ON target.pickup_date = source.pickup_date
  AND target.payment_type IS NOT DISTINCT FROM source.payment_type
WHEN MATCHED THEN
  UPDATE SET
    target.qtd_trips = source.qtd_trips,
    target.total_revenue = source.total_revenue,
    target.avg_fare = source.avg_fare,
    target.avg_distance = source.avg_distance,
    target.avg_minutes_trip = source.avg_minutes_trip,
    target.avg_tip = source.avg_tip
WHEN NOT MATCHED THEN
  INSERT (
    pickup_date,
    payment_type,
    qtd_trips,
    total_revenue,
    avg_fare,
    avg_distance,
    avg_minutes_trip,
    avg_tip
  )
  VALUES (
    source.pickup_date,
    source.payment_type,
    source.qtd_trips,
    source.total_revenue,
    source.avg_fare,
    source.avg_distance,
    source.avg_minutes_trip,
    source.avg_tip
  );
