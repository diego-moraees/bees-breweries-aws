variable "environment" {
  type = string
}

variable "topic_name"   {
  type = string
  default = "bees-pipeline-alerts"
}

variable "email"        {
  type = string
  default = "diego.moraees@outlook.com"
}