variable "environment_name" {
  type = string
}

variable "airflow_version" {
  type    = string
  default = "2.5.1"
}

variable "environment_class"{
  type = string
  default = "mw1.small"
}

variable "dag_s3_bucket_arn" {
  type = string
}

variable "dag_s3_path"       {
  type = string
  default = "dags"
}

variable "requirements_s3_path" {
  type = string
  default = ""
}

variable "plugins_s3_path"      {
  type = string
  default = ""
}

variable "execution_role_arn" {
  type = string
}

variable "subnet_ids"         {
  type = list(string)
  default = []
}

variable "security_group_ids" {
  type = list(string)
  default = []
}

variable "webserver_access_mode" {
  type = string
  default = "PUBLIC_ONLY"
}

variable "airflow_configuration_options" {
  description = "Map of Airflow config overrides"
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
