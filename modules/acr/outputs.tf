output "id" {
  description = "ACR ID."
  value       = var.enabled ? azurerm_container_registry.this[0].id : null
}

output "name" {
  description = "ACR name."
  value       = var.enabled ? azurerm_container_registry.this[0].name : null
}

output "login_server" {
  description = "ACR login server."
  value       = var.enabled ? azurerm_container_registry.this[0].login_server : null
}