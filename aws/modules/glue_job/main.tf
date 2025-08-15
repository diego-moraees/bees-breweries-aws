resource "aws_glue_job" "this" {
  name     = var.job_name
  role_arn = var.role_arn

  command {
    name            = "glueetl"
    script_location = var.script_location
    python_version  = "3"
  }

  glue_version      = var.glue_version
  number_of_workers = var.number_of_workers
  worker_type       = var.worker_type

  default_arguments = merge(
    {
      "--job-language"                   = "python"
      "--enable-continuous-cloudwatch-log" = "true"
      "--enable-metrics"                = ""
      "--enable-glue-datacatalog"      = ""
      "--enable-spark-ui"               = "true"
      "--enable-auto-scaling"           = "true"
    },
    var.additional_arguments
  )

  tags = {
    Environment = var.environment
    Project     = "bees-breweries"
  }
}
