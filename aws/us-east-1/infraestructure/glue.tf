module "glue_role" {
  source      = "../../modules/iam_role_glue"
  role_name   = "glue_role_${var.environment}"
  buckets     = join(",", [
    "${var.bees_s3_bronze}-${var.environment}",
    "${var.bees_s3_silver}-${var.environment}",
    "${var.bees_s3_gold}-${var.environment}",
    "${var.bees_s3_scripts}-${var.environment}"
  ])
  environment = var.environment
}

module "glue_bronze_to_silver" {
  source        = "../../modules/glue_job"

  job_name      = "bronze_to_silver_${var.environment}"
  role_arn      = module.glue_role.role_arn  # você precisará criar esse módulo para a role
  script_location = "s3://${var.bees_s3_scripts}-${var.environment}/bronze_to_silver.py"
  glue_version  = "3.0"
  number_of_workers = 2
  worker_type   = "G.1X"
  environment   = var.environment

  additional_arguments = {
    "--extra-py-files" = "s3://${var.bees_s3_scripts}-${var.environment}/dependencies.zip"  # se houver libs extras
  }
}

module "glue_silver_to_gold" {
  source        = "../../modules/glue_job"
  job_name      = "silver_to_gold_${var.environment}"
  role_arn      = module.glue_role.role_arn
  script_location = "s3://${var.bees_s3_scripts}-${var.environment}/silver_to_gold.py"
  number_of_workers = 5
  worker_type       = "G.1X"
  glue_version  = "3.0"
  environment   = var.environment
}
