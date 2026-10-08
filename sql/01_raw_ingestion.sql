-- NYC Taxi Analytics | 01 - RAW ingestion
-- Source: BigQuery public NYC Yellow Taxi Trips 2022 dataset
-- Target: learning-bigquery-509717.sales.raw_taxi_trips
--
-- This is the original lab query. The date is intentionally hard-coded
-- to 2022-07-01; change it or parameterize it for another processing date.
-- The MERGE inserts only unmatched rows. It does not update existing rows.
-- ROW_NUMBER removes duplicate rows within the selected source batch.
-- Note: only passenger_count uses null-safe matching in the ON clause;
-- other nullable key fields may require IS NOT DISTINCT FROM for robust
-- idempotency across all possible source values.

MERGE `learning-bigquery-509717.sales.raw_taxi_trips` AS target
USING (
  SELECT
    *,
    CURRENT_TIMESTAMP() AS loaded_at
  FROM
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
  WHERE
    DATE(pickup_datetime) = '2022-07-01'
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
    trip_distance,
    fare_amount,
    payment_type,
    passenger_count,
    tip_amount,
    total_amount,
    loaded_at
  )
  VALUES (
    source.pickup_datetime,
    source.dropoff_datetime,
    source.trip_distance,
    source.fare_amount,
    source.payment_type,
    source.passenger_count,
    source.tip_amount,
    source.total_amount,
    source.loaded_at
  );
