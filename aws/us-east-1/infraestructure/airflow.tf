module "mwaa" {
  source                = "../../modules/mwaa"
  environment_name      = "bees-mwaa-${var.environment}"
  airflow_version       = "2.5.1"
  environment_class     = "mw1.small"
  dag_s3_bucket_arn     = module.dags_bucket.bucket_arn
  dag_s3_path           = "dags"
  execution_role_arn    = module.iam_mwaa.role_arn
  subnet_ids            = module.vpc_mwaa.private_subnet_ids
  security_group_ids    = [module.vpc_mwaa.security_group_id]
  webserver_access_mode = "PUBLIC_ONLY"

  # Se você enviar requirements.txt e plugins.zip para a RAIZ do bucket, aponte aqui
  requirements_s3_path = "requirements.txt"
  plugins_s3_path      = "plugins.zip"

  airflow_configuration_options = {
    "webserver.dag_default_view"         = "graph"
    "core.parallelism"                   = "8"
    "core.load_examples"                 = "False"
    "logging.logging_level"              = "INFO"
  }

  tags = {
    Environment = var.environment
    Project     = "bees-breweries"
  }

  depends_on = [module.dags_bucket, module.upload_dags, module.upload_requirements]
}
