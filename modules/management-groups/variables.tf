variable "management_groups" {
  description = "Parent management groups configuration"
  type = map(object({
    display_name = string
    parent_id    = string
  }))
}

variable "child_management_groups" {
  description = "Child management groups configuration"
  type = map(object({
    display_name = string
    parent_key   = string
  }))
  default = {}
}
