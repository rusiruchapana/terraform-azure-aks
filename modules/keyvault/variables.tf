variable "enabled" {
  description = "Whether to create Azure Key Vault."
  type        = bool
  default     = false
}

variable "name" {
  description = "Name of the Azure Key Vault. Must be globally unique."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for Key Vault."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name where Key Vault will be created."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "sku_name" {
  description = "SKU name for Key Vault."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "Key Vault sku_name must be either standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention days."
  type        = number
  default     = 7
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled for Key Vault."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for Key Vault."
  type        = map(string)
  default     = {}
}