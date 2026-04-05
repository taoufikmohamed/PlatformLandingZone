variable "subscription_id" {
  description = "Subscription ID for monitoring resources"
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

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 365
}

variable "security_alert_email" {
  description = "Email for security alerts"
  type        = string
  sensitive   = true
}

variable "enable_security_alerts" {
  description = "Enable monitoring action group and scheduled query alerts"
  type        = bool
  default     = false
}
