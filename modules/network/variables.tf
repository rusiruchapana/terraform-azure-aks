variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "aks_subnet_name" {
  type = string
}

variable "aks_subnet_address_prefixes" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_nat_gateway" {
  description = "Whether to create and associate a NAT Gateway with the AKS subnet."
  type        = bool
  default     = false
}

variable "nat_gateway_name" {
  description = "Name of the NAT Gateway."
  type        = string
  default     = null
}

variable "nat_gateway_public_ip_name" {
  description = "Name of the NAT Gateway Public IP."
  type        = string
  default     = null
}

variable "nat_gateway_idle_timeout_in_minutes" {
  description = "Idle timeout in minutes for NAT Gateway."
  type        = number
  default     = 4
}