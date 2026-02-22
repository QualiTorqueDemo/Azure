output "database_name" {
  value = azurerm_mssql_database.db.name
}

output "sql_admin_username" {
  value = var.sql_admin_username
}

output "sql_password" {
  sensitive = true
  value     = random_password.password.result
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql.name
}