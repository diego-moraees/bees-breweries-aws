module "bronze_bucket" {
  source      = "../../modules/s3"
  bucket_name = "${var.bees_s3_bronze}-${var.environment}"
  environment = var.environment
}

module "silver_bucket" {
  source      = "../../modules/s3"
  bucket_name = "${var.bees_s3_silver}-${var.environment}"
  environment = var.environment
}

module "gold_bucket" {
  source      = "../../modules/s3"
  bucket_name = "${var.bees_s3_gold}-${var.environment}"
  environment = var.environment
}

module "logs_bucket" {
  source      = "../../modules/s3"
  bucket_name = "${var.bees_s3_logs}-${var.environment}"
  environment = var.environment
}

module "scripts_bucket" {
  source      = "../../modules/s3"
  bucket_name = "${var.bees_s3_scripts}-${var.environment}"
  environment = var.environment
}

module "upload_bronze_to_silver" {
  source      = "../../modules/s3_Object"
  bucket_id   = "${var.bees_s3_scripts}-${var.environment}"
  local_path  = "../../scripts/glue/bronze_to_silver.py"
  remote_path = "glue"
}

module "upload_silver_to_gold" {
  source      = "../../modules/s3_Object"
  bucket_id   = "${var.bees_s3_scripts}-${var.environment}"
  local_path  = "../../scripts/glue/silver_to_gold.py"
  remote_path = "glue"
}

module "lambda_zip" {
  source      = "../../modules/s3_Object"
  bucket_id   = "${var.bees_s3_scripts}-${var.environment}"
  local_path  = "../../scripts/lambda/brewery_ingest.zip"
  remote_path = "lambda"
}