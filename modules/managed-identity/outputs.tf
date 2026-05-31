output "id" {
  description = "Managed Identity resource ID."
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "Managed Identity name."
  value       = azurerm_user_assigned_identity.this.name
}

output "principal_id" {
  description = "Managed Identity principal ID used for Azure RBAC role assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Managed Identity client ID used by AKS identity block."
  value       = azurerm_user_assigned_identity.this.client_id
}