resource "aws_iam_role_policy" "lambda_glue_access" {
  name = "lambda-glue-access-${var.environment}"
  role = module.lambda_brewery_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["glue:StartJobRun", "glue:GetJobRun", "glue:GetJobRuns"],
      Resource = "*"
    }]
  })
}

# IAM Role for Lambda Brewery Ingestion
module "lambda_brewery_role" {
  source              = "../../modules/iam_role"
  role_name           = "brewery_lambda_role-${var.environment}"
  environment         = var.environment
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

# Lambda Function
module "lambda_brewery_ingest" {
  source                = "../../modules/lambda"
  function_name         = "brewery_ingest-${var.environment}"
  role_arn              = module.lambda_brewery_role.role_arn
  handler               = "brewery_ingest.lambda_handler"
  runtime               = "python3.11"
  s3_bucket             = "${var.bees_s3_scripts}-${var.environment}"
  s3_key                = "teste/brewery_ingest.zip"
  environment_variables = {
    BUCKET_NAME = "${var.bees_s3_bronze}-${var.environment}"
  }
  environment           = var.environment

  depends_on = [
    module.lambda_scripts
  ]
}
