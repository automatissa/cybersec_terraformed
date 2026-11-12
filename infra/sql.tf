resource "azurerm_mssql_server" "sql" {
  name                         = "sql-namecounter-${var.environment}-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"

  tags = azurerm_resource_group.rg.tags
}

resource "azurerm_mssql_database" "db" {
  name                        = "NameCounterDB"
  server_id                   = azurerm_mssql_server.sql.id
  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  zone_redundant              = false

  tags = azurerm_resource_group.rg.tags
}

# 6.5.2 a) Tried: replace the 0.0.0.0 rule with the Function's outbound IPs only.
# Result on Linux Consumption (Y1): the Function connected from 131.189.239.33,
# an IP absent from both possible_outbound_ip_addresses and outbound_ip_addresses,
# so calls failed at random (error 40615). The 0.0.0.0 rule is kept until
# Level 2 (VNet integration + private endpoint) provides real isolation.
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Per-IP rules kept: harmless, and they document the published list.
locals {
  function_outbound_ips = toset(split(",", azurerm_linux_function_app.app.possible_outbound_ip_addresses))
}

resource "azurerm_mssql_firewall_rule" "function_outbound" {
  for_each         = local.function_outbound_ips
  name             = "func-${replace(each.value, ".", "-")}"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

# 6.5.2 b) Workstation access only during maintenance windows.
resource "azurerm_mssql_firewall_rule" "allow_student_ip" {
  count            = var.allow_workstation_access ? 1 : 0
  name             = "AllowStudentWorkstation"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = var.client_ip_address
  end_ip_address   = var.client_ip_address
}

# Adding count changes the address; this tells Terraform it is the same rule
# (no destroy/recreate).
moved {
  from = azurerm_mssql_firewall_rule.allow_student_ip
  to   = azurerm_mssql_firewall_rule.allow_student_ip[0]
}