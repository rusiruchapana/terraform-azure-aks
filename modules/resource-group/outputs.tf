output "name" {
  description = "Resource Group Name"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Resource Group Location"
  value       = azurerm_resource_group.this.location
}

output "id" {
  description = "Resource Group ID"
  value       = azurerm_resource_group.this.id
}