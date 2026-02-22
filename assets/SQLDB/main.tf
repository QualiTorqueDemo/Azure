resource "random_id" "name" {
  byte_length = 8
}

resource "random_password" "password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = "${var.resource_group_name}-${random_id.name.hex}"
}

data "azurerm_client_config" "current" {}

resource "azurerm_mssql_server" "sql" {
  name                         = "sqlserver-${random_id.name.hex}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.password.result
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username = "sqladmin"
    tenant_id      = data.azurerm_client_config.current.tenant_id
    object_id      = coalesce(var.msi_id, data.azurerm_client_config.current.object_id)
  }
}

resource "azurerm_mssql_database" "db" {
  name      = "${var.db_name}-${random_id.name.hex}"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "S0"
}

resource "azurerm_mssql_firewall_rule" "fw" {
  name             = "AllowAccess"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = var.start_ip_address
  end_ip_address   = var.end_ip_address
}