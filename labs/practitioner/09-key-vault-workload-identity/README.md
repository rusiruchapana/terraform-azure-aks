# Practitioner Lab 09 - Key Vault and Workload Identity

This lab shows how to use AKS Workload Identity to let a Kubernetes pod read a secret from Azure Key Vault.

This is a standalone AKS security lab.

The pod does not store the secret as a raw Kubernetes Secret.

Instead, the pod uses:

- Azure Key Vault
- AKS Workload Identity
- User-assigned managed identity
- Federated identity credential
- Secrets Store CSI Driver
- Azure Key Vault provider for Secrets Store CSI Driver

## Lab goal

By the end of this lab, you should have:

- An Azure Key Vault created for the lab
- A demo secret stored in Azure Key Vault
- A user-assigned managed identity
- A federated identity credential that maps a Kubernetes ServiceAccount to the managed identity
- A Kubernetes namespace named `practitioner-keyvault`
- A ServiceAccount named `keyvault-reader`
- A SecretProviderClass configured for Azure Key Vault
- A pod named `keyvault-demo`
- The Key Vault secret mounted into the pod as a file

The secret is mounted into the pod at:

    /mnt/secrets-store/demo-message

Expected pod log output:

    Reading mounted Key Vault secret...
    Hello from Azure Key Vault using AKS Workload Identity

## What you will learn

You will learn:

- How AKS Workload Identity works
- How to verify AKS OIDC issuer and Workload Identity settings
- How to verify the Azure Key Vault Secrets Provider addon
- How to create a Key Vault secret
- How to create a user-assigned managed identity
- How to map a Kubernetes ServiceAccount to an Azure managed identity
- How to create a federated identity credential
- How to render Kubernetes manifests with Azure values
- How to mount a Key Vault secret into a pod
- How to troubleshoot identity, RBAC, and CSI mount issues
- How to clean up Azure and Kubernetes resources after testing

## Lab architecture

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
    Federated identity credential
      |
      v
    User-assigned managed identity
      |
      v
    Azure Key Vault
      |
      v
    Mounted secret file

The Kubernetes pod uses the ServiceAccount.

The ServiceAccount is annotated with the Azure managed identity client ID.

The federated identity credential allows Azure AD to trust tokens from the AKS OIDC issuer for that ServiceAccount subject.

The Secrets Store CSI Driver mounts the Key Vault secret as a file inside the pod.

## What this lab requires

You need:

- Azure CLI
- kubectl
- A terminal
- An AKS cluster
- AKS OIDC issuer enabled
- AKS Workload Identity enabled
- Azure Key Vault Secrets Provider addon enabled, or permission to enable it
- Permission to create Azure Key Vaults
- Permission to create or update Azure Key Vault secrets
- Permission to create user-assigned managed identities
- Permission to create Azure role assignments
- Permission to create federated identity credentials

This lab does not require:

- Docker Desktop
- A container registry
- A CI/CD platform
- A public application endpoint

## Install required local tools

### Azure CLI

Install Azure CLI:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Verify Azure CLI:

    az version

Login to Azure:

    az login

Verify the active account:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

### kubectl

Install kubectl:

    https://kubernetes.io/docs/tasks/tools/

Verify kubectl:

    kubectl version --client

## Check local tools and Azure access

Before continuing, verify:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl version --client

Set your AKS values:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"

Get AKS credentials:

    az aks get-credentials \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --overwrite-existing

Verify AKS access:

    kubectl get nodes

## Find your Azure values

Use these commands to find your resource group, AKS cluster, and location.

List resource groups:

    az group list --query "[].{name:name, location:location}" -o table

List AKS clusters:

    az aks list --query "[].{name:name, resourceGroup:resourceGroup, location:location}" -o table

Set your values:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"
    LOCATION="<your-azure-region>"

Example location format:

    southeastasia

Verify:

    echo "$RESOURCE_GROUP"
    echo "$AKS_NAME"
    echo "$LOCATION"

Do not copy values from another environment.

Use values from your own Azure subscription.

## Files in this lab

This lab includes:

    manifests/
      Kubernetes manifest templates with placeholders

    scripts/
      Helper script to render manifests with real Azure values

Files:

    manifests/namespace.yaml
    manifests/serviceaccount.yaml
    manifests/secretproviderclass.yaml
    manifests/pod.yaml
    scripts/render-manifests.sh

The render script creates this folder during the lab:

    rendered/

The `rendered/` folder is generated output and should not be committed to Git.

## Set lab variables

Set these values for your environment:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"
    LOCATION="<your-azure-region>"
    NAMESPACE="practitioner-keyvault"
    SERVICE_ACCOUNT="keyvault-reader"
    IDENTITY_NAME="id-practitioner-keyvault-reader"
    KEYVAULT_NAME="<globally-unique-key-vault-name>"
    SECRET_NAME="demo-message"
    SECRET_VALUE="Hello from Azure Key Vault using AKS Workload Identity"

Key Vault names must be globally unique.

A good pattern is to include your initials and a short random suffix:

    KEYVAULT_NAME="kv-akswi-<your-initials>-<random-number>"

Verify:

    echo "$RESOURCE_GROUP"
    echo "$AKS_NAME"
    echo "$LOCATION"
    echo "$KEYVAULT_NAME"

## Verify AKS Workload Identity and CSI addon

Check the AKS configuration:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "{workloadIdentity:securityProfile.workloadIdentity.enabled, oidcIssuer:oidcIssuerProfile.issuerUrl, keyvaultProvider:addonProfiles.azureKeyvaultSecretsProvider.enabled}" \
      -o table

Expected:

    workloadIdentity is true
    oidcIssuer has a URL
    keyvaultProvider is true

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

If Workload Identity or the OIDC issuer is not enabled, enable them before continuing:

    az aks update \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --enable-oidc-issuer \
      --enable-workload-identity

Then verify the AKS configuration again.

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

Expected:

    rbac is true

## Give yourself permission to create the secret

Because this lab uses Key Vault RBAC, your signed-in Azure user needs permission to create the demo secret.

Get your signed-in user object ID:

    USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

Get the Key Vault resource ID:

    KEYVAULT_ID=$(az keyvault show \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query id \
      -o tsv)

Assign yourself the Key Vault Secrets Officer role:

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

Verify the secret exists:

    az keyvault secret show \
      --vault-name "$KEYVAULT_NAME" \
      --name "$SECRET_NAME" \
      --query "{name:name, enabled:attributes.enabled}" \
      -o table

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

Verify values:

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

RBAC permissions may take a short time to propagate.

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

For this lab, the subject is:

    system:serviceaccount:practitioner-keyvault:keyvault-reader

Verify the federated credential:

    az identity federated-credential list \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      -o table

## Render Kubernetes manifests

Export values for the render script:

    export AZURE_CLIENT_ID="$IDENTITY_CLIENT_ID"
    export AZURE_TENANT_ID="$(az account show --query tenantId -o tsv)"
    export KEYVAULT_NAME="$KEYVAULT_NAME"

Run the render script from the repository root:

    ./labs/practitioner/09-key-vault-workload-identity/scripts/render-manifests.sh

Check rendered files:

    find labs/practitioner/09-key-vault-workload-identity/rendered -maxdepth 1 -type f -print

Verify that placeholders were replaced:

    grep -R "PLACEHOLDER" labs/practitioner/09-key-vault-workload-identity/rendered || true

Expected:

    No PLACEHOLDER output should be shown.

Verify rendered ServiceAccount and SecretProviderClass:

    grep -n "azure.workload.identity/client-id" \
      labs/practitioner/09-key-vault-workload-identity/rendered/serviceaccount.yaml

    grep -n "keyvaultName" \
      labs/practitioner/09-key-vault-workload-identity/rendered/secretproviderclass.yaml

## Deploy the lab

Apply the rendered manifests:

    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/namespace.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/serviceaccount.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/secretproviderclass.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/pod.yaml

Verify Kubernetes resources:

    kubectl get namespace "$NAMESPACE"
    kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE"
    kubectl get secretproviderclass keyvault-demo-secrets -n "$NAMESPACE"
    kubectl get pod keyvault-demo -n "$NAMESPACE"

## Verify the secret mount

Check the pod:

    kubectl get pod keyvault-demo -n "$NAMESPACE"

Check pod logs:

    kubectl logs keyvault-demo -n "$NAMESPACE"

Expected output:

    Reading mounted Key Vault secret...
    Hello from Azure Key Vault using AKS Workload Identity

Inspect the mounted file:

    kubectl exec -n "$NAMESPACE" keyvault-demo -- cat /mnt/secrets-store/demo-message

Expected output:

    Hello from Azure Key Vault using AKS Workload Identity

## Troubleshooting

### Key Vault provider addon is missing

If this returns empty output or disabled status:

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

### Workload Identity or OIDC issuer is missing

If Workload Identity or OIDC issuer is disabled, enable both:

    az aks update \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --enable-oidc-issuer \
      --enable-workload-identity

Then rerun the AKS verification command.

### RBAC permission delay

If setting or reading secrets fails soon after role assignment, wait one or two minutes and retry.

Azure RBAC role assignments can take time to propagate.

### Pod is stuck in ContainerCreating

Describe the pod:

    kubectl describe pod keyvault-demo -n "$NAMESPACE"

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

Verify:

    az identity federated-credential list \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query "[].{name:name, subject:subject, issuer:issuer}" \
      -o table

### Key Vault access denied

Verify that the managed identity has the Key Vault Secrets User role on the Key Vault scope:

    az role assignment list \
      --assignee "$IDENTITY_PRINCIPAL_ID" \
      --scope "$KEYVAULT_ID" \
      --query "[].{role:roleDefinitionName, principalId:principalId}" \
      -o table

## Cleanup

Delete Kubernetes resources:

    kubectl delete namespace "$NAMESPACE" --ignore-not-found

Delete the federated identity credential:

    az identity federated-credential delete \
      --name "fic-practitioner-keyvault-reader" \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --yes

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

Purge may fail if purge protection is enabled or if your account does not have purge permission.

Delete generated rendered manifests:

    rm -rf labs/practitioner/09-key-vault-workload-identity/rendered

Do not delete the template manifests under:

    labs/practitioner/09-key-vault-workload-identity/manifests/

## Security cleanup

After testing, remove or rotate any demo secrets that should not remain in Azure Key Vault.

Do not commit rendered manifests that contain real Azure values.

For production, prefer:

- Least privilege access
- Separate managed identities per workload
- Separate Key Vaults or secret scopes where appropriate
- Secret rotation
- Monitoring for Key Vault access
- Azure Policy controls for workload identity and Key Vault access

## Important note

This is a learning lab.

It demonstrates how a Kubernetes pod can access Azure Key Vault without storing the secret as a raw Kubernetes Secret.

For production, use least privilege access, managed identities per workload, separate Key Vaults or secret scopes where appropriate, and a documented secret rotation process.
