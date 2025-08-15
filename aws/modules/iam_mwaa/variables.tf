variable "name" {
  description = "Base name for MWAA role/policy"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs MWAA must access (dags, logs, lakehouse...)"
  type        = list(string)
}
