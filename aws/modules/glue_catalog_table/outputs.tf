output "name" {
  description = "Glue table name."
  value       = coalesce(
    try(aws_glue_catalog_table.parquet[0].name, null),
    try(aws_glue_catalog_table.delta[0].name, null)
  )
}

output "arn" {
  description = "Glue table ARN."
  value       = coalesce(
    try(aws_glue_catalog_table.parquet[0].arn, null),
    try(aws_glue_catalog_table.delta[0].arn, null)
  )
}
