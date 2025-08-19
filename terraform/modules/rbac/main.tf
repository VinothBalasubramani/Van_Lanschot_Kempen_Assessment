
variable "rg_id"                { type = string }
variable "storage_account_id"   { type = string }
variable "kv_id"                { type = string }
variable "sql_server_id"        { type = string }
variable "df_principal_id"      { type = string }
variable "dbx_group_object_id"  { type = string }
variable "admin_group_object_id"{ type = string }

resource "azurerm_role_assignment" "rg_reader_dev" {
  scope                = var.rg_id
  role_definition_name = "Reader"
  principal_id         = var.dbx_group_object_id
}

resource "azurerm_role_assignment" "stg_contrib" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.dbx_group_object_id
}

resource "azurerm_role_assignment" "kv_secrets_user_adf" {
  scope                = var.kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.df_principal_id
}

resource "azurerm_role_assignment" "sql_contrib_admins" {
  scope                = var.sql_server_id
  role_definition_name = "SQL Server Contributor"
  principal_id         = var.admin_group_object_id
}
