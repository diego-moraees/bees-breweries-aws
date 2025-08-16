data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ------------------------------------------
# IAM Role para EventBridge publicar no SNS
# ------------------------------------------
resource "aws_iam_role" "events_to_sns_role" {
  name = "events-to-sns-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "AllowEventBridgeAssume",
      Effect = "Allow",
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
# Regra EventBridge: falha do Step Functions -> SNS
# -------------------------------------------------------
resource "aws_cloudwatch_event_rule" "sfn_failed" {
  name        = "sfn-failed-${var.environment}"
  description = "Alerta quando a State Machine falha/timed_out/aborted"

  event_pattern = jsonencode({
    "source": ["aws.states"],
    "detail-type": ["Step Functions Execution Status Change"],
    "detail": {
      "stateMachineArn": [module.sfn_pipeline.state_machine_arn],
      "status": ["FAILED", "TIMED_OUT", "ABORTED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sfn_failed_to_sns" {
  rule      = aws_cloudwatch_event_rule.sfn_failed.name
  arn       = module.alerts_sns.topic_arn
  role_arn  = aws_iam_role.events_to_sns_role.arn

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

    # precisa ser um JSON string (aspas e \n escapados)
    input_template = "\"[ALERT] Step Functions execution <name> is <stat> at <time>.\\nStateMachine: <sm>\\nExecution: <exec>\\nAccount: <acct> | Region: <regio>\""
  }
}

# -------------------------------------------------------
# Regra EventBridge: falha dos Glue Jobs -> SNS
# (cobre bronze->silver e silver->gold)
# -------------------------------------------------------
resource "aws_cloudwatch_event_rule" "glue_failed" {
  name        = "glue-failed-${var.environment}"
  description = "Alerta quando Glue Job falhar ou expirar"

  event_pattern = jsonencode({
    "source": ["aws.glue"],
    "detail-type": ["Glue Job State Change"],
    "detail": {
      "jobName": [module.glue_bronze_to_silver.job_name , module.glue_silver_to_gold.job_name ],
      "state":   ["FAILED", "TIMEOUT"]
    }
  })
}

resource "aws_cloudwatch_event_target" "glue_failed_to_sns" {
  rule      = aws_cloudwatch_event_rule.glue_failed.name
  arn       = module.alerts_sns.topic_arn
  role_arn  = aws_iam_role.events_to_sns_role.arn

  input_transformer {
    input_paths = {
      job   = "$.detail.jobName"
      state = "$.detail.state"
      run   = "$.detail.jobRunId"
      time  = "$.time"
      acct  = "$.account"
      regio = "$.region"
    }

    # idem: JSON string com \n escapado
    input_template = "\"[ALERT] Glue job <job> is <state> at <time>.\\nJobRunId: <run>\\nAccount: <acct> | Region: <regio>\""
  }
}
