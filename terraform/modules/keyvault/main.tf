
variable "name"        { type = string }
variable "location"    { type = string }
variable "rg_name"     { type = string }
variable "tags"        { type = map(string) default = {} }
variable "subnet_pe_id" { type = string }
variable "pdns_kv_id"   { type = string }
variable "adf_principal_id" { type = string default = null }
variable "dbx_principal_id" { type = string default = null }

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = var.name
  resource_group_name           = var.rg_name
  location                      = var.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  tags = var.tags
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pe-${var.name}-kv"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_pe_id
  private_service_connection {
    name                           = "kv-conn"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
  }
}

resource "azurerm_private_dns_zone_group" "kv" {
  name                 = "pdns-${var.name}-kv"
  private_endpoint_id  = azurerm_private_endpoint.kv.id
  private_dns_zone_ids = [var.pdns_kv_id]
}

resource "azurerm_role_assignment" "adf_secrets_user" {
  count                = var.adf_principal_id != null ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.adf_principal_id
}

resource "azurerm_role_assignment" "dbx_secrets_user" {
  count                = var.dbx_principal_id != null ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.dbx_principal_id
}

output "id"   { value = azurerm_key_vault.this.id }
output "name" { value = azurerm_key_vault.this.name }
