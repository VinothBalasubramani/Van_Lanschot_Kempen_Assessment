
variable "name"          { type = string }
variable "location"      { type = string }
variable "rg_name"       { type = string }
variable "tags"          { type = map(string) default = {} }
variable "subnet_pe_id"  { type = string }
variable "pdns_blob_id"  { type = string }
variable "pdns_dfs_id"   { type = string }
variable "pdns_queue_id" { type = string }
variable "pdns_table_id" { type = string }

resource "azurerm_storage_account" "this" {
  name                         = var.name
  resource_group_name          = var.rg_name
  location                     = var.location
  account_tier                 = "Standard"
  account_replication_type     = "RAGZRS"
  account_kind                 = "StorageV2"
  is_hns_enabled               = true
  min_tls_version              = "TLS1_2"
  public_network_access_enabled = false
  tags = var.tags
}

resource "azurerm_storage_container" "bronze" { name = "bronze"  storage_account_name = azurerm_storage_account.this.name }
resource "azurerm_storage_container" "silver" { name = "silver"  storage_account_name = azurerm_storage_account.this.name }
resource "azurerm_storage_container" "gold"   { name = "gold"    storage_account_name = azurerm_storage_account.this.name }
resource "azurerm_storage_container" "meta"   { name = "meta"    storage_account_name = azurerm_storage_account.this.name }

resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.this.id
  rule {
    name    = "tier-and-retain"
    enabled = true
    filters { prefix_match = ["bronze/", "silver/"] }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        delete_after_days_since_modification_greater_than       = 180
      }
      snapshot { delete_after_days_since_creation_greater_than  = 30 }
    }
  }
}

# Private Endpoints + DNS zone groups
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-${var.name}-blob"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_pe_id
  private_service_connection {
    name                           = "blob-conn"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
  }
}
resource "azurerm_private_dns_zone_group" "blob" {
  name                 = "pdns-${var.name}-blob"
  private_endpoint_id  = azurerm_private_endpoint.blob.id
  private_dns_zone_ids = [var.pdns_blob_id]
}

resource "azurerm_private_endpoint" "dfs" {
  name                = "pe-${var.name}-dfs"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_pe_id
  private_service_connection {
    name                           = "dfs-conn"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["dfs"]
  }
}
resource "azurerm_private_dns_zone_group" "dfs" {
  name                 = "pdns-${var.name}-dfs"
  private_endpoint_id  = azurerm_private_endpoint.dfs.id
  private_dns_zone_ids = [var.pdns_dfs_id]
}

resource "azurerm_private_endpoint" "queue" {
  name                = "pe-${var.name}-queue"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_pe_id
  private_service_connection {
    name                           = "queue-conn"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["queue"]
  }
}
resource "azurerm_private_dns_zone_group" "queue" {
  name                 = "pdns-${var.name}-queue"
  private_endpoint_id  = azurerm_private_endpoint.queue.id
  private_dns_zone_ids = [var.pdns_queue_id]
}

resource "azurerm_private_endpoint" "table" {
  name                = "pe-${var.name}-table"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_pe_id
  private_service_connection {
    name                           = "table-conn"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["table"]
  }
}
resource "azurerm_private_dns_zone_group" "table" {
  name                 = "pdns-${var.name}-table"
  private_endpoint_id  = azurerm_private_endpoint.table.id
  private_dns_zone_ids = [var.pdns_table_id]
}

output "account_name"  { value = azurerm_storage_account.this.name }
output "account_id"    { value = azurerm_storage_account.this.id }
output "dfs_uri"       { value = "abfss://@${azurerm_storage_account.this.name}.dfs.core.windows.net/" }
