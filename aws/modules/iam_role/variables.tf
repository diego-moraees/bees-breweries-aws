variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "assume_role_policy" {
  description = "JSON for assume role policy"
  type        = string
}

variable "policy_arns" {
  description = "List of policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment (ex: dev, prod)"
  type        = string
}
