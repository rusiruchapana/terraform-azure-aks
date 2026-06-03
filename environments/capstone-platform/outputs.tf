output "resource_group_name" {
  description = "Created Resource Group"
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "CReated Resource Group Location"
  value       = module.resource_group.location
}

output "resource_group_id" {
  description = "Created Resource Group ID"
  value       = module.resource_group.id

}

output "vnet_name" {
  description = "Created VNet name."
  value       = module.network.vnet_name
}

output "vnet_id" {
  description = "Created VNet ID."
  value       = module.network.vnet_id
}

output "aks_subnet_id" {
  description = "Created AKS subnet ID."
  value       = module.network.aks_subnet_id
}

output "aks_identity_id" {
  description = "AKS Managed Identity resource ID."
  value       = module.aks_identity.id
}

output "aks_identity_principal_id" {
  description = "AKS Managed Identity principal ID."
  value       = module.aks_identity.principal_id
}

output "aks_identity_client_id" {
  description = "AKS Managed Identity client ID."
  value       = module.aks_identity.client_id
}

output "aks_network_contributor_role_assignment_id" {
  description = "AKS identity Network Contributor role assignment ID."
  value       = module.aks_network_contributor_role.id
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = module.aks.name
}

output "aks_cluster_id" {
  description = "AKS cluster ID."
  value       = module.aks.id
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN."
  value       = module.aks.fqdn
}

output "user_node_pool_id" {
  description = "AKS user node pool ID."
  value       = module.aks.user_node_pool_id
}

output "user_node_pool_name" {
  description = "AKS user node pool name."
  value       = module.aks.user_node_pool_name
}

output "nat_gateway_id" {
  description = "NAT Gateway ID."
  value       = module.network.nat_gateway_id
}

output "nat_gateway_public_ip_address" {
  description = "NAT Gateway outbound public IP address."
  value       = module.network.nat_gateway_public_ip_address
}

output "acr_id" {
  description = "ACR ID."
  value       = module.acr.id
}

output "acr_name" {
  description = "ACR name."
  value       = module.acr.name
}

output "acr_login_server" {
  description = "ACR login server."
  value       = module.acr.login_server
}

output "aks_kubelet_identity_object_id" {
  description = "AKS kubelet identity object ID."
  value       = module.aks.kubelet_identity_object_id
}

output "aks_kubelet_identity_client_id" {
  description = "AKS kubelet identity client ID."
  value       = module.aks.kubelet_identity_client_id
}

output "aks_acr_pull_role_assignment_id" {
  description = "AcrPull role assignment ID for AKS kubelet identity."
  value       = var.enable_acr ? module.aks_acr_pull_role[0].id : null
}

output "keyvault_id" {
  description = "Key Vault ID."
  value       = module.keyvault.id
}

output "keyvault_name" {
  description = "Key Vault name."
  value       = module.keyvault.name
}

output "keyvault_uri" {
  description = "Key Vault URI."
  value       = module.keyvault.vault_uri
}

output "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL."
  value       = module.aks.oidc_issuer_url
}

output "app_workload_identity_id" {
  description = "App workload identity resource ID."
  value       = var.enable_workload_identity_keyvault_access ? module.app_workload_identity[0].id : null
}

output "app_workload_identity_client_id" {
  description = "App workload identity client ID."
  value       = var.enable_workload_identity_keyvault_access ? module.app_workload_identity[0].client_id : null
}

output "app_workload_identity_principal_id" {
  description = "App workload identity principal ID."
  value       = var.enable_workload_identity_keyvault_access ? module.app_workload_identity[0].principal_id : null
}

output "app_keyvault_secrets_user_role_assignment_id" {
  description = "Key Vault Secrets User role assignment ID for app workload identity."
  value       = var.enable_workload_identity_keyvault_access && var.enable_keyvault ? module.app_keyvault_secrets_user_role[0].id : null
}

output "app_federated_identity_credential_id" {
  description = "Federated identity credential ID for app workload identity."
  value       = var.enable_workload_identity_keyvault_access ? azurerm_federated_identity_credential.app_keyvault[0].id : null
}

