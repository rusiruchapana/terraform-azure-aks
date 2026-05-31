# Prerequisites

This page lists the tools, Azure permissions, and preparation needed before using this AKS DevOps Practice Platform.

## Required tools

Install these tools on your local machine:

- Git
- Azure CLI
- Terraform
- kubectl
- Helm

## Recommended tool versions

Use recent stable versions of each tool.

Check your installed versions:

    git --version
    az version
    terraform version
    kubectl version --client
    helm version

## Azure CLI login

Login to Azure:

    az login

Check the active account and subscription:

    az account show

If needed, set the correct subscription:

    az account set --subscription "<subscription-id>"

## Azure subscription

You need access to an Azure subscription where you can create resources such as:

- Resource groups
- Virtual networks
- Public IP addresses
- NAT Gateways
- AKS clusters
- Managed identities
- Role assignments
- Azure Container Registry
- Azure Key Vault
- Storage account for Terraform state

## Azure permissions

The user or identity running Terraform needs enough permission to create and manage Azure resources.

For learning environments, Subscription Owner is the simplest option.

However, some services also need data-plane permissions.

## Terraform backend permissions

Terraform remote state is stored in Azure Storage.

For blob state access, the user or identity running Terraform needs:

    Storage Blob Data Contributor

This is different from normal Azure resource management permissions.

## Key Vault permissions

This project uses Key Vault RBAC mode.

For creating or updating secrets, the human/operator account needs:

    Key Vault Secrets Officer

For application read access, the workload identity needs:

    Key Vault Secrets User

Important:

Subscription Owner or Contributor does not automatically mean Key Vault secret read/write access.

## AKS quota requirements

AKS node pools require regional vCPU quota.

Before applying Terraform, check that your subscription has enough vCPU quota in the selected Azure region.

Quota is especially important when:

- Creating AKS node pools
- Scaling node pools
- Rotating the system node pool
- Using temporary node pools during updates

If quota is low, Azure may return:

    ErrCode_InsufficientVCPUQuota

Fix options:

- Request quota increase
- Use another Azure region
- Use smaller VM sizes
- Reduce node count

## VM SKU availability

Not every VM size is available in every Azure region or subscription.

If a VM size is not available, choose another size.

Example low-cost option used in this project:

    Standard_B2s_v2

## Naming requirements

Some Azure resource names must be globally unique.

Examples:

- Azure Container Registry name
- Azure Key Vault name
- Storage account name

Use your own unique names in terraform.tfvars.

## Local files

You will create local files from examples:

    backend.tf.example      -> backend.tf
    terraform.tfvars.example -> terraform.tfvars

Do not commit these real local files:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- terraform.tfstate.backup
- .terraform/

## Kubernetes access

After the AKS cluster is created, configure kubectl:

    az aks get-credentials \
      --resource-group <resource-group-name> \
      --name <aks-cluster-name>

Verify:

    kubectl get nodes

## Helm access

Helm is used to install platform add-ons such as:

- NGINX Gateway Fabric
- kube-prometheus-stack
- OpenTelemetry Collector

Check Helm:

    helm version

## Recommended starting environment

For first-time users, start with:

    environments/dev

Do not apply qa or prod until you understand the dev setup.

## Cost warning

AKS, NAT Gateway, public IPs, ACR, Key Vault, and monitoring components may create Azure costs.

For learning:

- Use small VM sizes
- Use low node counts
- Destroy the environment when not needed
- Review Azure costs regularly

## Before you continue

Before running terraform apply, make sure:

- You are logged into the correct Azure subscription
- Terraform backend storage exists
- You have Storage Blob Data Contributor for Terraform state
- terraform.tfvars has unique resource names
- The region supports your selected VM sizes
- Your subscription has enough vCPU quota
