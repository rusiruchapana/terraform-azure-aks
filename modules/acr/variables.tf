variable "enabled" {
  description = "Whether to create Azure Container Registry."
  type        = bool
  default     = false
}

variable "name" {
  description = "Name of the Azure Container Registry. Must be globally unique."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Resource Group name where ACR will be created."
  type        = string
}

variable "location" {
  description = "Azure region for ACR."
  type        = string
}

variable "sku" {
  description = "SKU for Azure Container Registry."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "ACR sku must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Whether to enable ACR admin user. Recommended false."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for ACR."
  type        = map(string)
  default     = {}
}