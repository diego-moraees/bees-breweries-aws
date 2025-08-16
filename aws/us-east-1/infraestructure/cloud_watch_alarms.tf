# data "aws_region" "current" {}
# data "aws_caller_identity" "current" {}
#
# resource "aws_cloudwatch_metric_alarm" "sfn_failed_alarm" {
#   alarm_name        = "The breweries-pipeline failed! Please check it out"
#
#   alarm_description = "Step Functions execution FAILED for breweries pipeline"
#
#   namespace           = "AWS/States"
#   metric_name         = "FailedExecutions"
#   statistic           = "Sum"
#   period              = 60
#   evaluation_periods  = 1
#   threshold           = 0
#   comparison_operator = "GreaterThanThreshold"
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#   StateMachineArn = module.sfn_pipeline.state_machine_arn
#   }
#
#   alarm_actions = [aws_sns_topic.alerts.arn]
#
# }