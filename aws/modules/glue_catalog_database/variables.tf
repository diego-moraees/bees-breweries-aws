variable "name" {
  type        = string
  description = "Glue database name"
}

variable "description" {
  type        = string
  description = "Database description"
  default     = "Managed by Terraform"
}
