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

module "dags_bucket" {
  source      = "../../modules/s3"
  bucket_name = "${var.bees_s3_dags}-${var.environment}"
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

module "lambda_scripts" {
  source      = "../../modules/s3_object"
  bucket_id   = "${var.bees_s3_scripts}-${var.environment}"
  local_path  = "../../scripts/brewery_ingest.zip"
  remote_path = "teste"
}

# Upload dos DAGs (tudo que estiver na pasta local aws/dags)
module "upload_dags" {
  source      = "../../modules/s3_object"
  bucket_id   = "${var.bees_s3_dags}-${var.environment}"
  local_path  = "../../dags/brewery_ingest_dag.py"
  remote_path = ""
}

# Upload de requirements.txt (se houver) da pasta aws/airflow
module "upload_requirements" {
  source      = "../../modules/s3_object"
  bucket_id   = "${var.bees_s3_dags}-${var.environment}"
  local_path  = "../../airflow/requirements.txt"
  remote_path = ""
}


# Upload de plugins.zip (opcional) da pasta aws/airflow
# module "upload_plugins" {
#   source      = "../../modules/s3_object"
#   bucket_id   = module.dags_bucket.bucket_name
#   local_path  = "${path.module}/../airflow"
#   remote_path = ""  # envia na raiz do bucket
# }
