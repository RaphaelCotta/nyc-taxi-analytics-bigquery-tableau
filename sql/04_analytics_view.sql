-- NYC Taxi Analytics | 04 - Analytics view for Tableau
-- Definition recovered from BigQuery: sales.vw_taxi_dashboard
-- This view exposes the analytics table without additional transformations.
-- Weighted averages are calculated in Tableau from sums and valid counts.

CREATE OR REPLACE VIEW `learning-bigquery-509717.sales.vw_taxi_dashboard` AS
SELECT
  *
FROM `learning-bigquery-509717.sales.analytics_taxi_daily`;
