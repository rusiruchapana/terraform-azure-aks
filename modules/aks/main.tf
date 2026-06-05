resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.private_cluster_enabled

  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.workload_identity_enabled

  role_based_access_control_enabled = true

  identity {
    type         = "UserAssigned"
    identity_ids = var.identity_ids
  }

  default_node_pool {
    name                         = var.system_node_pool_name
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = var.subnet_id
    os_disk_size_gb              = var.system_node_os_disk_size_gb
    auto_scaling_enabled         = true
    min_count                    = var.system_node_min_count
    max_count                    = var.system_node_max_count
    only_critical_addons_enabled = var.system_node_only_critical_addons_enabled
    temporary_name_for_rotation  = var.system_node_temporary_name_for_rotation
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    load_balancer_sku = var.load_balancer_sku
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].upgrade_settings
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = var.user_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_vm_size
  mode                  = "User"

  vnet_subnet_id  = var.subnet_id
  os_disk_size_gb = var.user_node_os_disk_size_gb

  auto_scaling_enabled = true
  min_count            = var.user_node_min_count
  max_count            = var.user_node_max_count

  node_labels = var.user_node_labels

  upgrade_settings {
    max_surge = "10%"
  }

  tags = var.tags
}
resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  count = var.enable_apps_node_pool ? 1 : 0

  name                  = var.apps_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.apps_node_vm_size
  mode                  = "User"

  vnet_subnet_id  = var.subnet_id
  os_disk_size_gb = var.apps_node_os_disk_size_gb

  auto_scaling_enabled = true
  min_count            = var.apps_node_min_count
  max_count            = var.apps_node_max_count

  node_labels = var.apps_node_labels

  upgrade_settings {
    max_surge = "10%"
  }

  tags = var.tags
}
