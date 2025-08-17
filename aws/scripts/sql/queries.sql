-- Scripts example to query data in Silver
-- Be aware to always set a date and/or country as partitions because the projection injected confs in Glue Catalog
SELECT *
FROM db_silver.open_breweries
WHERE ingestion_date = '2025-08-16'
  AND country = 'United States'
  AND state   = 'California'
LIMIT 10;


-- Scripts example to query data in Silver
-- Be aware to always set a date and/or country as partitions because the projection injected confs in Glue Catalog
SELECT country, state, brewery_type, breweries_count
FROM bees_gold_dev.openbrewerydb_agg
WHERE ingestion_date = date '2025-08-16'
ORDER BY breweries_count DESC
LIMIT 20;