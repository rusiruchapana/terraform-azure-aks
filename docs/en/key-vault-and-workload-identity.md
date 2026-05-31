# Key Vault and Workload Identity

This document explains how Azure Key Vault and AKS Workload Identity are used in this platform.

## Purpose

The goal is to let Kubernetes workloads access Azure resources securely without storing Azure credentials inside pods.

The recommended pattern is:

    Kubernetes Pod
        |
        v
    Kubernetes ServiceAccount
        |
        v
    AKS Workload Identity
        |
        v
    Azure User Assigned Managed Identity
        |
        v
    Azure Key Vault

## Key Vault is optional

Key Vault can be enabled or disabled from terraform.tfvars.

Enable Key Vault:

    enable_keyvault = true

Disable Key Vault:

    enable_keyvault = false

If enabled, Terraform creates an Azure Key Vault.

## Key Vault settings

Common variables:

    enable_keyvault
    keyvault_name
    keyvault_sku_name
    keyvault_soft_delete_retention_days
    keyvault_purge_protection_enabled
    keyvault_public_network_access_enabled

Example:

    enable_keyvault = true
    keyvault_name   = "replace-with-unique-kv-name"

Important:

Key Vault name must be globally unique.

## Key Vault RBAC mode

This project uses Key Vault RBAC mode.

That means access is controlled using Azure RBAC roles.

The project uses:

    rbac_authorization_enabled = true

In RBAC mode, Key Vault access policies are not used.

## Management plane vs data plane

Azure permissions have two important layers.

Management plane:

    Create, update, or delete Azure resources.

Data plane:

    Read or write data inside a resource.

For Key Vault:

- Creating the Key Vault is management-plane access
- Reading or writing secrets is data-plane access

Important:

A Subscription Owner or Contributor can create a Key Vault, but may not be able to create or read secrets unless data-plane RBAC roles are assigned.

## Important Key Vault roles

For human/operator users who create or update secrets:

    Key Vault Secrets Officer

For applications that only read secrets:

    Key Vault Secrets User

Recommended pattern:

- Human/operator account gets Key Vault Secrets Officer
- Application workload identity gets Key Vault Secrets User

## Why Workload Identity?

Do not store Azure client secrets inside Kubernetes pods.

Instead, use AKS Workload Identity.

Benefits:

- No client secrets in Kubernetes secrets
- Identity is tied to a Kubernetes ServiceAccount
- Azure RBAC controls what the app can access
- Works well with Key Vault
- Cleaner and more secure app identity model

## AKS OIDC issuer

AKS Workload Identity requires the AKS OIDC issuer.

Recommended setting:

    aks_oidc_issuer_enabled = true

Terraform output:

    aks_oidc_issuer_url

This URL is used by Azure to trust tokens from the AKS cluster.

## Enable Workload Identity on AKS

Recommended setting:

    aks_workload_identity_enabled = true

This enables the cluster to use Workload Identity.

## High-level Workload Identity flow

    Pod
     |
     v
    ServiceAccount
     |
     v
    Projected federated token
     |
     v
    Azure federated identity credential
     |
     v
    User Assigned Managed Identity
     |
     v
    Key Vault RBAC

## ServiceAccount subject format

The federated identity credential subject must match the Kubernetes ServiceAccount.

Format:

    system:serviceaccount:<namespace>:<service-account-name>

Example:

    system:serviceaccount:app-secrets-demo:kv-reader-sa

If namespace or ServiceAccount name does not match, login will fail.

## ServiceAccount annotation

A ServiceAccount must be annotated with the managed identity client ID.

Example:

    azure.workload.identity/client-id: "<managed-identity-client-id>"

## Pod label

The pod must include this label:

    azure.workload.identity/use: "true"

Without this label, the Workload Identity webhook may not inject the required environment variables and token file.

## Expected injected environment variables

Inside a correctly configured pod, these variables should exist:

    AZURE_CLIENT_ID
    AZURE_TENANT_ID
    AZURE_FEDERATED_TOKEN_FILE

The token file usually points to:

    /var/run/secrets/azure/tokens/azure-identity-token

## Federated token login pattern

Inside the pod, use federated token login:

    az login \
      --service-principal \
      --username "$AZURE_CLIENT_ID" \
      --tenant "$AZURE_TENANT_ID" \
      --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"

Do not use this for AKS Workload Identity:

    az login --identity

That command is for managed identity endpoint login, not federated token login.

## Key Vault secret test

Create a secret in Key Vault as an operator.

The operator needs:

    Key Vault Secrets Officer

Example:

    az keyvault secret set \
      --vault-name <keyvault-name> \
      --name demo-message \
      --value "hello-from-keyvault"

Then a workload identity with Key Vault Secrets User can read it.

Example:

    az keyvault secret show \
      --vault-name <keyvault-name> \
      --name demo-message \
      --query value -o tsv

## Common error: ForbiddenByRbac

Error:

    ForbiddenByRbac
    Caller is not authorized to perform action

Why it happens:

The caller does not have the correct Key Vault data-plane role.

Fix:

For setting secrets, assign:

    Key Vault Secrets Officer

For reading secrets, assign:

    Key Vault Secrets User

Role assignment propagation can take a few minutes.

## Common error: Identity not found

Error:

    ERROR: Identity not found
    Please run az login

Common cause:

Using this command inside a Workload Identity pod:

    az login --identity

Fix:

Use federated token login:

    az login \
      --service-principal \
      --username "$AZURE_CLIENT_ID" \
      --tenant "$AZURE_TENANT_ID" \
      --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"

## Common error: environment variables missing

If AZURE_CLIENT_ID, AZURE_TENANT_ID, or AZURE_FEDERATED_TOKEN_FILE are missing, check:

- Pod has azure.workload.identity/use: "true" label
- ServiceAccount annotation is correct
- Pod uses the correct ServiceAccount
- Workload Identity is enabled on AKS
- Azure Workload Identity webhook is running

## Cleanup guidance

Demo workload identity resources can be removed after testing.

Safe to delete:

- Demo test pod
- Demo namespace
- Demo ServiceAccount
- Demo federated credential
- Demo app managed identity
- Demo role assignment

Do not delete core AKS OIDC or Workload Identity settings unless you want to disable Workload Identity support for the cluster.

## Why demo identity is not kept permanently

This platform is app-agnostic.

A real application should define its own:

- Namespace
- ServiceAccount
- Managed identity
- Federated identity credential
- Key Vault role assignment

Keeping demo identities permanently in the core platform can create leftover resources and confusion.

## Recommended learning path

Beginner:

1. Understand Key Vault RBAC
2. Create a secret manually
3. Read the secret with Azure CLI

Practitioner:

1. Create a ServiceAccount
2. Create a managed identity
3. Create a federated credential
4. Assign Key Vault Secrets User
5. Read a secret from a pod

Professional:

1. Create one identity per application
2. Use least privilege RBAC
3. Manage identity resources through Terraform or GitOps
4. Rotate and audit access regularly
5. Add secret access monitoring
