terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Log group to execute State Machine
resource "aws_cloudwatch_log_group" "sfn" {
  count             = var.enable_logging ? 1 : 0
  name              = "/aws/states/${var.name}-${var.environment}"
  retention_in_days = 7
}

# Step Functions Role
resource "aws_iam_role" "sfn_role" {
  name = "sfn_role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Policies: invoke Lambda and start/observe Glue Jobs + logs do SFN
resource "aws_iam_role_policy" "sfn_policy" {
  name = "sfn-exec-policy-${var.environment}"
  role = aws_iam_role.sfn_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Invoke lambda to ingestion in Bronze
      {
        Sid:    "InvokeLambda",
        Effect: "Allow",
        Action: ["lambda:InvokeFunction"],
        Resource: var.lambda_function_arn
      },
      # Glue: start and observe Jobs
      {
        Sid:    "StartGlueJobs",
        Effect: "Allow",
        Action: [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ],
        Resource: [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/${var.glue_job_bronze_name}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/${var.glue_job_gold_name}"
        ]
      },
      # Step Functions Logs (when logging enabled)
      {
        Sid:    "SfnLogs",
        Effect: "Allow",
        Action: [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ],
        Resource: "*"
      }
    ]
  })
}

# State Machine Defnition (ASL)
locals {
  sfn_definition = {
    Comment = "Breweries daily pipeline"
    StartAt = "Ingest"
    States = {
      Ingest = {
        Type       = "Task"
        Resource   = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.lambda_function_arn
          Payload      = {}
        }
        ResultPath = "$.ingest"
        Next       = "BronzeToSilver"
      }

      BronzeToSilver = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.glue_job_bronze_name
        }
        Next = "SilverToGold"
      }

      SilverToGold = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.glue_job_gold_name
        }
        End = true
      }
    }
  }
}

resource "aws_sfn_state_machine" "this" {
  name     = "${var.name}-${var.environment}"
  role_arn = aws_iam_role.sfn_role.arn
  definition = jsonencode(local.sfn_definition)

  dynamic "logging_configuration" {
    for_each = var.enable_logging ? [1] : []
    content {
      include_execution_data = true
      level                  = "ALL"
      log_destination        = "${aws_cloudwatch_log_group.sfn[0].arn}:*"
    }
  }

  tags = {
    Project     = "bees-breweries"
    Environment = var.environment
  }
}
