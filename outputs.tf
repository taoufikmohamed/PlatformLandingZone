output "management_group_ids" {
  description = "IDs of created management groups"
  value       = try(module.management_groups[0].management_group_ids, {})
}

output "management_group_names" {
  description = "Names of created management groups"
  value       = try(module.management_groups[0].management_group_names, {})
}

output "subscription_ids" {
  description = "IDs of created subscriptions"
  value       = try(module.subscriptions[0].subscription_ids, {})
  sensitive   = true
}

output "hub_network_info" {
  description = "Hub network configuration"
  value = {
    vnet_id             = module.networking.hub_vnet_id
    vnet_name           = module.networking.hub_vnet_name
    firewall_private_ip = module.networking.firewall_private_ip
    firewall_public_ip  = module.networking.firewall_public_ip
    bastion_host_id     = module.networking.bastion_host_id
    bastion_public_ip   = module.networking.bastion_public_ip
  }
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace Name"
  value       = module.monitoring.log_analytics_workspace_name
}

output "key_vault_id" {
  description = "Key Vault ID for secrets management"
  value       = module.security.key_vault_id
  sensitive   = true
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.security.key_vault_uri
}

output "deployment_summary" {
  description = "Summary of deployment"
  value = {
    environment       = var.environment
    location          = var.location
    management_groups = keys(try(module.management_groups[0].management_group_ids, {}))
    subscriptions     = try(module.subscriptions[0].subscription_keys, [])
    has_firewall      = var.enable_azure_firewall
    has_bastion       = var.enable_bastion
  }
}
