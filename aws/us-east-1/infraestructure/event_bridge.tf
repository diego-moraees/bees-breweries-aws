# resource "aws_cloudwatch_event_rule" "daily" {
#   name                = "brewery-daily-${var.environment}"
#   schedule_expression = "rate(1 day)"
# }
#
# resource "aws_cloudwatch_event_target" "lambda" {
#   rule      = aws_cloudwatch_event_rule.daily.name
#   target_id = "brewery-lambda"
#   arn       = module.lambda_brewery.function_arn
# }
#
# resource "aws_lambda_permission" "allow_eventbridge" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = module.lambda_brewery.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.daily.arn
# }
