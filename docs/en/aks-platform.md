# AKS Platform

This document explains the AKS platform design used in this project.

## Purpose

The AKS cluster is the main Kubernetes platform for this DevOps practice environment.

It is designed to support:

- Application deployments
- CI/CD labs
- GitOps labs
- Gateway API routing
- Key Vault and Workload Identity
- Monitoring and observability
- dev / qa / prod environment practice

## AKS cluster

Terraform creates an Azure Kubernetes Service cluster.

Main AKS settings are controlled through terraform.tfvars:

    aks_cluster_name
    aks_dns_prefix
    aks_kubernetes_version
    aks_private_cluster_enabled
    aks_oidc_issuer_enabled
    aks_workload_identity_enabled

Recommended learning defaults:

    aks_kubernetes_version      = null
    aks_private_cluster_enabled = false
    aks_oidc_issuer_enabled       = true
    aks_workload_identity_enabled = true

## Kubernetes version

If this value is null:

    aks_kubernetes_version = null

Azure chooses a supported default Kubernetes version.

For learning environments, this is usually easier.

For production-style environments, you may pin a specific supported version.

## Public vs private cluster

This project uses a public AKS API server by default:

    aks_private_cluster_enabled = false

Why?

It is easier for learners to access the cluster from a local machine.

Production-style environments may use private clusters, but private clusters require extra networking setup.

## Node pool design

The platform uses two node pools:

- System node pool
- User node pool

## System node pool

The system node pool is intended for Kubernetes system components and platform components.

Examples:

- CoreDNS
- kube-proxy
- cluster system pods
- platform controllers

Common settings:

    system_node_pool_name
    system_node_vm_size
    system_node_min_count
    system_node_max_count
    system_node_os_disk_size_gb
    system_node_only_critical_addons_enabled

Recommended design for new clusters:

    system_node_only_critical_addons_enabled = true

This helps keep user application workloads away from the system node pool.

## Important quota note for system node pool changes

Changing some system node pool settings on an existing AKS cluster may require node pool rotation.

During rotation, Azure may create a temporary node pool.

That temporary node pool also consumes vCPU quota.

If regional quota is low, Azure may return:

    ErrCode_InsufficientVCPUQuota

This is an Azure quota issue, not a platform design issue.

Recommended options:

- Enable important system node pool settings from the beginning
- Request more vCPU quota
- Use another Azure region
- Use smaller VM sizes
- Recreate the learning cluster if needed

## User node pool

The user node pool is intended for application workloads.

Common settings:

    user_node_pool_name
    user_node_vm_size
    user_node_min_count
    user_node_max_count
    user_node_os_disk_size_gb
    user_node_labels

Applications should normally run on the user node pool.

## User node labels

This project labels the user node pool.

Example:

    user_node_labels = {
      workload = "user"
      pool     = "user"
    }

Applications can target user nodes with:

    nodeSelector:
      workload: user

This keeps application workloads separate from system workloads.

## Managed identity

The platform uses Azure managed identities instead of client secrets where possible.

Terraform creates or uses managed identities for AKS.

Important identities:

- AKS cluster identity
- AKS kubelet identity
- Optional app workload identities for labs

## AKS kubelet identity

The kubelet identity is used by AKS nodes for some Azure integrations.

For example, if ACR is enabled, the kubelet identity can be granted AcrPull permission.

## ACR pull permission

If ACR is enabled:

    enable_acr = true

Terraform creates:

- Azure Container Registry
- AcrPull role assignment for AKS

This allows AKS to pull images from ACR without imagePullSecret.

If ACR is disabled, applications can still use public registries such as Docker Hub or GHCR.

Private external registries need imagePullSecret.

## OIDC issuer

Workload Identity requires the AKS OIDC issuer.

Recommended:

    aks_oidc_issuer_enabled = true

Terraform outputs the OIDC issuer URL after apply.

Example output:

    aks_oidc_issuer_url

## Workload Identity

Workload Identity allows Kubernetes workloads to access Azure resources without storing secrets in pods.

Recommended:

    aks_workload_identity_enabled = true

High-level flow:

    Kubernetes ServiceAccount
              |
              v
    Federated identity credential
              |
              v
    Azure User Assigned Managed Identity
              |
              v
    Azure resource such as Key Vault

The core platform enables Workload Identity support.

App-specific identities should be created per application or lab.

## Why app-specific identity is not permanent in the core platform

During testing, a demo Key Vault reader identity may be created.

After testing, it should be removed.

Why?

Because the core platform should stay app-agnostic.

Each real application should define its own:

- Namespace
- ServiceAccount
- Managed identity
- Federated credential
- Azure RBAC role assignment

## Network integration

AKS is deployed into a dedicated subnet.

The subnet is part of the project VNet.

Outbound traffic uses NAT Gateway when enabled.

High-level flow:

    AKS node
        |
        v
    AKS subnet
        |
        v
    NAT Gateway
        |
        v
    Internet

## Verify AKS cluster

Check nodes:

    kubectl get nodes

Expected:

    STATUS   Ready

Check node details:

    kubectl get nodes -o wide

Check system pods:

    kubectl get pods -n kube-system

Check user node labels:

    kubectl get nodes --show-labels

## Verify AKS outputs

Terraform outputs useful AKS values after apply:

- aks_cluster_name
- aks_cluster_id
- aks_cluster_fqdn
- aks_identity_client_id
- aks_kubelet_identity_client_id
- aks_kubelet_identity_object_id
- aks_oidc_issuer_url
- user_node_pool_name

## Connect kubectl to AKS

Use Azure CLI:

    az aks get-credentials \
      --resource-group <resource-group-name> \
      --name <aks-cluster-name>

Then verify:

    kubectl get nodes

## Recommended learning setup

For first-time users:

- Use dev environment
- Use small VM sizes
- Use one system node
- Use one user node
- Keep Workload Identity enabled
- Keep ACR enabled if you want to practice private image pulls
- Keep Key Vault enabled if you want to practice secrets

## Production-style considerations

For production-style environments, consider:

- Private AKS cluster
- Larger node pools
- Multiple availability zones where supported
- Higher node counts
- Stronger monitoring and alerting
- Network policies
- Pod security standards
- Separate identity per application
- GitOps-managed add-ons
