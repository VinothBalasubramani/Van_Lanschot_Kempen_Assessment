
variable "name_prefix"    { type = string }
variable "location"       { type = string }
variable "rg_name"        { type = string }
variable "aad_admin_object_id" { type = string }
variable "tags"           { type = map(string) default = {} }
variable "subnet_pe_id"   { type = string }
variable "pdns_sql_id"    { type = string }

resource "random_password" "sql" { length = 20 special = true }

resource "azurerm_mssql_server" "this" {
  name                          = "${var.name_prefix}-sqlsrv"
  resource_group_name           = var.rg_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = "sqladminuser"
  administrator_login_password  = random_password.sql.result
  public_network_access_enabled = false
  identity { type = "SystemAssigned" }

  azuread_administrator {
    login_username = "aad-admin"
    object_id      = var.aad_admin_object_id
  }

  tags = var.tags
}

resource "azurerm_mssql_database" "db" {
  name      = "${var.name_prefix}-sqldb"
  server_id = azurerm_mssql_server.this.id
  sku_name  = "S0"
  tags      = var.tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-${var.name_prefix}-sql"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_pe_id
  private_service_connection {
    name                           = "sql-conn"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
  }
}

resource "azurerm_private_dns_zone_group" "sql" {
  name                 = "pdns-${var.name_prefix}-sql"
  private_endpoint_id  = azurerm_private_endpoint.sql.id
  private_dns_zone_ids = [var.pdns_sql_id]
}

output "server_fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
output "server_id"   { value = azurerm_mssql_server.this.id }
output "database_id" { value = azurerm_mssql_database.db.id }
