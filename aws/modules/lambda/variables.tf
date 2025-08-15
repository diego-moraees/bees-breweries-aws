variable "function_name" {
  type        = string
  description = "Lambda function name"
}

variable "role_arn" {
  type        = string
  description = "IAM Role ARN for Lambda"
}

variable "handler" {
  type        = string
  description = "Lambda handler (file.function)"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "python3.11"
}

variable "s3_bucket" {
  type        = string
  description = "S3 bucket containing Lambda code zip"
}

variable "s3_key" {
  type        = string
  description = "S3 key for Lambda zip file"
}

variable "memory_size" {
  type        = number
  default     = 512
}

variable "timeout" {
  type        = number
  default     = 300
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
}

variable "environment" {
  type        = string
}
