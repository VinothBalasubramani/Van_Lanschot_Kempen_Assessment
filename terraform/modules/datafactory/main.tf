
variable "name"       { type = string }
variable "location"   { type = string }
variable "rg_name"    { type = string }
variable "tags"       { type = map(string) default = {} }

variable "target_storage_account_id" { type = string }
variable "target_sql_server_id"      { type = string }
variable "target_key_vault_id"       { type = string }

# Additional inputs for LS
variable "storage_account_name" { type = string }
variable "bronze_container"     { type = string default = "bronze" }
variable "sql_database_name"    { type = string default = null }
variable "databricks_workspace_url" { type = string } # https://adb-<id>.<region>.azuredatabricks.net

resource "azurerm_data_factory" "this" {
  name                  = var.name
  resource_group_name   = var.rg_name
  location              = var.location
  identity { type = "SystemAssigned" }
  public_network_enabled = false
  tags = var.tags
}

resource "azurerm_data_factory_integration_runtime_managed" "ir" {
  name            = "ir-managed-vnet"
  data_factory_id = azurerm_data_factory.this.id
  location        = var.location
  virtual_network_enabled = true
}

# Managed Private Endpoints
resource "azurerm_data_factory_managed_private_endpoint" "stg" {
  name               = "mpe-storage"
  data_factory_id    = azurerm_data_factory.this.id
  target_resource_id = var.target_storage_account_id
  subresource_name   = "blob"
}
resource "azurerm_data_factory_managed_private_endpoint" "sql" {
  name               = "mpe-sql"
  data_factory_id    = azurerm_data_factory.this.id
  target_resource_id = var.target_sql_server_id
  subresource_name   = "sqlServer"
}
resource "azurerm_data_factory_managed_private_endpoint" "kv" {
  name               = "mpe-kv"
  data_factory_id    = azurerm_data_factory.this.id
  target_resource_id = var.target_key_vault_id
  subresource_name   = "vault"
}

# Linked Services
resource "azurerm_data_factory_linked_service_azure_databricks" "dbx" {
  name            = "ls-databricks"
  data_factory_id = azurerm_data_factory.this.id
  access_token    = null
  msi_authentication {  }
  domain          = var.databricks_workspace_url
}

resource "azurerm_data_factory_linked_service_azure_sql_database" "sqldb" {
  name            = "ls-sqldb"
  data_factory_id = azurerm_data_factory.this.id
  connection_string = format("Data Source=tcp:%s,1433;Initial Catalog=%s;Encrypt=True;Connection Timeout=30;", 
    replace(var.target_sql_server_id, "/subscriptions", "server"), 
    coalesce(var.sql_database_name, "sqldb"))
  # use MSI
  key_vault_password_reference {
    # Placeholder if you later use SQL auth; with AAD MSI, password not needed
    secret_name    = "placeholder"
    secret_version = "00000000000000000000000000000000"
    store {
      reference_name = "kv-placeholder"
      type           = "LinkedServiceReference"
    }
  }
  # NOTE: For AAD MSI auth to Azure SQL, use the built-in "AzureSqlDatabase" LS with "authenticationType": "MSI"
  # The provider does not expose every property; consider ARM template spec if needed.
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "stg" {
  name            = "ls-storage-bronze"
  data_factory_id = azurerm_data_factory.this.id
  use_managed_identity = true
  connection_string    = null
}

# Datasets
resource "azurerm_data_factory_dataset_binary" "bronze_file" {
  name            = "ds-bronze-binary"
  data_factory_id = azurerm_data_factory.this.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.stg.name
  folder          = "datasets"
  dynamic_filename_enabled = true
  dynamic_path_enabled = true
}

resource "azurerm_data_factory_dataset_sql_table" "sql_table" {
  name            = "ds-sql-table"
  data_factory_id = azurerm_data_factory.this.id
  linked_service_name = azurerm_data_factory_linked_service_azure_sql_database.sqldb.name
  table_name      = "dbo.StageFromBronze"
  schema          = "dbo"
}

# Pipeline JSON (Databricks notebook activity -> placeholder copy)
locals {
  pl_json = jsonencode({
    name = "pl_bronze_to_sql"
    properties = {
      activities = [
        {
          name = "Run_Databricks_Notebook"
          type = "DatabricksNotebook"
          dependsOn = []
          policy = { timeout = "1.00:00:00", retry = 1, retryIntervalInSeconds = 30, secureOutput = false, secureInput = false }
          typeProperties = {
            notebookPath = "/Shared/bronze_to_silver"
            # parameters can be added here
          }
          linkedServiceName = { referenceName = azurerm_data_factory_linked_service_azure_databricks.dbx.name, type = "LinkedServiceReference" }
        },
        {
          name = "Upsert_To_SQL"
          type = "SqlServerStoredProcedure"
          dependsOn = [{ activity = "Run_Databricks_Notebook", dependencyConditions = ["Succeeded"] }]
          typeProperties = {
            storedProcedureName = "dbo.usp_UpsertFromLake"
          }
          linkedServiceName = { referenceName = azurerm_data_factory_linked_service_azure_sql_database.sqldb.name, type = "LinkedServiceReference" }
        }
      ]
      annotations = ["starter"]
    }
  })
}

resource "azurerm_data_factory_pipeline" "pl" {
  name            = "pl_bronze_to_sql"
  data_factory_id = azurerm_data_factory.this.id
  json            = local.pl_json
}

output "id"            { value = azurerm_data_factory.this.id }
output "name"          { value = azurerm_data_factory.this.name }
output "principal_id"  { value = azurerm_data_factory.this.identity[0].principal_id }
