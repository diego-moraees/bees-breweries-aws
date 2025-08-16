variable "name" {
  type = string
}

variable "environment" {
  type = string
}

# ARNs/Names
variable "lambda_function_arn" {
  type = string
}

variable "glue_job_bronze_name" {
  type = string
}

variable "glue_job_gold_name"   {
  type = string
}

# optional: start logs
variable "enable_logging" {
  type = bool
  default = true
}