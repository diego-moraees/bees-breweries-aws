# Policy for Glue role read scripts, read Bronze, write Silver and Gold
resource "aws_iam_role_policy" "glue_s3_access" {
  name = "glue-s3-access-${var.environment}"

  # Get role name using module ARN
  role = element(split("/", module.glue_role.role_arn), 1)

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ---------------- Scripts ----------------
      {
        Sid      = "ListScriptsBucket",
        Effect   = "Allow",
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"],
        Resource = "arn:aws:s3:::${var.bees_s3_scripts}-${var.environment}"
      },
      {
        Sid      = "GetScriptsObjects",
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "arn:aws:s3:::${var.bees_s3_scripts}-${var.environment}/glue/*"
      },

      # ---------------- Bronze (read) ----------------
      {
        Sid      = "ListBronzeBucket",
        Effect   = "Allow",
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"],
        Resource = "arn:aws:s3:::${var.bees_s3_bronze}-${var.environment}"
      },
      {
        Sid      = "ReadBronzeObjects",
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "arn:aws:s3:::${var.bees_s3_bronze}-${var.environment}/*"
      },

      # ---------------- Silver (read/write) ----------------
      {
        Sid      = "ListSilverBucket",
        Effect   = "Allow",
        Action   = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads"
        ],
        Resource = "arn:aws:s3:::${var.bees_s3_silver}-${var.environment}"
      },
      {
        Sid      = "RWSilverObjects",
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ],
        Resource = "arn:aws:s3:::${var.bees_s3_silver}-${var.environment}/*"
      },

      # ---------------- Gold (read/write) ----------------
      {
        Sid      = "ListGoldBucket",
        Effect   = "Allow",
        Action   = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads"
        ],
        Resource = "arn:aws:s3:::${var.bees_s3_gold}-${var.environment}"
      },
      {
        Sid      = "RWGoldObjects",
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ],
        Resource = "arn:aws:s3:::${var.bees_s3_gold}-${var.environment}/*"
      },

      # ---------------- CloudWatch (métricas do Glue) ----------------
      {
        Sid    = "PutMetrics",
        Effect = "Allow",
        Action = ["cloudwatch:PutMetricData"],
        Resource = "*"
      }
    ]
  })
}


module "glue_role" {
  source      = "../../modules/iam_role_glue"
  role_name   = "glue_role_${var.environment}"
  buckets     = join(",", [
    "${var.bees_s3_bronze}-${var.environment}",
    "${var.bees_s3_silver}-${var.environment}",
    "${var.bees_s3_gold}-${var.environment}",
    "${var.bees_s3_scripts}-${var.environment}"
  ])
  environment = var.environment
}

module "glue_bronze_to_silver" {

  source            = "../../modules/glue_job"
  job_name          = "bronze_to_silver_${var.environment}"
  role_arn          = module.glue_role.role_arn
  script_location   = "s3://${var.bees_s3_scripts}-${var.environment}/glue/bronze_to_silver.py"
  glue_version      = "5.0"
  number_of_workers = 3
  worker_type       = "G.1X"
  environment       = var.environment
  additional_arguments = {
    "--dataset_name"   = "openbrewerydb"
    "--bronze_bucket"  = "${var.bees_s3_bronze}-${var.environment}"
    "--silver_bucket"  = "${var.bees_s3_silver}-${var.environment}"
  }
  depends_on = [ module.upload_bronze_to_silver ]
}

module "glue_silver_to_gold" {
  source        = "../../modules/glue_job"
  job_name      = "silver_to_gold_${var.environment}"
  role_arn      = module.glue_role.role_arn
  script_location   = "s3://${var.bees_s3_scripts}-${var.environment}/glue/silver_to_gold.py"

  glue_version      = "5.0"
  number_of_workers = 3
  worker_type       = "G.1X"
  environment   = var.environment

  additional_arguments = {
    "--ingestion_date" = ""  # passamos na execução
    "--dataset_name"   = "openbrewerydb"
    "--gold_dataset_name"  = "openbrewerydb_agg"
    "--silver_bucket"  = "${var.bees_s3_silver}-${var.environment}"
    "--gold_bucket"    = "${var.bees_s3_gold}-${var.environment}"

  }
  depends_on = [ module.upload_bronze_to_silver ]
}