resource "aws_mwaa_environment" "this" {
  name               = var.environment_name
  airflow_version    = var.airflow_version
  environment_class  = var.environment_class

  source_bucket_arn  = var.dag_s3_bucket_arn
  dag_s3_path        = var.dag_s3_path

  execution_role_arn = var.execution_role_arn

  network_configuration {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  logging_configuration {
    dag_processing_logs {
      enabled = true
      log_level = "INFO"
    }
    scheduler_logs      {
      enabled = true
      log_level = "INFO"
    }
    task_logs           {
      enabled = true
      log_level = "INFO"
    }
    webserver_logs      {
      enabled = true
      log_level = "INFO"
    }
    worker_logs         {
      enabled = true
      log_level = "INFO"
    }
  }

  webserver_access_mode = var.webserver_access_mode

  requirements_s3_path = var.requirements_s3_path
  plugins_s3_path      = ""
  # plugins_s3_path      = var.plugins_s3_path

  airflow_configuration_options = var.airflow_configuration_options

  tags = var.tags
}
