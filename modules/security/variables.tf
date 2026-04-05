variable "subscription_id" {
  description = "Subscription ID for security resources"
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

variable "enable_example_secret" {
  description = "Enable creation of example secret"
  type        = bool
  default     = false
}
