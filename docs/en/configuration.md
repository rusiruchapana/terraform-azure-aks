# Configuration Guide

This guide explains how to configure this AKS Terraform platform for your own Azure subscription, naming standards, region, and learning environment.

Use this after reading the Quick Start guide.

## Environment folders

The repository includes three environment templates:

- dev
- qa
- prod

Folder structure:

    environments/
      dev/
      qa/
      prod/

Each environment has the same Terraform structure:

    main.tf
    variables.tf
    outputs.tf
    providers.tf
    backend.tf.example
    terraform.tfvars.example

## Files you should copy

Before running Terraform, copy the example files:

    cp backend.tf.example backend.tf
    cp terraform.tfvars.example terraform.tfvars

Why?

The example files are safe to commit.

The real files contain your local environment settings and should not be committed.

## Files you should not commit

Do not commit these files:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- terraform.tfstate.backup
- .terraform/

These files may contain local configuration, environment-specific values, or Terraform state data.

Use these files instead for the public repository:

- backend.tf.example
- terraform.tfvars.example

## Backend configuration

The backend file tells Terraform where to store remote state.

Example:

    terraform {
      backend "azurerm" {
        resource_group_name  = "replace-with-tfstate-resource-group"
        storage_account_name = "replacewithuniquetfstate"
        container_name       = "tfstate"
        key                  = "dev.terraform.tfstate"
        use_azuread_auth     = true
      }
    }

Values to change:

- resource_group_name: Resource group that contains the Terraform state storage account
- storage_account_name: Azure Storage Account name for Terraform state
- container_name: Blob container name
- key: State file name for this environment

Recommended state keys:

    dev.terraform.tfstate
    qa.terraform.tfstate
    prod.terraform.tfstate

Important:

The user or identity running Terraform needs blob data access.

Recommended role:

    Storage Blob Data Contributor

## terraform.tfvars

The terraform.tfvars file controls the environment configuration.

This is the main file most users will customize.

## Required common values

You should normally change these values for your own environment:

    resource_group_name
    location
    vnet_name
    aks_subnet_name
    nat_gateway_name
    nat_gateway_public_ip_name
    aks_identity_name
    aks_cluster_name
    aks_dns_prefix

Example:

    resource_group_name = "rg-aks-dev-001"
    location            = "southeastasia"

    vnet_name       = "vnet-aks-dev-001"
    aks_cluster_name = "aks-dev-001"

## Location

The location controls the Azure region.

Example:

    location = "southeastasia"

You can change it to another Azure region, for example:

    location = "australiaeast"

Important:

Not all VM sizes are available in every region.

Check VM SKU availability and vCPU quota before applying.

## Network settings

Network settings control the VNet and AKS subnet.

Example:

    vnet_address_space          = ["10.10.0.0/16"]
    aks_subnet_address_prefixes = ["10.10.1.0/24"]

If you create qa or prod environments, use different CIDR ranges.

Example:

    dev  = 10.10.0.0/16
    qa   = 10.20.0.0/16
    prod = 10.30.0.0/16

Do not overlap network ranges if environments may connect to each other later.

## NAT Gateway settings

NAT Gateway gives AKS nodes stable outbound internet access.

Example:

    enable_nat_gateway = true

For most learning and platform scenarios, keep this enabled.

## AKS settings

Main AKS settings:

    aks_cluster_name
    aks_dns_prefix
    aks_kubernetes_version
    aks_private_cluster_enabled
    aks_oidc_issuer_enabled
    aks_workload_identity_enabled

Recommended defaults:

    aks_kubernetes_version      = null
    aks_private_cluster_enabled = false
    aks_oidc_issuer_enabled       = true
    aks_workload_identity_enabled = true

What they mean:

- aks_kubernetes_version = null lets Azure choose the default supported version
- aks_private_cluster_enabled = false keeps the cluster easier to access for learning
- aks_oidc_issuer_enabled = true is required for Workload Identity
- aks_workload_identity_enabled = true enables secure pod identity integration

## Node pool settings

This platform uses two node pools:

- system node pool
- user node pool

System node pool:

    system_node_pool_name
    system_node_vm_size
    system_node_min_count
    system_node_max_count
    system_node_os_disk_size_gb
    system_node_only_critical_addons_enabled

User node pool:

    user_node_pool_name
    user_node_vm_size
    user_node_min_count
    user_node_max_count
    user_node_os_disk_size_gb
    user_node_labels

Recommended learning setup:

    system_node_min_count = 1
    user_node_min_count   = 1

For production-style environments, use larger VM sizes and higher node counts.

## System node pool critical add-ons

Recommended for new clusters:

    system_node_only_critical_addons_enabled = true

This helps keep user workloads away from the system node pool.

Important:

Changing this on an existing cluster can require node pool rotation and extra vCPU quota.

If you hit quota errors, check Known Issues.

## User node labels

User node labels help schedule application workloads onto user nodes.

Example:

    user_node_labels = {
      workload = "user"
      pool     = "user"
    }

Applications can use nodeSelector later:

    nodeSelector:
      workload: user

## ACR settings

ACR is optional.

Enable ACR:

    enable_acr = true

Disable ACR:

    enable_acr = false

Common ACR settings:

    acr_name
    acr_sku
    acr_admin_enabled

Important:

ACR name must be globally unique.

Recommended:

    acr_admin_enabled = false

If ACR is disabled, you can still use public Docker Hub, GHCR, Quay, or other public registry images.

Private external registries require imagePullSecret.

## Key Vault settings

Key Vault is optional.

Enable Key Vault:

    enable_keyvault = true

Disable Key Vault:

    enable_keyvault = false

Common settings:

    keyvault_name
    keyvault_sku_name
    keyvault_soft_delete_retention_days
    keyvault_purge_protection_enabled
    keyvault_public_network_access_enabled

Important:

Key Vault name must be globally unique.

For dev:

    keyvault_purge_protection_enabled = false

For production-style environments:

    keyvault_purge_protection_enabled = true

## Workload Identity settings

Recommended AKS settings:

    aks_oidc_issuer_enabled       = true
    aks_workload_identity_enabled = true

These enable the cluster to support Workload Identity.

App-specific workload identity resources are optional.

The current core platform keeps app-specific identity resources disabled by default:

    enable_workload_identity_keyvault_access = false

Why?

Because app-specific identities should be created per application or lab, not permanently in the core platform.

## Tags

Tags help identify Azure resources.

Example:

    tags = {
      environment = "dev"
      project     = "aks-platform"
      managed_by  = "terraform"
    }

Recommended environment values:

    dev
    qa
    prod

## Common customization examples

### Low-cost dev environment

Use small VM sizes and low node counts:

    system_node_vm_size = "Standard_B2s_v2"
    user_node_vm_size   = "Standard_B2s_v2"
    system_node_min_count = 1
    user_node_min_count   = 1

### Use a different region

Change:

    location = "australiaeast"

Also check VM size availability and quota.

### Disable ACR

    enable_acr = false

Use this if you want to pull from Docker Hub or another registry.

### Disable Key Vault

    enable_keyvault = false

Use this if you do not want to practice Key Vault or Workload Identity yet.

### Larger user node pool

    user_node_min_count = 2
    user_node_max_count = 5
    user_node_vm_size   = "Standard_D2s_v5"

## Recommended first-time setup

For first-time learners:

1. Start with environments/dev
2. Keep ACR enabled
3. Keep Key Vault enabled
4. Keep Workload Identity enabled
5. Use small VM sizes
6. Apply only dev first
7. Do not apply qa or prod until you understand the dev setup

## Final checklist before terraform apply

Check these before applying:

- Azure subscription is correct
- backend.tf points to your Terraform state storage
- terraform.tfvars names are unique
- ACR name is globally unique
- Key Vault name is globally unique
- Region supports your VM size
- Subscription has enough vCPU quota
- You reviewed terraform plan carefully
