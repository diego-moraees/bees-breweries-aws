#AWS Account info
variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "access_key" {
  description = "AWS Access Key"
  type        = string
  default     = null
}

variable "secret_key" {
  description = "AWS Secret Key"
  type        = string
  default     = null
}

variable "token" {
  description = "AWS Session Token"
  type        = string
  default     = null
}

variable "environment" {
  type        = string
  default     = "dev"
}

#Bucket S3
variable "bees_s3_bronze" {
  description = "S3 Lakehouse Bronze"
  type        = string
  default     = "bees-lakehouse-bronze"
}

variable "bees_s3_silver" {
  description = "S3 Lakehouse Silver"
  type        = string
  default     = "bees-lakehouse-silver"
}

variable "bees_s3_gold" {
  description = "S3 Lakehouse Gold"
  type        = string
  default     = "bees-lakehouse-gold"
}

variable "bees_s3_dags" {
  description = "S3 Lakehouse Dags"
  type        = string
  default     = "bees-lakehouse-dags"
}

variable "bees_s3_scripts" {
  description = "S3 Lakehouse Scripts"
  type        = string
  default     = "bees-lakehouse-scripts"
}

variable "bees_s3_logs" {
  description = "S3 Lakehouse Logs"
  type        = string
  default     = "bees-lakehouse-logs"
}


#Network
variable "subnet_ids" {
  description = "List of subnet IDs for MWAA"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for MWAA"
  type        = list(string)
  default     = []
}


variable "pipeline_schedule_cron" {
  type        = string
  description = "Cron do EventBridge para rodar a pipeline"
  default     = "cron(0 3 * * ? *)" # 03:00 UTC diário
}

variable "alert_email"     {
  type = string
  description = "E-mail to send alerts when pipeline fails"
  default     = "diego.moraees@outlook.com"

}

variable "enable_glue_alerts" {
  description = "If true, send failure alerts of Glue Job via EventBridge -> SNS"
  type        = bool
  default     = false
}