module "sfn_pipeline" {
  source           = "../../modules/sfn_state_machine"
  name             = "breweries-pipeline"
  environment      = var.environment

  lambda_function_arn = module.lambda_brewery.lambda_arn

  glue_job_bronze_name = module.glue_bronze_to_silver.job_name
  glue_job_gold_name   = module.glue_silver_to_gold.job_name

  enable_logging = true
}

module "daily_trigger" {
  source              = "../../modules/eventbridge_to_sfn"
  name                = "breweries-pipeline"
  environment         = var.environment
  schedule_expression = var.pipeline_schedule_cron
  state_machine_arn   = module.sfn_pipeline.state_machine_arn
}
