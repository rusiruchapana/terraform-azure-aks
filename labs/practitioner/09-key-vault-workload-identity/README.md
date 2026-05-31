# Practitioner Lab 09 - Key Vault and Workload Identity

This lab shows how to use AKS Workload Identity to let a pod read a secret from Azure Key Vault.

The pod does not store the secret as a raw Kubernetes Secret. Instead, it uses:

- Azure Key Vault
- AKS Workload Identity
- User-assigned managed identity
- Federated identity credential
- Secrets Store CSI Driver
- Azure Key Vault provider for Secrets Store CSI Driver

## What you will learn

You will learn:

- How AKS Workload Identity works
- How to enable and verify the Key Vault Secrets Provider addon
- How to create a Key Vault secret
- How to create a user-assigned managed identity
- How to map a Kubernetes ServiceAccount to an Azure managed identity
- How to use a federated identity credential
- How to mount a Key Vault secret into a pod
- How to clean up Azure and Kubernetes resources after testing

## Architecture

The flow is:

    Pod
      |
      v
    Kubernetes ServiceAccount
      |
      v
    AKS Workload Identity
      |
      v
    User-assigned managed identity
      |
      v
    Azure Key Vault
      |
      v
    Mounted secret file

The secret is mounted into the pod at:

    /mnt/secrets-store/demo-message

## What this lab requires

You need:

- Azure CLI
- kubectl
- Existing AKS cluster
- AKS OIDC issuer enabled
- AKS Workload Identity enabled
- Azure Key Vault Secrets Provider addon enabled
- Permission to create Azure managed identities
- Permission to create or update Azure Key Vault secrets
- Permission to create Azure role assignments

Check Azure and Kubernetes access:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl get nodes

## Lab files

This lab includes:

    manifests/
      Kubernetes manifests with placeholders

    scripts/
      Helper script to render manifests with real Azure values

Files:

    manifests/namespace.yaml
    manifests/serviceaccount.yaml
    manifests/secretproviderclass.yaml
    manifests/pod.yaml
    scripts/render-manifests.sh

## Set lab variables

Set these values for your environment:

    RESOURCE_GROUP="rg-aks-dev-001"
    AKS_NAME="aks-dev-001"
    LOCATION="southeastasia"
    NAMESPACE="practitioner-keyvault"
    SERVICE_ACCOUNT="keyvault-reader"
    IDENTITY_NAME="id-practitioner-keyvault-reader"
    KEYVAULT_NAME="<globally-unique-key-vault-name>"
    SECRET_NAME="demo-message"
    SECRET_VALUE="Hello from Azure Key Vault using AKS Workload Identity"

Key Vault names must be globally unique.

## Verify AKS Workload Identity and CSI addon

Check the AKS configuration:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "{workloadIdentity:securityProfile.workloadIdentity.enabled, oidcIssuer:oidcIssuerProfile.issuerUrl, keyvaultProvider:addonProfiles.azureKeyvaultSecretsProvider.enabled}" \
      -o table

Check CSI provider pods:

    kubectl get pods -n kube-system | grep -E "csi-secrets-store|secrets-store|keyvault"

If the Key Vault provider addon is missing, enable it:

    az aks enable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons azure-keyvault-secrets-provider

Verify again:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.azureKeyvaultSecretsProvider" \
      -o json

    kubectl get pods -n kube-system | grep -E "csi-secrets-store|secrets-store|keyvault"

## Create Key Vault

Create a Key Vault with RBAC authorization enabled:

    az keyvault create \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION" \
      --enable-rbac-authorization true

Verify:

    az keyvault show \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query "{name:name, rbac:properties.enableRbacAuthorization}" \
      -o table

## Give yourself permission to create the secret

Because this lab uses Key Vault RBAC, your signed-in Azure user needs permission to create the demo secret.

    USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

    KEYVAULT_ID=$(az keyvault show \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query id \
      -o tsv)

    az role assignment create \
      --assignee-object-id "$USER_OBJECT_ID" \
      --assignee-principal-type User \
      --role "Key Vault Secrets Officer" \
      --scope "$KEYVAULT_ID"

RBAC permissions may take a short time to propagate.

Create the demo secret:

    az keyvault secret set \
      --vault-name "$KEYVAULT_NAME" \
      --name "$SECRET_NAME" \
      --value "$SECRET_VALUE"

## Create managed identity

Create a user-assigned managed identity:

    az identity create \
      --name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION"

Capture identity values:

    IDENTITY_CLIENT_ID=$(az identity show \
      --name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query clientId \
      -o tsv)

    IDENTITY_PRINCIPAL_ID=$(az identity show \
      --name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query principalId \
      -o tsv)

    OIDC_ISSUER=$(az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query oidcIssuerProfile.issuerUrl \
      -o tsv)

    KEYVAULT_ID=$(az keyvault show \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query id \
      -o tsv)

    echo "IDENTITY_CLIENT_ID=$IDENTITY_CLIENT_ID"
    echo "IDENTITY_PRINCIPAL_ID=$IDENTITY_PRINCIPAL_ID"
    echo "OIDC_ISSUER=$OIDC_ISSUER"
    echo "KEYVAULT_ID=$KEYVAULT_ID"

## Give the identity permission to read secrets

Assign the Key Vault Secrets User role to the managed identity:

    az role assignment create \
      --assignee-object-id "$IDENTITY_PRINCIPAL_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "Key Vault Secrets User" \
      --scope "$KEYVAULT_ID"

## Create federated identity credential

Create the federated identity credential that maps the Kubernetes ServiceAccount to the managed identity:

    az identity federated-credential create \
      --name "fic-practitioner-keyvault-reader" \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --issuer "$OIDC_ISSUER" \
      --subject "system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT" \
      --audience "api://AzureADTokenExchange"

The subject must match this format exactly:

    system:serviceaccount:<namespace>:<service-account-name>

## Render Kubernetes manifests

Export values for the render script:

    export AZURE_CLIENT_ID="$IDENTITY_CLIENT_ID"
    export AZURE_TENANT_ID="$(az account show --query tenantId -o tsv)"
    export KEYVAULT_NAME="$KEYVAULT_NAME"

Render manifests:

    ./labs/practitioner/09-key-vault-workload-identity/scripts/render-manifests.sh

Check rendered files:

    find labs/practitioner/09-key-vault-workload-identity/rendered -type f -maxdepth 1 -print

## Deploy the lab

Apply the rendered manifests:

    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/namespace.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/serviceaccount.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/secretproviderclass.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/pod.yaml

## Verify the secret mount

Check the pod:

    kubectl get pod keyvault-demo -n practitioner-keyvault

Check logs:

    kubectl logs keyvault-demo -n practitioner-keyvault

Expected output:

    Reading mounted Key Vault secret...
    Hello from Azure Key Vault using AKS Workload Identity

You can also inspect the mounted file:

    kubectl exec -n practitioner-keyvault keyvault-demo -- cat /mnt/secrets-store/demo-message

## Troubleshooting

### Key Vault provider addon is missing

If this returns empty output:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.azureKeyvaultSecretsProvider" \
      -o json

Enable the addon:

    az aks enable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons azure-keyvault-secrets-provider

### RBAC permission delay

If setting or reading secrets fails soon after role assignment, wait one or two minutes and retry.

Azure RBAC role assignments can take time to propagate.

### Pod is stuck in ContainerCreating

Describe the pod:

    kubectl describe pod keyvault-demo -n practitioner-keyvault

Look for CSI mount errors, identity errors, or Key Vault access errors.

### SecretProviderClass placeholders were not replaced

Check rendered files:

    grep -R "PLACEHOLDER" labs/practitioner/09-key-vault-workload-identity/rendered || true

If placeholders remain, rerun the render script after exporting:

    export AZURE_CLIENT_ID="$IDENTITY_CLIENT_ID"
    export AZURE_TENANT_ID="$(az account show --query tenantId -o tsv)"
    export KEYVAULT_NAME="$KEYVAULT_NAME"

### Federated identity subject mismatch

The federated credential subject must exactly match:

    system:serviceaccount:practitioner-keyvault:keyvault-reader

If the namespace or service account name changes, recreate the federated credential.

## Cleanup

This lab creates Azure and Kubernetes resources. Clean up after testing to avoid leaving identities, role assignments, and Key Vault resources behind.

Delete Kubernetes resources:

    kubectl delete namespace practitioner-keyvault --ignore-not-found

Delete the managed identity:

    az identity delete \
      --name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP"

Delete the Key Vault:

    az keyvault delete \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP"

Optional purge:

    az keyvault purge \
      --name "$KEYVAULT_NAME" \
      --location "$LOCATION"

If purge protection is enabled, the Key Vault cannot be purged until the retention period ends.

## Important note

This is a learning lab.

It demonstrates how a Kubernetes pod can access Azure Key Vault without storing the secret as a raw Kubernetes Secret.

For production, use least privilege access, managed identities per workload, separate Key Vaults or secret scopes where appropriate, and a documented secret rotation process.
