
variable "workspace_id"     { type = string }
variable "catalog_name"     { type = string }
variable "create_metastore" { type = bool default = true }
variable "metastore_name"   { type = string default = null }
variable "storage_root"     { type = string }
variable "dev_group_name"   { type = string }
variable "admin_group_name" { type = string }

resource "databricks_metastore" "this" {
  count        = var.create_metastore ? 1 : 0
  name         = coalesce(var.metastore_name, "${var.catalog_name}-metastore")
  storage_root = var.storage_root
}

resource "databricks_metastore_assignment" "ws" {
  count        = var.create_metastore ? 1 : 0
  workspace_id = var.workspace_id
  metastore_id = databricks_metastore.this[0].id
}

resource "databricks_catalog" "team" { name = var.catalog_name }
resource "databricks_schema" "raw"    { name = "raw"    catalog_name = databricks_catalog.team.name }
resource "databricks_schema" "silver" { name = "silver" catalog_name = databricks_catalog.team.name }
resource "databricks_schema" "gold"   { name = "gold"   catalog_name = databricks_catalog.team.name }
resource "databricks_schema" "meta"   { name = "meta"   catalog_name = databricks_catalog.team.name }

resource "databricks_grants" "catalog" {
  catalog = databricks_catalog.team.name
  grant { principal = var.admin_group_name privileges = ["ALL PRIVILEGES"] }
  grant { principal = var.dev_group_name   privileges = ["USE CATALOG", "CREATE", "SELECT"] }
}

output "catalog" { value = databricks_catalog.team.name }
