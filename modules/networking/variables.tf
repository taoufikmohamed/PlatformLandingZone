variable "subscription_id" {
  description = "Subscription ID for networking resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "hub_vnet" {
  description = "Hub VNet configuration"
  type = object({
    name          = string
    address_space = list(string)
    subnets = map(object({
      address_prefixes  = list(string)
      service_endpoints = list(string)
    }))
  })
}

variable "spoke_vnets" {
  description = "Spoke VNets configuration"
  type = map(object({
    name          = string
    address_space = list(string)
    subnets = map(object({
      address_prefixes  = list(string)
      service_endpoints = list(string)
    }))
  }))
}

variable "enable_azure_firewall" {
  description = "Enable Azure Firewall"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection"
  type        = bool
  default     = false
}
