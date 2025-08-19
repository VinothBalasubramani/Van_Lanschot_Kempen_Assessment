
variable "name_prefix" { type = string }
variable "location"    { type = string }
variable "rg_name"     { type = string }
variable "address_space" { type = list(string) }
variable "tags"        { type = map(string) default = {} }

resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-vnet"
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_subnet" "dbx_private" {
  name                 = "snet-dbx-private"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 4, 1)]
  delegation {
    name = "databricks"
    service_delegation { name = "Microsoft.Databricks/workspaces" }
  }
}

resource "azurerm_subnet" "dbx_public" {
  name                 = "snet-dbx-public"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 4, 2)]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-pe"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 4, 3)]
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "blob"  { name = "privatelink.blob.core.windows.net"  resource_group_name = var.rg_name }
resource "azurerm_private_dns_zone" "dfs"   { name = "privatelink.dfs.core.windows.net"   resource_group_name = var.rg_name }
resource "azurerm_private_dns_zone" "queue" { name = "privatelink.queue.core.windows.net" resource_group_name = var.rg_name }
resource "azurerm_private_dns_zone" "table" { name = "privatelink.table.core.windows.net" resource_group_name = var.rg_name }
resource "azurerm_private_dns_zone" "sql"   { name = "privatelink.database.windows.net"   resource_group_name = var.rg_name }
resource "azurerm_private_dns_zone" "kv"    { name = "privatelink.vaultcore.azure.net"    resource_group_name = var.rg_name }

# VNet links
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "link-${var.name_prefix}-blob"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "dfs" {
  name                  = "link-${var.name_prefix}-dfs"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.dfs.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  name                  = "link-${var.name_prefix}-queue"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "link-${var.name_prefix}-table"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "link-${var.name_prefix}-sql"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "link-${var.name_prefix}-kv"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
}

output "vnet_id"              { value = azurerm_virtual_network.this.id }
output "subnet_dbx_private_id"  { value = azurerm_subnet.dbx_private.id }
output "subnet_dbx_public_id"   { value = azurerm_subnet.dbx_public.id }
output "subnet_pe_id"         { value = azurerm_subnet.private_endpoints.id }

output "pdns_blob_id"  { value = azurerm_private_dns_zone.blob.id }
output "pdns_dfs_id"   { value = azurerm_private_dns_zone.dfs.id }
output "pdns_queue_id" { value = azurerm_private_dns_zone.queue.id }
output "pdns_table_id" { value = azurerm_private_dns_zone.table.id }
output "pdns_sql_id"   { value = azurerm_private_dns_zone.sql.id }
output "pdns_kv_id"    { value = azurerm_private_dns_zone.kv.id }
