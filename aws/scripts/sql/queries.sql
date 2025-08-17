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


-- Top states with more breweries in USA - Example
WITH states AS (
  SELECT * FROM (VALUES 'California', 'Texas', 'New York', 'Florida', 'Colorado') AS t(state)
)
SELECT
  g.state,
  SUM(g.breweries_count) AS total_breweries
FROM db_gold.open_breweries_agg g
JOIN states s ON s.state = g.state
WHERE g.ingestion_date = '2025-08-16'
  AND g.country = 'United States'
GROUP BY g.state
ORDER BY total_breweries DESC
LIMIT 10;

-- Top cities by breweries in a state
SELECT
  city,
  COUNT(*) AS breweries
FROM db_silver.open_breweries
WHERE ingestion_date = '2025-08-16'
  AND country = 'United States'
  AND state   = 'California'
GROUP BY city
HAVING COUNT(*) >= 3
ORDER BY breweries DESC, city
LIMIT 20;