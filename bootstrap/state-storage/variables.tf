variable "location" {
  description = "Azure region for Terraform State Resources"
}

variable "resource_group_name" {
  description = "Resource Group name for Terraform state storage."
  type        = string
}

variable "storage_account_name" {
  description = "Storage Account name for Terraform state. Must be globally unique."
  type        = string
}

variable "container_name" {
  description = "Blob container name for Terraform state files."
  type        = string
}

variable "tags" {
  description = "Tags for Terraform state resources."
  type        = map(string)
  default     = {}
}