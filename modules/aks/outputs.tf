output "id" {
  description = "AKS cluster ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "fqdn" {
  description = "AKS cluster FQDN."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "user_node_pool_id" {
  description = "User node pool ID."
  value       = azurerm_kubernetes_cluster_node_pool.user.id
}

output "user_node_pool_name" {
  description = "User node pool name."
  value       = azurerm_kubernetes_cluster_node_pool.user.name
}

output "kubelet_identity_object_id" {
  description = "AKS kubelet identity object ID used for AcrPull role assignment."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "AKS kubelet identity client ID."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id
}

output "oidc_issuer_url" {
  description = "AKS OIDC issuer URL."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}