# Resource Group
resource "azurerm_resource_group" "networking" {
  name     = "rg-networking-${var.environment}"
  location = var.location
  tags     = var.tags
}

# DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "main" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "ddos-plan-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.networking.name
  tags                = var.tags
}

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet.name
  resource_group_name = azurerm_resource_group.networking.name
  location            = var.location
  address_space       = var.hub_vnet.address_space
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = azurerm_network_ddos_protection_plan.main[0].id
      enable = true
    }
  }
}

# Hub Subnets
resource "azurerm_subnet" "hub" {
  for_each = var.hub_vnet.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

# Public IP for Firewall
resource "azurerm_public_ip" "firewall" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = "pip-azure-firewall-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.networking.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = "fw-${var.environment}"
  resource_group_name = azurerm_resource_group.networking.name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

# Firewall Rules
resource "azurerm_firewall_network_rule_collection" "allow_outbound" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = "allow-outbound"
  azure_firewall_name = azurerm_firewall.main[0].name
  resource_group_name = azurerm_resource_group.networking.name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "allow-https"
    protocols             = ["TCP"]
    source_addresses      = ["*"]
    destination_addresses = ["*"]
    destination_ports     = ["443"]
  }

  rule {
    name                  = "allow-dns"
    protocols             = ["UDP"]
    source_addresses      = ["*"]
    destination_addresses = ["8.8.8.8", "8.8.4.4"]
    destination_ports     = ["53"]
  }
}

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                = "pip-bastion-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.networking.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

# Azure Bastion
resource "azurerm_bastion_host" "main" {
  count = var.enable_bastion ? 1 : 0

  name                = "bastion-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.networking.name
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

# Spoke Virtual Networks
resource "azurerm_virtual_network" "spoke" {
  for_each = var.spoke_vnets

  name                = each.value.name
  resource_group_name = azurerm_resource_group.networking.name
  location            = var.location
  address_space       = each.value.address_space
  tags                = var.tags
}

# Spoke Subnets
resource "azurerm_subnet" "spoke" {
  for_each = {
    for pair in flatten([
      for vnet_name, vnet in var.spoke_vnets : [
        for subnet_name, subnet in vnet.subnets : {
          key               = "${vnet_name}-${subnet_name}"
          vnet_name         = vnet_name
          subnet_name       = subnet_name
          address_prefixes  = subnet.address_prefixes
          service_endpoints = subnet.service_endpoints
        }
      ]
    ]) : pair.key => pair
  }

  name                 = each.value.subnet_name
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.spoke[each.value.vnet_name].name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

# VNet Peering: Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_vnets

  name                         = "hub-to-${each.key}"
  resource_group_name          = azurerm_resource_group.networking.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spoke_vnets

  name                         = "${each.key}-to-hub"
  resource_group_name          = azurerm_resource_group.networking.name
  virtual_network_name         = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# Route Tables for Spokes to force tunnel through Firewall
resource "azurerm_route_table" "spoke" {
  for_each = var.spoke_vnets

  name                = "rt-${each.key}-to-firewall"
  location            = var.location
  resource_group_name = azurerm_resource_group.networking.name
  tags                = var.tags

  dynamic "route" {
    for_each = var.enable_azure_firewall ? [1] : []
    content {
      name                   = "default-route"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_firewall.main[0].ip_configuration[0].private_ip_address
    }
  }
}

# Associate route tables with subnets
resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = {
    for pair in flatten([
      for vnet_name, vnet in var.spoke_vnets : [
        for subnet_name, subnet in vnet.subnets : {
          key            = "${vnet_name}-${subnet_name}"
          subnet_id      = azurerm_subnet.spoke["${vnet_name}-${subnet_name}"].id
          route_table_id = azurerm_route_table.spoke[vnet_name].id
        }
      ]
    ]) : pair.key => pair
  }

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}

# Outputs
output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "firewall_private_ip" {
  value = var.enable_azure_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
}

output "firewall_public_ip" {
  value = var.enable_azure_firewall ? azurerm_public_ip.firewall[0].ip_address : null
}

output "bastion_host_id" {
  value = var.enable_bastion ? azurerm_bastion_host.main[0].id : null
}

output "bastion_public_ip" {
  value = var.enable_bastion ? azurerm_public_ip.bastion[0].ip_address : null
}

output "spoke_vnet_ids" {
  value = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}
