data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["airflow.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = {
    Environment = var.environment
    Project     = "bees-breweries"
  }
}

# Policy mínima para MWAA acessar S3 (dags/scripts/logs/lakehouse), Glue, Lambda, CloudWatch Logs
data "aws_iam_policy_document" "inline" {
  statement {
    sid     = "S3Access"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = var.s3_bucket_arns
  }

  statement {
    sid     = "S3ObjectsAccess"
    effect  = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload"
    ]
    resources = [for arn in var.s3_bucket_arns : "${arn}/*"]
  }

  statement {
    sid     = "GlueAccess"
    effect  = "Allow"
    actions = [
      "glue:StartJobRun", "glue:GetJobRun", "glue:GetJob", "glue:GetJobs",
      "glue:GetTables", "glue:GetDatabase", "glue:GetDatabases"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "LambdaInvoke"
    effect  = "Allow"
    actions = ["lambda:InvokeFunction", "lambda:GetFunction", "lambda:ListFunctions"]
    resources = ["*"]
  }

  statement {
    sid     = "LogsAccess"
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents",
      "logs:DescribeLogGroups", "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.name}-policy"
  description = "MWAA execution inline policy"
  policy      = data.aws_iam_policy_document.inline.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
