output "resource_group_name" {
  description = "Terraform state Resource Group name."
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Terraform state Storage Account name."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Terraform state container name."
  value       = azurerm_storage_container.tfstate.name
}