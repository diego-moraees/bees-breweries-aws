module "iam_mwaa" {
  source      = "../../modules/iam_mwaa"
  name        = "bees-mwaa-${var.environment}"
  environment = var.environment
  s3_bucket_arns = [
    module.dags_bucket.bucket_arn,
    "arn:aws:s3:::${var.bees_s3_logs}-${var.environment}",
    "arn:aws:s3:::${var.bees_s3_bronze}-${var.environment}",
    "arn:aws:s3:::${var.bees_s3_silver}-${var.environment}",
    "arn:aws:s3:::${var.bees_s3_gold}-${var.environment}",
    "arn:aws:s3:::${var.bees_s3_scripts}-${var.environment}",
  ]
}
