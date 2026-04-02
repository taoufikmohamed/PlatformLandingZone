# Data sources for current context
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Module: Management Groups
module "management_groups" {
  source = "./modules/management-groups"

  management_groups = {
    "platform" = {
      display_name = "Platform"
      parent_id    = null
    }
    "landing-zones" = {
      display_name = "Landing Zones"
      parent_id    = null
    }
    "sandbox" = {
      display_name = "Sandbox"
      parent_id    = null
    }
    "decommissioned" = {
      display_name = "Decommissioned"
      parent_id    = null
    }
  }

  child_management_groups = {
    "identity" = {
      display_name = "Identity"
      parent_key   = "platform"
    }
    "management" = {
      display_name = "Management"
      parent_key   = "platform"
    }
    "connectivity" = {
      display_name = "Connectivity"
      parent_key   = "platform"
    }
    "corp" = {
      display_name = "Corp"
      parent_key   = "landing-zones"
    }
    "online" = {
      display_name = "Online"
      parent_key   = "landing-zones"
    }
  }
}

# Module: Subscriptions (if billing scope provided)
module "subscriptions" {
  source     = "./modules/subscriptions"
  depends_on = [module.management_groups]

  billing_scope_id = var.billing_scope_id

  subscriptions = {
    "connectivity" = {
      display_name        = "Connectivity-${var.environment}"
      management_group_id = module.management_groups.management_group_ids["connectivity"]
      subscription_id     = ""
    }
    "management" = {
      display_name        = "Management-${var.environment}"
      management_group_id = module.management_groups.management_group_ids["management"]
      subscription_id     = ""
    }
    "identity" = {
      display_name        = "Identity-${var.environment}"
      management_group_id = module.management_groups.management_group_ids["identity"]
      subscription_id     = ""
    }
    "corp" = {
      display_name        = "Corp-${var.environment}"
      management_group_id = module.management_groups.management_group_ids["corp"]
      subscription_id     = ""
    }
    "online" = {
      display_name        = "Online-${var.environment}"
      management_group_id = module.management_groups.management_group_ids["online"]
      subscription_id     = ""
    }
  }
}

# Module: Security (Key Vault, RBAC)
module "security" {
  source = "./modules/security"

  subscription_id = var.billing_scope_id != "" ? module.subscriptions.subscription_ids["management"] : data.azurerm_subscription.current.id
  location        = var.location
  environment     = var.environment
  tags            = var.tags
}

# Module: Networking (Hub & Spokes)
module "networking" {
  source = "./modules/networking"

  subscription_id = var.billing_scope_id != "" ? module.subscriptions.subscription_ids["connectivity"] : data.azurerm_subscription.current.id
  location        = var.location
  environment     = var.environment
  tags            = var.tags

  hub_vnet = {
    name          = "hub-vnet-${var.environment}"
    address_space = var.hub_vnet_address_space
    subnets = {
      "AzureFirewallSubnet" = {
        address_prefixes  = ["10.0.1.0/24"]
        service_endpoints = []
      }
      "AzureBastionSubnet" = {
        address_prefixes  = ["10.0.2.0/24"]
        service_endpoints = []
      }
      "GatewaySubnet" = {
        address_prefixes  = ["10.0.3.0/24"]
        service_endpoints = []
      }
      "Management" = {
        address_prefixes  = ["10.0.4.0/24"]
        service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      }
      "SharedServices" = {
        address_prefixes  = ["10.0.5.0/24"]
        service_endpoints = ["Microsoft.Storage"]
      }
    }
  }

  spoke_vnets = {
    "corp" = {
      name          = "corp-spoke-vnet-${var.environment}"
      address_space = var.corp_spoke_address_space
      subnets = {
        "Workloads" = {
          address_prefixes  = ["10.1.1.0/24"]
          service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
        }
        "Data" = {
          address_prefixes  = ["10.1.2.0/24"]
          service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
        }
        "App" = {
          address_prefixes  = ["10.1.3.0/24"]
          service_endpoints = ["Microsoft.Storage"]
        }
      }
    }
    "online" = {
      name          = "online-spoke-vnet-${var.environment}"
      address_space = var.online_spoke_address_space
      subnets = {
        "Web" = {
          address_prefixes  = ["10.2.1.0/24"]
          service_endpoints = ["Microsoft.Storage"]
        }
        "App" = {
          address_prefixes  = ["10.2.2.0/24"]
          service_endpoints = ["Microsoft.Storage"]
        }
        "DB" = {
          address_prefixes  = ["10.2.3.0/24"]
          service_endpoints = ["Microsoft.Sql"]
        }
      }
    }
  }

  enable_azure_firewall  = var.enable_azure_firewall
  enable_bastion         = var.enable_bastion
  enable_vpn_gateway     = var.enable_vpn_gateway
  enable_ddos_protection = var.enable_ddos_protection
}

# Module: Azure Policies
module "policies" {
  source     = "./modules/policies"
  depends_on = [module.management_groups]

  management_group_ids = module.management_groups.management_group_ids

  allowed_locations = var.allowed_locations
  allowed_vm_skus   = var.allowed_vm_skus
}

# Module: Monitoring and Logging
module "monitoring" {
  source = "./modules/monitoring"

  subscription_id = var.billing_scope_id != "" ? module.subscriptions.subscription_ids["management"] : data.azurerm_subscription.current.id
  location        = var.location
  environment     = var.environment
  tags            = var.tags

  log_analytics_workspace_name = "law-platform-${var.environment}-${random_string.suffix.result}"
  log_retention_days           = var.log_retention_days

  security_alert_email = var.security_alert_email
}
