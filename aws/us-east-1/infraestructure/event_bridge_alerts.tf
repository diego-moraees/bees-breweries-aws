# # ---------- Glue Job Silver FAILED ----------
# resource "aws_cloudwatch_event_rule" "glue_bronze_failed" {
#   name        = "glue-${module.glue_bronze_to_silver.job_name}-failed-${var.environment}"
#   description = "Alerta quando o Glue Bronze->Silver falhar"
#   event_pattern = jsonencode({
#     "source":      ["aws.glue"],
#     "detail-type": ["Glue Job State Change"],
#     "detail": {
#       "jobName": [ module.glue_bronze_to_silver.job_name ],
#       "state":   ["FAILED"]
#     }
#   })
# }
#
# resource "aws_cloudwatch_event_target" "glue_bronze_failed_to_sns" {
#   rule      = aws_cloudwatch_event_rule.glue_bronze_failed.name
#   target_id = "sns"
#   arn       = module.alerts_sns.topic_arn
# }
#
# # ---------- Glue Job Gold FAILED ----------
# resource "aws_cloudwatch_event_rule" "glue_gold_failed" {
#   name        = "glue-${module.glue_silver_to_gold.job_name}-failed-${var.environment}"
#   description = "Alerta quando o Glue Silver->Gold falhar"
#   event_pattern = jsonencode({
#     "source":      ["aws.glue"],
#     "detail-type": ["Glue Job State Change"],
#     "detail": {
#       "jobName": [ module.glue_silver_to_gold.job_name ],
#       "state":   ["FAILED"]
#     }
#   })
# }
#
# resource "aws_cloudwatch_event_target" "glue_gold_failed_to_sns" {
#   rule      = aws_cloudwatch_event_rule.glue_gold_failed.name
#   target_id = "sns"
#   arn       = module.alerts_sns.topic_arn
# }
#
# # Permissão para o EventBridge publicar no SNS (ambas as regras)
# resource "aws_sns_topic_policy" "sns_events_policy" {
#   arn    = module.alerts_sns.topic_arn
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid:    "AllowEventBridgeToPublish",
#         Effect: "Allow",
#         Principal: { Service: "events.amazonaws.com" },
#         Action: "sns:Publish",
#         Resource: module.alerts_sns.topic_arn,
#         Condition: {
#           ArnEquals: {
#             "aws:SourceArn": [
#               aws_cloudwatch_event_rule.glue_bronze_failed.arn,
#               aws_cloudwatch_event_rule.glue_gold_failed.arn,
#               aws_cloudwatch_event_rule.sfn_failed.arn
#             ]
#           }
#         }
#       }
#     ]
#   })
# }
#
# # ---------- Step Functions Execution FAILED/ABORTED/TIMED_OUT ----------
# resource "aws_cloudwatch_event_rule" "sfn_failed" {
#   name        = "sfn-failed-${var.environment}"
#   description = "Alerta de falha/abort/timeout da State Machine"
#   event_pattern = jsonencode({
#     "source":      ["aws.states"],
#     "detail-type": ["Step Functions Execution Status Change"],
#     "detail": {
#       "stateMachineArn": [ module.sfn_pipeline.state_machine_arn ],
#       "status": ["FAILED", "ABORTED", "TIMED_OUT"]
#     }
#   })
# }
#
# resource "aws_cloudwatch_event_target" "sfn_failed_to_sns" {
#   rule      = aws_cloudwatch_event_rule.sfn_failed.name
#   target_id = "sns"
#   arn       = module.alerts_sns.topic_arn
#
#   input_transformer {
#     input_paths = {
#       when  = "$.time"
#       ex    = "$.detail.executionArn"
#       sm    = "$.detail.stateMachineArn"
#       error = "$.detail.error"
#       cause = "$.detail.cause"
#       name  = "$.detail.name"
#     }
#     # corpo do e-mail (mensagem do SNS)
#     input_template = "\"The breweries-pipeline failed! Please check it out.\\n\\nWhen: <when>\\nExecution: <ex>\\nStateMachine: <sm>\\nName: <name>\\nError: <error>\\nCause: <cause>\""
#   }
# }
