# AKS Platform

මෙම document එකෙන් මෙම project එකේ AKS platform design එක පැහැදිලි කරනවා.

## Purpose

AKS cluster එක මෙම DevOps practice environment එකේ main Kubernetes platform එක.

මෙම platform එක support කරන දේවල්:

- Application deployments
- CI/CD labs
- GitOps labs
- Gateway API routing
- Key Vault සහ Workload Identity
- Monitoring සහ observability
- dev / qa / prod environment practice

## AKS cluster

Terraform මගින් Azure Kubernetes Service cluster එක create කරනවා.

Main AKS settings terraform.tfvars file එකෙන් control වෙනවා:

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

මේ value එක null නම්:

    aks_kubernetes_version = null

Azure supported default Kubernetes version එකක් choose කරනවා.

Learning environments වලට මේක පහසුයි.

Production-style environments වලදී specific supported version එකක් pin කරන්න පුළුවන්.

## Public vs private cluster

මෙම project එක default විදියට public AKS API server එකක් use කරනවා:

    aks_private_cluster_enabled = false

ඇයි?

Learnersලාට local machine එකෙන් cluster access කරන්න පහසු නිසා.

Production-style environments private cluster use කරන්න පුළුවන්, හැබැයි private cluster වලට extra networking setup ඕන.

## Node pool design

Platform එක node pools දෙකක් use කරනවා:

- System node pool
- User node pool

## System node pool

System node pool එක Kubernetes system components සහ platform components සඳහා.

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

New clusters සඳහා recommended design:

    system_node_only_critical_addons_enabled = true

මේකෙන් user application workloads system node pool එකෙන් separate කරලා තියාගන්න help වෙනවා.

## System node pool changes වල quota note එක

Existing AKS cluster එකක සමහර system node pool settings change කරනකොට node pool rotation අවශ්‍ය වෙන්න පුළුවන්.

Rotation එකේදී Azure temporary node pool එකක් create කරන්න පුළුවන්.

ඒ temporary node pool එකටත් vCPU quota ඕන.

Regional quota අඩු නම් Azure මෙහෙම error දෙන්න පුළුවන්:

    ErrCode_InsufficientVCPUQuota

මේක Azure quota issue එකක්. Platform design issue එකක් නෙවෙයි.

Recommended options:

- Important system node pool settings new cluster එකේ මුලින්ම enable කරන්න
- vCPU quota increase request කරන්න
- වෙන Azure region එකක් use කරන්න
- Smaller VM sizes use කරන්න
- Learning cluster එකක් නම් recreate කරන්න

## User node pool

User node pool එක application workloads සඳහා.

Common settings:

    user_node_pool_name
    user_node_vm_size
    user_node_min_count
    user_node_max_count
    user_node_os_disk_size_gb
    user_node_labels

Applications සාමාන්‍යයෙන් user node pool එකේ run වෙන්න ඕන.

## User node labels

මෙම project එක user node pool එකට labels දානවා.

Example:

    user_node_labels = {
      workload = "user"
      pool     = "user"
    }

Applications user nodes target කරන්න මෙහෙම use කරන්න පුළුවන්:

    nodeSelector:
      workload: user

මේකෙන් application workloads සහ system workloads separate කරගන්න පුළුවන්.

## Managed identity

Platform එක හැකි තරම් client secrets වෙනුවට Azure managed identities use කරනවා.

Terraform AKS සඳහා managed identities create/use කරනවා.

Important identities:

- AKS cluster identity
- AKS kubelet identity
- Optional app workload identities for labs

## AKS kubelet identity

kubelet identity එක AKS nodes වලට සමහර Azure integrations සඳහා use වෙනවා.

Example එකක් ලෙස ACR enabled නම් kubelet identity එකට AcrPull permission දෙන්න පුළුවන්.

## ACR pull permission

ACR enabled නම්:

    enable_acr = true

Terraform create කරනවා:

- Azure Container Registry
- AKS සඳහා AcrPull role assignment

මේකෙන් AKS ට imagePullSecret නැතුව ACR images pull කරන්න පුළුවන්.

ACR disabled නම් Docker Hub හෝ GHCR වගේ public registries තවම use කරන්න පුළුවන්.

Private external registries සඳහා imagePullSecret ඕන.

## OIDC issuer

Workload Identity සඳහා AKS OIDC issuer අවශ්‍යයි.

Recommended:

    aks_oidc_issuer_enabled = true

Terraform apply එකෙන් පස්සේ OIDC issuer URL output එකක් ලෙස ලැබෙනවා.

Example output:

    aks_oidc_issuer_url

## Workload Identity

Workload Identity මගින් Kubernetes workloads වලට pod එක තුළ secrets store නොකර Azure resources access කරන්න පුළුවන්.

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

Core platform එක Workload Identity support enable කරනවා.

App-specific identities application හෝ lab level එකෙන් create කරන්න ඕන.

## App-specific identity core platform එකේ permanent නැත්තේ ඇයි?

Testing වලදී demo Key Vault reader identity එකක් create කරන්න පුළුවන්.

Testing පස්සේ ඒක remove කරන්න හොඳයි.

ඇයි?

Core platform එක app-agnostic තියාගන්න ඕන නිසා.

Real application එකක් තමන්ගේම මේ resources define කරන්න ඕන:

- Namespace
- ServiceAccount
- Managed identity
- Federated credential
- Azure RBAC role assignment

## Network integration

AKS dedicated subnet එකකට deploy වෙනවා.

Subnet එක project VNet එකේ කොටසක්.

Outbound traffic NAT Gateway හරහා යනවා, enable කරලා තිබ්බොත්.

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

## AKS cluster verify කිරීම

Nodes check කරන්න:

    kubectl get nodes

Expected:

    STATUS   Ready

Node details check කරන්න:

    kubectl get nodes -o wide

System pods check කරන්න:

    kubectl get pods -n kube-system

User node labels check කරන්න:

    kubectl get nodes --show-labels

## AKS outputs verify කිරීම

Terraform apply එකෙන් පස්සේ useful AKS values outputs විදියට ලැබෙනවා:

- aks_cluster_name
- aks_cluster_id
- aks_cluster_fqdn
- aks_identity_client_id
- aks_kubelet_identity_client_id
- aks_kubelet_identity_object_id
- aks_oidc_issuer_url
- user_node_pool_name

## kubectl AKS එකට connect කිරීම

Azure CLI use කරන්න:

    az aks get-credentials \
      --resource-group <resource-group-name> \
      --name <aks-cluster-name>

ඊට පස්සේ verify කරන්න:

    kubectl get nodes

## Recommended learning setup

First-time users සඳහා:

- dev environment use කරන්න
- Small VM sizes use කරන්න
- One system node use කරන්න
- One user node use කරන්න
- Workload Identity enabled තියාගන්න
- Private image pulls practice කරන්න ඕන නම් ACR enabled තියාගන්න
- Secrets practice කරන්න ඕන නම් Key Vault enabled තියාගන්න

## Production-style considerations

Production-style environments සඳහා consider කරන්න:

- Private AKS cluster
- Larger node pools
- Supported නම් multiple availability zones
- Higher node counts
- Stronger monitoring and alerting
- Network policies
- Pod security standards
- Application එකකට වෙනම identity
- GitOps-managed add-ons
