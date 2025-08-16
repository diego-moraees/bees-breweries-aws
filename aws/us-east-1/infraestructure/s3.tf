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


# Upload dos scripts de Glue
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

# Upload do zip da Lambda (vamos gerar manualmente no passo 5)
module "lambda_zip" {
  source      = "../../modules/s3_Object"
  bucket_id   = "${var.bees_s3_scripts}-${var.environment}"
  local_path  = "../../scripts/lambda/brewery_ingest.zip"
  remote_path = "lambda"
}