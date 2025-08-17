locals {
  table_location   = "s3://${var.bucket_name_prefix}-${var.environment}/${var.dataset_name}"

  # For Athena projection templates we need literal ${var} placeholders.
  # In Terraform, escape with $$ to emit a literal ${...}
  storage_template = "s3://${var.bucket_name_prefix}-${var.environment}/${var.dataset_name}/ingestion_date=$${ingestion_date}/country=$${country}/state=$${state}"

  parquet_parameters_base = {
    classification                     = "parquet"
    EXTERNAL                           = "TRUE"

    # Turn projection on/off
    "projection.enabled"               = tostring(var.projection_enabled)

    # ingestion_date as DATE
    "projection.ingestion_date.type"   = "date"
    "projection.ingestion_date.range"  = "${var.ingestion_date_min},NOW"
    "projection.ingestion_date.format" = "yyyy-MM-dd"

    # country/state as injected (no need to maintain enums)
    "projection.country.type"          = "injected"
    "projection.state.type"            = "injected"

    # Template must match your partition folder layout
    "storage.location.template"        = local.storage_template
  }

  parquet_parameters = merge(local.parquet_parameters_base, var.projection_additional_params)

  delta_parameters = {
    classification     = "delta"
    EXTERNAL           = "TRUE"
    "delta.table.path" = local.table_location
  }
}

# -------------------------------
# Parquet + Partition Projection
# -------------------------------
resource "aws_glue_catalog_table" "parquet" {
  count        = var.format == "parquet" ? 1 : 0
  database_name= var.database_name
  name         = var.table_name
  table_type   = "EXTERNAL_TABLE"
  description  = var.description

  parameters = local.parquet_parameters

  storage_descriptor {
    location      = local.table_location
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters            = var.serde_parameters
    }

    # Data columns (do not include partition keys here)
    dynamic "columns" {
      for_each = var.columns
      content {
        name    = columns.value.name
        type    = columns.value.type
        comment = try(columns.value.comment, null)
      }
    }
  }

  # Partitions (derived from the S3 path)
  partition_keys {
    name = "ingestion_date"
    type = "string"
  }

  partition_keys {
    name = "country"
    type = "string"
  }

  partition_keys {
    name = "state"
    type = "string"
  }
}

# -------------
# Delta Lake
# -------------
resource "aws_glue_catalog_table" "delta" {
  count        = var.format == "delta" ? 1 : 0
  database_name= var.database_name
  name         = var.table_name
  table_type   = "EXTERNAL_TABLE"
  description  = var.description

  parameters = local.delta_parameters

  storage_descriptor {
    location      = local.table_location
    # Glue uses Parquet I/O classes; the engine (Spark/connector) reads Delta using _delta_log
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    # Columns are optional for Delta (schema comes from _delta_log); keep empty or pass in if desired
    dynamic "columns" {
      for_each = var.columns
      content {
        name    = columns.value.name
        type    = columns.value.type
        comment = try(columns.value.comment, null)
      }
    }
  }

  # Partitions help catalog navigation; engine still honors _delta_log.
  partition_keys {
    name = "ingestion_date"
    type = "string"
  }

  partition_keys {
    name = "country"
    type = "string"
  }

  partition_keys {
    name = "state"
    type = "string"
  }
}
