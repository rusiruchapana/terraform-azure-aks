# Configuration Guide - settings වෙනස් කිරීම

මෙම guide එකෙන් මෙම AKS Terraform platform එක ඔයාගේ Azure subscription එකට, naming standard එකට, region එකට, සහ learning environment එකට ගැලපෙන විදියට configure කරන ආකාරය පැහැදිලි කරනවා.

Quick Start guide එකෙන් පස්සේ මේක කියවන්න.

## Environment folders

Repository එකේ environment templates තුනක් තියෙනවා:

- dev
- qa
- prod

Folder structure:

    environments/
      dev/
      qa/
      prod/

Each environment එකේ මේ Terraform files තියෙනවා:

    main.tf
    variables.tf
    outputs.tf
    providers.tf
    backend.tf.example
    terraform.tfvars.example

## Copy කරන්න ඕන files

Terraform run කරන්න කලින් example files copy කරන්න:

    cp backend.tf.example backend.tf
    cp terraform.tfvars.example terraform.tfvars

ඇයි?

Example files GitHub එකට commit කරන්න safe.

Real files local environment settings තියෙන නිසා commit කරන්න හොඳ නැහැ.

## Commit කරන්න එපා

මේ files commit කරන්න එපා:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- terraform.tfstate.backup
- .terraform/

මේ files වල local configuration, environment-specific values, හෝ Terraform state data තියෙන්න පුළුවන්.

Public repo එකට use කරන්න ඕන:

- backend.tf.example
- terraform.tfvars.example

## Backend configuration

Backend file එක Terraform state එක store කරන්නේ කොහෙද කියලා කියනවා.

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

Change කරන්න ඕන values:

- resource_group_name: Terraform state storage account තියෙන resource group එක
- storage_account_name: Terraform state සඳහා Azure Storage Account නම
- container_name: Blob container නම
- key: මේ environment එකේ state file නම

Recommended state keys:

    dev.terraform.tfstate
    qa.terraform.tfstate
    prod.terraform.tfstate

Important:

Terraform run කරන user හෝ identity එකට blob data access ඕන.

Recommended role:

    Storage Blob Data Contributor

## terraform.tfvars

terraform.tfvars file එක environment configuration control කරන main file එක.

බොහෝ usersලා වැඩිපුර customize කරන්නේ මේ file එක.

## Required common values

ඔයාගේ environment එකට normally වෙනස් කරන්න ඕන values:

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

    vnet_name        = "vnet-aks-dev-001"
    aks_cluster_name = "aks-dev-001"

## Location

location එක Azure region එක control කරනවා.

Example:

    location = "southeastasia"

වෙන region එකකට change කරන්න පුළුවන්:

    location = "australiaeast"

Important:

හැම VM size එකම හැම region එකකම available නැහැ.

Apply කරන්න කලින් VM SKU availability සහ vCPU quota check කරන්න.

## Network settings

Network settings වලින් VNet සහ AKS subnet control වෙනවා.

Example:

    vnet_address_space          = ["10.10.0.0/16"]
    aks_subnet_address_prefixes = ["10.10.1.0/24"]

qa හෝ prod environments හදනවා නම් වෙන CIDR ranges use කරන්න.

Example:

    dev  = 10.10.0.0/16
    qa   = 10.20.0.0/16
    prod = 10.30.0.0/16

Environments පස්සේ connect කරන්න ඉඩ තියෙනවා නම් network ranges overlap කරන්න එපා.

## NAT Gateway settings

NAT Gateway එක AKS nodes වල outbound internet access stable public IP එකකින් යන්න help කරනවා.

Example:

    enable_nat_gateway = true

Learning සහ platform scenarios සඳහා මේක enabled තියාගන්න හොඳයි.

## AKS settings

Main AKS settings:

    aks_cluster_name
    aks_dns_prefix
    aks_kubernetes_version
    aks_private_cluster_enabled
    aks_oidc_issuer_enabled
    aks_workload_identity_enabled

Recommended defaults:

    aks_kubernetes_version        = null
    aks_private_cluster_enabled   = false
    aks_oidc_issuer_enabled       = true
    aks_workload_identity_enabled = true

Meaning:

- aks_kubernetes_version = null නම් Azure default supported version එක choose කරනවා
- aks_private_cluster_enabled = false නම් learning වලට access පහසුයි
- aks_oidc_issuer_enabled = true Workload Identity සඳහා අවශ්‍යයි
- aks_workload_identity_enabled = true secure pod identity integration enable කරනවා

## Node pool settings

මෙම platform එක node pools දෙකක් use කරනවා:

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

Production-style environments වලට larger VM sizes සහ higher node counts use කරන්න.

## System node pool critical add-ons

New clusters සඳහා recommended:

    system_node_only_critical_addons_enabled = true

මේකෙන් user workloads system node pool එකෙන් separate කරලා තියාගන්න help වෙනවා.

Important:

Existing cluster එකක මේ setting එක change කරනකොට node pool rotation සහ extra vCPU quota අවශ්‍ය වෙන්න පුළුවන්.

Quota errors එනවා නම් Known Issues බලන්න.

## User node labels

User node labels වලින් application workloads user nodes වල schedule කරන්න පහසු වෙනවා.

Example:

    user_node_labels = {
      workload = "user"
      pool     = "user"
    }

Applications later nodeSelector use කරන්න පුළුවන්:

    nodeSelector:
      workload: user

## ACR settings

ACR optional.

ACR enable කරන්න:

    enable_acr = true

ACR disable කරන්න:

    enable_acr = false

Common ACR settings:

    acr_name
    acr_sku
    acr_admin_enabled

Important:

ACR name globally unique වෙන්න ඕන.

Recommended:

    acr_admin_enabled = false

ACR disable කළත් Docker Hub, GHCR, Quay වගේ public registry images use කරන්න පුළුවන්.

Private external registries සඳහා imagePullSecret ඕන.

## Key Vault settings

Key Vault optional.

Key Vault enable කරන්න:

    enable_keyvault = true

Key Vault disable කරන්න:

    enable_keyvault = false

Common settings:

    keyvault_name
    keyvault_sku_name
    keyvault_soft_delete_retention_days
    keyvault_purge_protection_enabled
    keyvault_public_network_access_enabled

Important:

Key Vault name globally unique වෙන්න ඕන.

Dev සඳහා:

    keyvault_purge_protection_enabled = false

Production-style environments සඳහා:

    keyvault_purge_protection_enabled = true

## Workload Identity settings

Recommended AKS settings:

    aks_oidc_issuer_enabled       = true
    aks_workload_identity_enabled = true

මේවා cluster එකට Workload Identity support enable කරනවා.

App-specific workload identity resources optional.

Current core platform එක app-specific identity resources default disable කරලා තියෙනවා:

    enable_workload_identity_keyvault_access = false

ඇයි?

App-specific identities application හෝ lab level එකේ create කරන එක clean design එකක්. Core platform එකේ permanent demo identity resources තියාගන්න හොඳ නැහැ.

## Tags

Tags වලින් Azure resources identify කරන්න පහසුයි.

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

Small VM sizes සහ low node counts use කරන්න:

    system_node_vm_size = "Standard_B2s_v2"
    user_node_vm_size   = "Standard_B2s_v2"
    system_node_min_count = 1
    user_node_min_count   = 1

### වෙන region එකක් use කිරීම

Change කරන්න:

    location = "australiaeast"

VM size availability සහ quota check කරන්න.

### ACR disable කිරීම

    enable_acr = false

Docker Hub හෝ වෙන registry එකක් use කරන්න ඕන නම්.

### Key Vault disable කිරීම

    enable_keyvault = false

Key Vault හෝ Workload Identity practice නොකරන්න ඕන නම්.

### Larger user node pool

    user_node_min_count = 2
    user_node_max_count = 5
    user_node_vm_size   = "Standard_D2s_v5"

## First-time learners සඳහා recommendation

First-time learners:

1. environments/dev වලින් පටන් ගන්න
2. ACR enabled තියාගන්න
3. Key Vault enabled තියාගන්න
4. Workload Identity enabled තියාගන්න
5. Small VM sizes use කරන්න
6. මුලින් dev විතරක් apply කරන්න
7. dev setup එක හොඳට තේරෙනකම් qa/prod apply කරන්න එපා

## terraform apply කලින් final checklist

Apply කරන්න කලින් මේවා check කරන්න:

- Azure subscription correct ද
- backend.tf Terraform state storage එකට point කරනවද
- terraform.tfvars names unique ද
- ACR name globally unique ද
- Key Vault name globally unique ද
- Region එක VM size එක support කරනවද
- Subscription එකේ vCPU quota enough ද
- terraform plan හොඳට review කළාද
