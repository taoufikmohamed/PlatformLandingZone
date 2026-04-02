# Resource Group for monitoring
resource "azurerm_resource_group" "monitoring" {
  name     = "rg-monitoring-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "appinsights-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.monitoring.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

# Action Group for alerts
resource "azurerm_monitor_action_group" "security" {
  name                = "security-alerts"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "sec-alert"
  
  email_receiver {
    name          = "security-team"
    email_address = var.security_alert_email
  }
}

# Alert: High network egress
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_egress" {
  name                = "high-network-egress"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = var.location
  
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  severity             = 1
  scopes              = [azurerm_log_analytics_workspace.main.id]
  
  criteria {
    query = <<-QUERY
      AzureDiagnostics
      | where Category == "AzureFirewallApplicationRule"
      | summarize TotalBytes = sum(Amount) by bin(TimeGenerated, 5m)
    QUERY
    
    metric_measure_column   = "TotalBytes"
    time_aggregation_method = "Total"
    threshold              = 1000000000
    operator               = "GreaterThan"
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  
  action {
    action_groups = [azurerm_monitor_action_group.security.id]
  }
}

# Diagnostic settings for all resources (to be applied by policy)

data "azurerm_subscription" "current" {
}

# Outputs
output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.main.name
}

output "application_insights_id" {
  value = azurerm_application_insights.main.id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.security.id
}
