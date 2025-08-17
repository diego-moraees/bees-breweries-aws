# Creates a Glue Catalog Database
resource "aws_glue_catalog_database" "this" {
  name        = var.name
  description = var.description
}