variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "schedule_expression" {
  type = string
} # ex: "cron(0 3 * * ? *)"

variable "state_machine_arn" {
  type = string
}