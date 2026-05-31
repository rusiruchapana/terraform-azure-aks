output "vnet_id" {
  description = "Virtual Network ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual Network name."
  value       = azurerm_virtual_network.this.name
}

output "aks_subnet_id" {
  description = "AKS subnet ID."
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "AKS subnet name."
  value       = azurerm_subnet.aks.name
}

output "nat_gateway_id" {
  description = "NAT Gateway ID."
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.this[0].id : null
}

output "nat_gateway_public_ip_id" {
  description = "NAT Gateway Public IP ID."
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat[0].id : null
}

output "nat_gateway_public_ip_address" {
  description = "NAT Gateway outbound public IP address."
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}