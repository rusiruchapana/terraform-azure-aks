variable "resource_group_name" {
  description = "Resource Group for the Dev Environment"
  type        = string
}

variable "location" {
  description = "Azure Region for the Dev Environment"
  type        = string
}

variable "tags" {
  description = "Common Tags for the Dev Environment"
  type        = map(string)
  default     = {}
}

variable "vnet_name" {
  description = "Name of the dev virtual network."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the dev virtual network."
  type        = list(string)
}

variable "aks_subnet_name" {
  description = "Name of the AKS subnet."
  type        = string
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for the AKS subnet."
  type        = list(string)
}

variable "aks_identity_name" {
  description = "Name of the AKS User Assigned Managed Identity."
  type        = string
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "aks_dns_prefix" {
  description = "DNS prefix for the AKS cluster."
  type        = string
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS. Null means Azure default."
  type        = string
  default     = null
}

variable "aks_private_cluster_enabled" {
  description = "Whether AKS private cluster is enabled."
  type        = bool
  default     = false
}

variable "system_node_pool_name" {
  description = "Name of the AKS system node pool."
  type        = string
}

variable "system_node_vm_size" {
  description = "VM size for the AKS system node pool."
  type        = string
}

variable "system_node_min_count" {
  description = "Minimum system node count."
  type        = number
}

variable "system_node_max_count" {
  description = "Maximum system node count."
  type        = number
}

variable "system_node_os_disk_size_gb" {
  description = "OS disk size for system node pool."
  type        = number
}

variable "user_node_pool_name" {
  description = "Name of the AKS user node pool."
  type        = string
}

variable "user_node_vm_size" {
  description = "VM size for the AKS user node pool."
  type        = string
}

variable "user_node_min_count" {
  description = "Minimum node count for user node pool."
  type        = number
}

variable "user_node_max_count" {
  description = "Maximum node count for user node pool."
  type        = number
}

variable "user_node_os_disk_size_gb" {
  description = "OS disk size for user node pool."
  type        = number
}

variable "user_node_labels" {
  description = "Labels for the user node pool."
  type        = map(string)
  default     = {}
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway for AKS subnet outbound traffic."
  type        = bool
  default     = true
}

variable "nat_gateway_name" {
  description = "Name of the NAT Gateway."
  type        = string
}

variable "nat_gateway_public_ip_name" {
  description = "Name of the NAT Gateway Public IP."
  type        = string
}

variable "nat_gateway_idle_timeout_in_minutes" {
  description = "Idle timeout in minutes for NAT Gateway."
  type        = number
  default     = 4
}

variable "enable_acr" {
  description = "Whether to create Azure Container Registry."
  type        = bool
  default     = false
}

variable "acr_name" {
  description = "Name of Azure Container Registry. Must be globally unique."
  type        = string
  default     = null
}

variable "acr_sku" {
  description = "ACR SKU."
  type        = string
  default     = "Basic"
}

variable "acr_admin_enabled" {
  description = "Whether ACR admin user is enabled."
  type        = bool
  default     = false
}

variable "system_node_only_critical_addons_enabled" {
  description = "Whether only critical addons can be scheduled on the system node pool."
  type        = bool
  default     = true
}

variable "system_node_temporary_name_for_rotation" {
  description = "Temporary node pool name used by AKS when rotating the default system node pool."
  type        = string
  default     = "syspooltmp"
}

variable "enable_keyvault" {
  description = "Whether to create Azure Key Vault."
  type        = bool
  default     = false
}

variable "keyvault_name" {
  description = "Name of Azure Key Vault. Must be globally unique."
  type        = string
  default     = null
}

variable "keyvault_sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"
}

variable "keyvault_soft_delete_retention_days" {
  description = "Key Vault soft delete retention days."
  type        = number
  default     = 7
}

variable "keyvault_purge_protection_enabled" {
  description = "Whether Key Vault purge protection is enabled."
  type        = bool
  default     = false
}

variable "keyvault_public_network_access_enabled" {
  description = "Whether Key Vault public network access is enabled."
  type        = bool
  default     = true
}

variable "aks_oidc_issuer_enabled" {
  description = "Whether to enable AKS OIDC issuer."
  type        = bool
  default     = true
}

variable "aks_workload_identity_enabled" {
  description = "Whether to enable AKS workload identity."
  type        = bool
  default     = true
}

variable "enable_workload_identity_keyvault_access" {
  description = "Whether to create workload identity resources for Key Vault access."
  type        = bool
  default     = true
}

variable "app_workload_identity_name" {
  description = "Name of the app User Assigned Managed Identity for Workload Identity."
  type        = string
}

variable "app_workload_namespace" {
  description = "Kubernetes namespace where the workload ServiceAccount will exist."
  type        = string
  default     = "app-secrets-demo"
}

variable "app_workload_service_account_name" {
  description = "Kubernetes ServiceAccount name used by the workload."
  type        = string
  default     = "kv-reader-sa"
}

variable "app_federated_identity_credential_name" {
  description = "Name of the federated identity credential."
  type        = string
  default     = "fic-kv-reader"
}


variable "enable_apps_node_pool" {
  description = "Whether to create an additional apps workload node pool."
  type        = bool
  default     = false
}

variable "apps_node_pool_name" {
  description = "Name of the apps workload node pool."
  type        = string
  default     = "apps"
}

variable "apps_node_vm_size" {
  description = "VM size for the apps workload node pool."
  type        = string
  default     = "Standard_D2_v4"
}

variable "apps_node_min_count" {
  description = "Minimum number of nodes for apps node pool autoscaling."
  type        = number
  default     = 1
}

variable "apps_node_max_count" {
  description = "Maximum number of nodes for apps node pool autoscaling."
  type        = number
  default     = 2
}

variable "apps_node_os_disk_size_gb" {
  description = "OS disk size in GB for apps node pool nodes."
  type        = number
  default     = 128
}

variable "apps_node_labels" {
  description = "Labels for the apps workload node pool."
  type        = map(string)
  default     = {}
}
