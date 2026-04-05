resource "azurerm_management_group" "parent" {
  for_each = var.management_groups

  display_name               = each.value.display_name
  parent_management_group_id = each.value.parent_id

  name = replace(lower(replace(each.value.display_name, " ", "-")), "_", "-")
}

resource "azurerm_management_group" "child" {
  for_each = var.child_management_groups

  display_name               = each.value.display_name
  parent_management_group_id = azurerm_management_group.parent[each.value.parent_key].id

  name = replace(lower(replace(each.value.display_name, " ", "-")), "_", "-")
}

output "management_group_ids" {
  value = merge(
    { for k, v in azurerm_management_group.parent : k => v.id },
    { for k, v in azurerm_management_group.child : k => v.id }
  )
}

output "management_group_names" {
  value = merge(
    { for k, v in azurerm_management_group.parent : k => v.name },
    { for k, v in azurerm_management_group.child : k => v.name }
  )
}
