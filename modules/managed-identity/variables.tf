variable "name" {
  description = "Name of the User Assigned Managed Identity."
  type        = string
}

variable "location" {
  description = "Azure region for the Managed Identity."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name where the Managed Identity will be created."
  type        = string
}

variable "tags" {
  description = "Tags for the Managed Identity."
  type        = map(string)
  default     = {}
}