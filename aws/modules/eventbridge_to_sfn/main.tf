terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# Cron rule
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.name}-schedule-${var.environment}"
  schedule_expression = var.schedule_expression
}

# Role used by EventBridge to start SFN StartExecution
resource "aws_iam_role" "events_to_sfn" {
  name = "events_to_sfn-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "events_to_sfn" {
  name = "events-to-sfn-policy-${var.environment}"
  role = aws_iam_role.events_to_sfn.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid:    "StartSfn",
      Effect: "Allow",
      Action: ["states:StartExecution"],
      Resource: var.state_machine_arn
    }]
  })
}

# Target = State Machine
resource "aws_cloudwatch_event_target" "to_sfn" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  arn       = var.state_machine_arn
  role_arn  = aws_iam_role.events_to_sfn.arn
}
