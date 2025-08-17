# -----------------------------
# Glue Databases
# -----------------------------
module "glue_db_silver" {
  source      = "../../modules/glue_catalog_database"
  name        = "db_silver"
  description = "Silver layer database for ${var.environment}"
}

module "glue_db_gold" {
  source      = "../../modules/glue_catalog_database"
  name        = "db_gold"
  description = "Gold layer database for ${var.environment}"
}

# --------------------------------------------
# Silver table (Parquet + Partition Projection)
# --------------------------------------------
module "glue_table_silver_openbrewerydb" {
  source             = "../../modules/glue_catalog_table"
  database_name      = module.glue_db_silver.name
  table_name         = "open_breweries"
  bucket_name_prefix = var.bees_s3_silver
  environment        = var.environment
  dataset_name       = "openbrewerydb"
  format            = "parquet"


  # Only NON-partition columns here
  columns = [
    { name = "id",           type = "string" },
    { name = "name",         type = "string" },
    { name = "brewery_type", type = "string" },
    { name = "street",       type = "string" },
    { name = "city",         type = "string" },
    { name = "postal_code",  type = "string" },
    { name = "longitude",    type = "double" },
    { name = "latitude",     type = "double" },
    { name = "phone",        type = "string" },
    { name = "website_url",  type = "string" },
  ]

  ingestion_date_min = "2024-01-01"

  description = "Cleaned Silver table (Parquet) with partition projection."

}

# --------------------------------------------
# Gold table (Parquet + Partition Projection)
# --------------------------------------------
module "glue_table_gold_openbrewerydb_agg" {
  source             = "../../modules/glue_catalog_table"
  database_name      = module.glue_db_gold.name
  table_name         = "open_breweries_agg"
  bucket_name_prefix = var.bees_s3_gold
  environment        = var.environment
  dataset_name       = "openbrewerydb_agg"
  format            = "delta"

  # Only NON-partition columns here
  columns = [
    { name = "brewery_type",    type = "string" },
    { name = "breweries_count", type = "bigint" },
  ]

  ingestion_date_min = "2024-01-01"

  description = "Aggregated Gold table (Delta Lake)."
}
