module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "../../modules/network"

  name                = var.vnet_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name

  address_space               = var.vnet_address_space
  aks_subnet_name             = var.aks_subnet_name
  aks_subnet_address_prefixes = var.aks_subnet_address_prefixes

  enable_nat_gateway                  = var.enable_nat_gateway
  nat_gateway_name                    = var.nat_gateway_name
  nat_gateway_public_ip_name          = var.nat_gateway_public_ip_name
  nat_gateway_idle_timeout_in_minutes = var.nat_gateway_idle_timeout_in_minutes

  tags = var.tags
}

module "aks_identity" {
  source = "../../modules/managed-identity"

  name                = var.aks_identity_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name

  tags = var.tags
}

module "aks_network_contributor_role" {
  source = "../../modules/role-assignments"

  principal_id         = module.aks_identity.principal_id
  scope                = module.network.vnet_id
  role_definition_name = "Network Contributor"
}

module "aks" {
  source = "../../modules/aks"

  name                = var.aks_cluster_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  dns_prefix          = var.aks_dns_prefix

  kubernetes_version      = var.aks_kubernetes_version
  private_cluster_enabled = var.aks_private_cluster_enabled

  subnet_id    = module.network.aks_subnet_id
  identity_ids = [module.aks_identity.id]

  system_node_pool_name                    = var.system_node_pool_name
  system_node_vm_size                      = var.system_node_vm_size
  system_node_min_count                    = var.system_node_min_count
  system_node_max_count                    = var.system_node_max_count
  system_node_os_disk_size_gb              = var.system_node_os_disk_size_gb
  system_node_only_critical_addons_enabled = var.system_node_only_critical_addons_enabled
  system_node_temporary_name_for_rotation  = var.system_node_temporary_name_for_rotation

  user_node_pool_name       = var.user_node_pool_name
  user_node_vm_size         = var.user_node_vm_size
  user_node_min_count       = var.user_node_min_count
  user_node_max_count       = var.user_node_max_count
  user_node_os_disk_size_gb = var.user_node_os_disk_size_gb
  user_node_labels          = var.user_node_labels

  enable_apps_node_pool     = var.enable_apps_node_pool
  apps_node_pool_name       = var.apps_node_pool_name
  apps_node_vm_size         = var.apps_node_vm_size
  apps_node_min_count       = var.apps_node_min_count
  apps_node_max_count       = var.apps_node_max_count
  apps_node_os_disk_size_gb = var.apps_node_os_disk_size_gb
  apps_node_labels          = var.apps_node_labels

  oidc_issuer_enabled       = var.aks_oidc_issuer_enabled
  workload_identity_enabled = var.aks_workload_identity_enabled

  tags = var.tags

  depends_on = [
    module.aks_network_contributor_role
  ]
}

module "acr" {
  source = "../../modules/acr"

  enabled             = var.enable_acr
  name                = var.acr_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled

  tags = var.tags
}

module "aks_acr_pull_role" {
  count  = var.enable_acr ? 1 : 0
  source = "../../modules/role-assignments"

  principal_id         = module.aks.kubelet_identity_object_id
  scope                = module.acr.id
  role_definition_name = "AcrPull"

  depends_on = [
    module.aks,
    module.acr
  ]
}

module "keyvault" {
  source = "../../modules/keyvault"

  enabled             = var.enable_keyvault
  name                = var.keyvault_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                      = var.keyvault_sku_name
  soft_delete_retention_days    = var.keyvault_soft_delete_retention_days
  purge_protection_enabled      = var.keyvault_purge_protection_enabled
  public_network_access_enabled = var.keyvault_public_network_access_enabled

  tags = var.tags
}

module "app_workload_identity" {
  count  = var.enable_workload_identity_keyvault_access ? 1 : 0
  source = "../../modules/managed-identity"

  name                = var.app_workload_identity_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name

  tags = var.tags
}

module "app_keyvault_secrets_user_role" {
  count  = var.enable_workload_identity_keyvault_access && var.enable_keyvault ? 1 : 0
  source = "../../modules/role-assignments"

  principal_id         = module.app_workload_identity[0].principal_id
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets User"
}

resource "azurerm_federated_identity_credential" "app_keyvault" {
  count = var.enable_workload_identity_keyvault_access ? 1 : 0

  name                = var.app_federated_identity_credential_name
  resource_group_name = module.resource_group.name
  parent_id           = module.app_workload_identity[0].id

  audience = ["api://AzureADTokenExchange"]
  issuer   = module.aks.oidc_issuer_url
  subject  = "system:serviceaccount:${var.app_workload_namespace}:${var.app_workload_service_account_name}"

  depends_on = [
    module.aks,
    module.app_workload_identity
  ]
}