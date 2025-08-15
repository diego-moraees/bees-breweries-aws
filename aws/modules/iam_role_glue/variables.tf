variable "role_name" {
  description = "Glue IAM role name"
  type        = string
}

variable "buckets" {
  description = "Comma separated list of S3 buckets the Glue job can access"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod etc)"
  type        = string
}
