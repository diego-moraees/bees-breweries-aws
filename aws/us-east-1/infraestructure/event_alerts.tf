data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ------------------------------------------
# IAM Role for EventBridge publish in SNS
# ------------------------------------------
resource "aws_iam_role" "events_to_sns_role" {
  name = "events-to-sns-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid      = "AllowEventBridgeAssume",
      Effect   = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "events_to_sns" {
  name = "events-to-sns-policy-${var.environment}"
  role = aws_iam_role.events_to_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid      = "PublishToAlertsTopic",
      Effect   = "Allow",
      Action   = ["sns:Publish"],
      Resource = module.alerts_sns.topic_arn
    }]
  })
}

# -------------------------------------------------------
# EventBridge Rule: Step Functions fail -> SNS (unique e-mail)
# -------------------------------------------------------
resource "aws_cloudwatch_event_rule" "sfn_failed" {
  name        = "sfn-failed-${var.environment}"
  description = "Alerta quando a State Machine falha/timed_out/aborted"

  event_pattern = jsonencode({
    "source":      ["aws.states"],
    "detail-type": ["Step Functions Execution Status Change"],
    "detail": {
      "stateMachineArn": [module.sfn_pipeline.state_machine_arn],
      "status": ["FAILED", "TIMED_OUT", "ABORTED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sfn_failed_to_sns" {
  rule     = aws_cloudwatch_event_rule.sfn_failed.name
  arn      = module.alerts_sns.topic_arn
  role_arn = aws_iam_role.events_to_sns_role.arn

  input_transformer {
    input_paths = {
      sm    = "$.detail.stateMachineArn"
      exec  = "$.detail.executionArn"
      name  = "$.detail.name"
      stat  = "$.detail.status"
      time  = "$.time"
      acct  = "$.account"
      regio = "$.region"
    }

    input_template = "\"[ALERT] Breweries pipeline <name> is <stat> at <time>.\\nStateMachine: <sm>\\nExecution: <exec>\\nAccount: <acct> | Region: <regio>\""
  }
}
