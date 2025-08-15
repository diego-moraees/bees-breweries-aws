variable "job_name" {
  description = "Glue job name"
  type        = string
}

variable "role_arn" {
  description = "IAM Role ARN for Glue job"
  type        = string
}

variable "script_location" {
  description = "S3 path for the Glue job script"
  type        = string
}

variable "glue_version" {
  description = "Glue version"
  type        = string
  default     = "3.0"
}

variable "number_of_workers" {
  description = "Number of workers"
  type        = number
  default     = 2
}

variable "worker_type" {
  description = "Type of worker (Standard, G.1X, G.2X)"
  type        = string
  default     = "G.1X"
}

variable "additional_arguments" {
  description = "Additional default arguments to pass to the Glue job"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment (ex: dev, prod)"
  type        = string
}
