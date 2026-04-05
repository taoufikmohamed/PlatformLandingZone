# Built-in policy: Allowed locations
resource "azurerm_policy_definition" "allowed_locations" {
  name                = "allowed-locations"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Allowed locations"
  description         = "Restrict locations to allowed regions"
  management_group_id = var.management_group_ids["platform"]

  metadata = jsonencode({
    version  = "1.0.0"
    category = "General"
  })

  parameters = jsonencode({
    listOfAllowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed locations"
        description = "The list of allowed locations for resources."
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = "[parameters('listOfAllowedLocations')]"
      }
    }
    then = {
      effect = "Deny"
    }
  })
}

# Built-in policy: Allowed VM SKUs
resource "azurerm_policy_definition" "allowed_vm_skus" {
  name                = "allowed-vm-skus"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Allowed virtual machine SKUs"
  description         = "Restrict VM SKUs to approved list"
  management_group_id = var.management_group_ids["platform"]

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Compute"
  })

  parameters = jsonencode({
    listOfAllowedSKUs = {
      type = "Array"
      metadata = {
        displayName = "Allowed SKUs"
        description = "The list of allowed SKUs for virtual machines."
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          not = {
            field = "Microsoft.Compute/virtualMachines/sku.name"
            in    = "[parameters('listOfAllowedSKUs')]"
          }
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# Policy: Enforce HTTPS for storage accounts
resource "azurerm_policy_definition" "storage_https" {
  name                = "storage-https-only"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Enforce HTTPS for storage accounts"
  description         = "Require HTTPS traffic for storage accounts"
  management_group_id = var.management_group_ids["platform"]

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Storage"
  })

  parameters = jsonencode({})

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field     = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly"
          notEquals = true
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# Assign policies to management groups
resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "assign-allowed-locations"
  management_group_id  = var.management_group_ids["platform"]
  policy_definition_id = azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
  })
}

resource "azurerm_management_group_policy_assignment" "allowed_vm_skus" {
  name                 = "assign-allowed-vm-skus"
  management_group_id  = var.management_group_ids["landing-zones"]
  policy_definition_id = azurerm_policy_definition.allowed_vm_skus.id

  parameters = jsonencode({
    listOfAllowedSKUs = {
      value = var.allowed_vm_skus
    }
  })
}

resource "azurerm_management_group_policy_assignment" "storage_https" {
  name                 = "assign-storage-https"
  management_group_id  = var.management_group_ids["platform"]
  policy_definition_id = azurerm_policy_definition.storage_https.id

  parameters = jsonencode({})
}

# Outputs
output "policy_ids" {
  value = {
    allowed_locations = azurerm_policy_definition.allowed_locations.id
    allowed_vm_skus   = azurerm_policy_definition.allowed_vm_skus.id
    storage_https     = azurerm_policy_definition.storage_https.id
  }
}
