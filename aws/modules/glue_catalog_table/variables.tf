variable "database_name" {
  description = "Glue database name."
  type        = string
}

variable "table_name" {
  description = "Glue table name."
  type        = string
}

variable "format" {
  description = "Storage format: parquet (with partition projection) or delta."
  type        = string
  validation {
    condition     = contains(["parquet", "delta"], var.format)
    error_message = "format must be 'parquet' or 'delta'."
  }
}

variable "bucket_name_prefix" {
  description = "S3 bucket name prefix (without environment suffix). Ex: bees-lakehouse-silver"
  type        = string
}

variable "dataset_name" {
  description = "Dataset folder under the bucket. Ex: openbrewerydb or openbrewerydb_agg"
  type        = string
}

variable "environment" {
  description = "Environment suffix used in bucket name. Ex: dev"
  type        = string
}

variable "columns" {
  description = "List of data columns (exclude partition keys)."
  type = list(object({
    name    = string
    type    = string
    comment = optional(string)
  }))
  default = []
}

variable "serde_parameters" {
  description = "Optional SerDe parameters for Parquet."
  type        = map(string)
  default     = {}
}

# Parquet (projection) specific
variable "projection_enabled" {
  description = "Enable Athena partition projection (only for parquet)."
  type        = bool
  default     = true
}

variable "ingestion_date_min" {
  description = "Min date for ingestion_date projection range, format yyyy-MM-dd (only for parquet)."
  type        = string
  default     = "2024-01-01"
}

variable "projection_additional_params" {
  description = "Extra projection parameters to merge in (only for parquet)."
  type        = map(string)
  default     = {}
}

variable "description" {
  description = "Optional human-readable table description."
  type        = string
  default     = null
}
