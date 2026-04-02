# Resource Group for security
resource "azurerm_resource_group" "security" {
  name     = "rg-security-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "kv-platform-${var.environment}-${random_string.suffix.result}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.security.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
  
  tags = var.tags
}

# Random suffix
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {
}

# Current user as Key Vault administrator
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  
  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover", "UnwrapKey", "WrapKey", "Verify", "Sign", "Encrypt", "Decrypt"
  ]
  
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover"
  ]
  
  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update"
  ]
}

# Example secret (to be replaced with actual secrets)
resource "azurerm_key_vault_secret" "example" {
  name         = "example-secret"
  value        = "ReplaceWithActualSecret"
  key_vault_id = azurerm_key_vault.main.id
  
  tags = var.tags
}

# Outputs
output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}
