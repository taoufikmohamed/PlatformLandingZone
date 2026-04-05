variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "enable_management_groups" {
  description = "Enable management group creation and hierarchy setup"
  type        = bool
  default     = false
}

variable "enable_subscription_vending" {
  description = "Enable creation or association of subscriptions via billing scope"
  type        = bool
  default     = false
}

variable "enable_policies" {
  description = "Enable custom policy definitions and assignments at management group scope"
  type        = bool
  default     = false
}

variable "billing_scope_id" {
  description = "Billing scope ID for subscription creation (for EA/CSP)"
  type        = string
  default     = ""
}

variable "allowed_locations" {
  description = "List of allowed Azure regions"
  type        = list(string)
  default     = ["eastus", "westus", "westeurope", "southeastasia"]
}

variable "allowed_vm_skus" {
  description = "List of allowed VM SKUs"
  type        = list(string)
  default     = ["Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3", "Standard_B2s", "Standard_B2ms"]
}

variable "security_alert_email" {
  description = "Email address for security alerts"
  type        = string
  sensitive   = true
}

variable "enable_security_alerts" {
  description = "Enable monitoring action group and scheduled query alerts"
  type        = bool
  default     = false
}

variable "enable_example_secret" {
  description = "Enable creation of example secret in Key Vault"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Enable VPN gateway in hub network"
  type        = bool
  default     = false
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Standard"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "Production"
    Project     = "Platform Landing Zone"
    Compliance  = "Azure-CAF"
  }
}

variable "hub_vnet_address_space" {
  description = "Hub VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "corp_spoke_address_space" {
  description = "Corp spoke VNet address space"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "online_spoke_address_space" {
  description = "Online spoke VNet address space"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "enable_azure_firewall" {
  description = "Enable Azure Firewall in hub"
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = false
}
