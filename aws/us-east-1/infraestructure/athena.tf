resource "aws_athena_workgroup" "this" {
  name  = "bees-wg-${var.environment}"
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.bees_s3_logs}-${var.environment}/athena/results/"
    }
  }
}