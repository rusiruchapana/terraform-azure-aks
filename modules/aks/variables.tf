variable "name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name where AKS will be created."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS. Set null to use Azure default."
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "Whether AKS private cluster is enabled."
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for the AKS default node pool."
  type        = string
}

variable "identity_ids" {
  description = "User Assigned Managed Identity IDs for the AKS cluster."
  type        = list(string)
}

variable "system_node_pool_name" {
  description = "Name of the AKS system node pool."
  type        = string
}

variable "system_node_vm_size" {
  description = "VM size for the system node pool."
  type        = string
}

variable "system_node_min_count" {
  description = "Minimum number of nodes for system node pool autoscaling."
  type        = number
}

variable "system_node_max_count" {
  description = "Maximum number of nodes for system node pool autoscaling."
  type        = number
}

variable "system_node_os_disk_size_gb" {
  description = "OS disk size in GB for system node pool nodes."
  type        = number
}

variable "network_plugin" {
  description = "Network plugin for AKS."
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy for AKS."
  type        = string
  default     = "azure"
}

variable "load_balancer_sku" {
  description = "Load balancer SKU for AKS."
  type        = string
  default     = "standard"
}

variable "tags" {
  description = "Tags for AKS resources."
  type        = map(string)
  default     = {}
}

variable "user_node_pool_name" {
  description = "Name of the AKS user node pool."
  type        = string
}

variable "user_node_vm_size" {
  description = "VM size for the user node pool."
  type        = string
}

variable "user_node_min_count" {
  description = "Minimum number of nodes for user node pool autoscaling."
  type        = number
}

variable "user_node_max_count" {
  description = "Maximum number of nodes for user node pool autoscaling."
  type        = number
}

variable "user_node_os_disk_size_gb" {
  description = "OS disk size in GB for user node pool nodes."
  type        = number
}

variable "user_node_labels" {
  description = "Labels for the user node pool."
  type        = map(string)
  default     = {}
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

variable "oidc_issuer_enabled" {
  description = "Whether to enable OIDC issuer for AKS."
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Whether to enable workload identity for AKS."
  type        = bool
  default     = true
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
