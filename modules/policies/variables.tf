variable "management_group_ids" {
  description = "Management group IDs"
  type        = map(string)
}

variable "allowed_locations" {
  description = "List of allowed locations"
  type        = list(string)
}

variable "allowed_vm_skus" {
  description = "List of allowed VM SKUs"
  type        = list(string)
}
