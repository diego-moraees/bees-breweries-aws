# # SNS para alertas
# resource "aws_sns_topic" "alerts" {
#   name = "bees-alerts-${var.environment}"
# }
# # (adicione subscription por email se quiser)
#
# # Regra p/ falhas de Glue
# resource "aws_cloudwatch_event_rule" "glue_failed" {
#   name        = "glue-failed-${var.environment}"
#   description = "Notifica falhas de Glue"
#   event_pattern = jsonencode({
#     "source": ["aws.glue"],
#     "detail-type": ["Glue Job State Change"],
#     "detail": {"state": ["FAILED"]}
#   })
# }
# resource "aws_cloudwatch_event_target" "glue_failed_to_sns" {
#   rule      = aws_cloudwatch_event_rule.glue_failed.name
#   target_id = "sns"
#   arn       = aws_sns_topic.alerts.arn
# }
#
# # Alarme simples para erros da Lambda
# resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
#   alarm_name          = "lambda-errors-${var.environment}"
#   namespace           = "AWS/Lambda"
#   metric_name         = "Errors"
#   statistic           = "Sum"
#   period              = 300
#   evaluation_periods  = 1
#   threshold           = 0
#   comparison_operator = "GreaterThanThreshold"
#   dimensions = { FunctionName = module.lambda_brewery.function_name }
#   alarm_actions = [aws_sns_topic.alerts.arn]
# }
