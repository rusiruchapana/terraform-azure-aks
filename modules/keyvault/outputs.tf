output "id" {
  description = "Key Vault ID."
  value       = var.enabled ? azurerm_key_vault.this[0].id : null
}

output "name" {
  description = "Key Vault name."
  value       = var.enabled ? azurerm_key_vault.this[0].name : null
}

output "vault_uri" {
  description = "Key Vault URI."
  value       = var.enabled ? azurerm_key_vault.this[0].vault_uri : null
}