# For EA/CSP environments, use this resource
resource "azurerm_subscription" "new" {
  for_each = {
    for k, v in var.subscriptions : k => v
    if v.subscription_id == "" && var.billing_scope_id != ""
  }

  subscription_name = each.value.display_name
  billing_scope_id  = var.billing_scope_id
  workload          = "Production"
}

# For existing subscriptions
data "azurerm_subscription" "existing" {
  for_each = {
    for k, v in var.subscriptions : k => v
    if v.subscription_id != ""
  }

  subscription_id = each.value.subscription_id
}

# Move subscription to management group
resource "azurerm_management_group_subscription_association" "assoc" {
  for_each = {
    for k, v in var.subscriptions : k => v
    if v.subscription_id != ""
  }

  management_group_id = each.value.management_group_id
  subscription_id     = each.value.subscription_id
}

output "subscription_ids" {
  value = {
    for k, v in var.subscriptions : k => try(
      azurerm_subscription.new[k].subscription_id,
      data.azurerm_subscription.existing[k].subscription_id,
      v.subscription_id
    )
  }
  sensitive = true
}

output "subscription_keys" {
  value = keys(var.subscriptions)
}

output "subscription_names" {
  value = {
    for k, v in var.subscriptions : k => v.display_name
  }
}
