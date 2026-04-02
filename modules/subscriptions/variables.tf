variable "subscriptions" {
  description = "Subscriptions configuration"
  type = map(object({
    display_name        = string
    management_group_id = string
    subscription_id     = string
  }))
}

variable "billing_scope_id" {
  description = "Billing scope ID for subscription creation"
  type        = string
  default     = ""
}
