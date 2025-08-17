module "alerts_sns" {
  source      = "../../modules/sns"
  environment = var.environment
  email       = var.alert_email
}