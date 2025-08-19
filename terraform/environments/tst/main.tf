
variable "subscription_id" { type = string }
variable "location"        { type = string  default = "westeurope" }
variable "env"             { type = string  default = "tst" }
variable "tags"            { type = map(string) default = { env = "tst", owner = "strada" } }

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-strada-tfstate"
    storage_account_name = "stradatfstate"
    container_name       = "tfstate"
    key                  = "downstream-tst.tfstate"
  }
}

provider "azurerm" {
  features { }
  subscription_id = var.subscription_id
}

provider "databricks" {
  host = "https://adb-2222222222222222.10.azuredatabricks.net"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-strada-downstream-tst"
  location = var.location
  tags     = var.tags
}

module "network" {
  source         = "../../modules/network"
  name_prefix    = "dst-tst"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name
  address_space  = ["10.20.0.0/20"]
  tags           = var.tags
}

module "storage" {
  source          = "../../modules/storage"
  name            = "stgdsttstadls"
  location        = var.location
  rg_name         = azurerm_resource_group.rg.name
  tags            = var.tags
  subnet_pe_id    = module.network.subnet_pe_id
  pdns_blob_id    = module.network.pdns_blob_id
  pdns_dfs_id     = module.network.pdns_dfs_id
  pdns_queue_id   = module.network.pdns_queue_id
  pdns_table_id   = module.network.pdns_table_id
}

module "sql" {
  source               = "../../modules/sql"
  name_prefix          = "dst-tst"
  location             = var.location
  rg_name              = azurerm_resource_group.rg.name
  aad_admin_object_id  = "00000000-0000-0000-0000-000000000000"
  tags                 = var.tags
  subnet_pe_id         = module.network.subnet_pe_id
  pdns_sql_id          = module.network.pdns_sql_id
}

module "kv" {
  source            = "../../modules/keyvault"
  name              = "kv-dst-tst"
  location          = var.location
  rg_name           = azurerm_resource_group.rg.name
  tags              = var.tags
  subnet_pe_id      = module.network.subnet_pe_id
  pdns_kv_id        = module.network.pdns_kv_id
}

module "adf" {
  source                    = "../../modules/datafactory"
  name                      = "adf-dst-tst"
  location                  = var.location
  rg_name                   = azurerm_resource_group.rg.name
  tags                      = var.tags
  target_storage_account_id = module.storage.account_id
  target_sql_server_id      = module.sql.server_id
  target_key_vault_id       = module.kv.id
  storage_account_name      = module.storage.account_name
  sql_database_name         = "dst_tst_sqldb"
  databricks_workspace_url  = "https://adb-2222222222222222.10.azuredatabricks.net"
}

module "dbx_uc" {
  source            = "../../modules/databricks"
  workspace_id      = "2222222222222222"
  catalog_name      = "team_tst"
  create_metastore  = true
  metastore_name    = "uc-tst-metastore"
  storage_root      = "abfss://uc-tst@${module.storage.account_name}.dfs.core.windows.net/"
  dev_group_name    = "sg-dbx-developer-tst"
  admin_group_name  = "sg-dbx-admin-tst"
}

module "rbac" {
  source                 = "../../modules/rbac"
  rg_id                  = azurerm_resource_group.rg.id
  storage_account_id     = module.storage.account_id
  kv_id                  = module.kv.id
  sql_server_id          = module.sql.server_id
  df_principal_id        = module.adf.principal_id
  dbx_group_object_id    = "11111111-1111-1111-1111-111111111111"
  admin_group_object_id  = "22222222-2222-2222-2222-222222222222"
}

# Policy assignments are optional; disabled by default
module "policy" {
  source   = "../../modules/policy"
  scope_id = azurerm_resource_group.rg.id
  enabled  = false
  # Provide built-in policy IDs here if you want to enable
}

output "storage_account" { value = module.storage.account_name }
output "key_vault"       { value = module.kv.name }
output "sql_server"      { value = module.sql.server_fqdn }
output "uc_catalog"      { value = module.dbx_uc.catalog }
