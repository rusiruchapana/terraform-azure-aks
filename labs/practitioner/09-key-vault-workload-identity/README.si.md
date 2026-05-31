# Practitioner Lab 09 - Key Vault and Workload Identity

මෙම lab එකෙන් AKS Workload Identity use කරලා pod එකකට Azure Key Vault එකෙන් secret එකක් read කරන්න ඉඩ දෙන විදිය ඉගෙන ගන්නවා.

Pod එක raw Kubernetes Secret එකක් ලෙස secret එක store කරන්නේ නැහැ. ඒ වෙනුවට මෙය use කරනවා:

- Azure Key Vault
- AKS Workload Identity
- User-assigned managed identity
- Federated identity credential
- Secrets Store CSI Driver
- Azure Key Vault provider for Secrets Store CSI Driver

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- AKS Workload Identity වැඩ කරන විදිය
- Key Vault Secrets Provider addon enable සහ verify කරන විදිය
- Key Vault secret එකක් create කරන විදිය
- User-assigned managed identity එකක් create කරන විදිය
- Kubernetes ServiceAccount එකක් Azure managed identity එකකට map කරන විදිය
- Federated identity credential එකක් use කරන විදිය
- Key Vault secret එකක් pod එකකට mount කරන විදිය
- Testing ඉවර වුණාම Azure සහ Kubernetes resources clean up කරන විදිය

## Architecture

Flow එක:

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

Secret එක pod එකට mount වෙන්නේ මෙතනට:

    /mnt/secrets-store/demo-message

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- Azure CLI
- kubectl
- Existing AKS cluster
- AKS OIDC issuer enabled
- AKS Workload Identity enabled
- Azure Key Vault Secrets Provider addon enabled
- Azure managed identities create කරන්න permission
- Azure Key Vault secrets create/update කරන්න permission
- Azure role assignments create කරන්න permission

Azure සහ Kubernetes access check කරන්න:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl get nodes

## Lab files

මෙම lab එකේ files:

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

ඔයාගේ environment එකට values set කරන්න:

    RESOURCE_GROUP="rg-aks-dev-001"
    AKS_NAME="aks-dev-001"
    LOCATION="southeastasia"
    NAMESPACE="practitioner-keyvault"
    SERVICE_ACCOUNT="keyvault-reader"
    IDENTITY_NAME="id-practitioner-keyvault-reader"
    KEYVAULT_NAME="<globally-unique-key-vault-name>"
    SECRET_NAME="demo-message"
    SECRET_VALUE="Hello from Azure Key Vault using AKS Workload Identity"

Key Vault names globally unique වෙන්න ඕන.

## Verify AKS Workload Identity and CSI addon

AKS configuration එක check කරන්න:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "{workloadIdentity:securityProfile.workloadIdentity.enabled, oidcIssuer:oidcIssuerProfile.issuerUrl, keyvaultProvider:addonProfiles.azureKeyvaultSecretsProvider.enabled}" \
      -o table

CSI provider pods check කරන්න:

    kubectl get pods -n kube-system | grep -E "csi-secrets-store|secrets-store|keyvault"

Key Vault provider addon එක missing නම් enable කරන්න:

    az aks enable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons azure-keyvault-secrets-provider

නැවත verify කරන්න:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.azureKeyvaultSecretsProvider" \
      -o json

    kubectl get pods -n kube-system | grep -E "csi-secrets-store|secrets-store|keyvault"

## Create Key Vault

RBAC authorization enabled Key Vault එකක් create කරන්න:

    az keyvault create \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION" \
      --enable-rbac-authorization true

Verify කරන්න:

    az keyvault show \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query "{name:name, rbac:properties.enableRbacAuthorization}" \
      -o table

## Give yourself permission to create the secret

මෙම lab එක Key Vault RBAC use කරන නිසා, demo secret එක create කරන්න signed-in Azure user එකට permission අවශ්‍යයි.

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

RBAC permissions propagate වෙන්න ටික වෙලාවක් යන්න පුළුවන්.

Demo secret එක create කරන්න:

    az keyvault secret set \
      --vault-name "$KEYVAULT_NAME" \
      --name "$SECRET_NAME" \
      --value "$SECRET_VALUE"

## Create managed identity

User-assigned managed identity එකක් create කරන්න:

    az identity create \
      --name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION"

Identity values capture කරන්න:

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

Managed identity එකට Key Vault Secrets User role assign කරන්න:

    az role assignment create \
      --assignee-object-id "$IDENTITY_PRINCIPAL_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "Key Vault Secrets User" \
      --scope "$KEYVAULT_ID"

## Create federated identity credential

Kubernetes ServiceAccount එක managed identity එකට map කරන federated identity credential එක create කරන්න:

    az identity federated-credential create \
      --name "fic-practitioner-keyvault-reader" \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --issuer "$OIDC_ISSUER" \
      --subject "system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT" \
      --audience "api://AzureADTokenExchange"

Subject එක මේ format එකට exact match වෙන්න ඕන:

    system:serviceaccount:<namespace>:<service-account-name>

## Render Kubernetes manifests

Render script එකට values export කරන්න:

    export AZURE_CLIENT_ID="$IDENTITY_CLIENT_ID"
    export AZURE_TENANT_ID="$(az account show --query tenantId -o tsv)"
    export KEYVAULT_NAME="$KEYVAULT_NAME"

Manifests render කරන්න:

    ./labs/practitioner/09-key-vault-workload-identity/scripts/render-manifests.sh

Rendered files check කරන්න:

    find labs/practitioner/09-key-vault-workload-identity/rendered -type f -maxdepth 1 -print

## Deploy the lab

Rendered manifests apply කරන්න:

    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/namespace.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/serviceaccount.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/secretproviderclass.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/pod.yaml

## Verify the secret mount

Pod එක check කරන්න:

    kubectl get pod keyvault-demo -n practitioner-keyvault

Logs check කරන්න:

    kubectl logs keyvault-demo -n practitioner-keyvault

Expected output:

    Reading mounted Key Vault secret...
    Hello from Azure Key Vault using AKS Workload Identity

Mounted file එක inspect කරන්නත් පුළුවන්:

    kubectl exec -n practitioner-keyvault keyvault-demo -- cat /mnt/secrets-store/demo-message

## Troubleshooting

### Key Vault provider addon is missing

මෙය empty output return කරනවා නම්:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.azureKeyvaultSecretsProvider" \
      -o json

Addon එක enable කරන්න:

    az aks enable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons azure-keyvault-secrets-provider

### RBAC permission delay

Role assignment කළාට පස්සේ secret set/read fail වුණොත්, විනාඩි එකක් දෙකක් ඉඳලා retry කරන්න.

Azure RBAC role assignments propagate වෙන්න වෙලාවක් යන්න පුළුවන්.

### Pod is stuck in ContainerCreating

Pod එක describe කරන්න:

    kubectl describe pod keyvault-demo -n practitioner-keyvault

CSI mount errors, identity errors, හෝ Key Vault access errors බලන්න.

### SecretProviderClass placeholders were not replaced

Rendered files check කරන්න:

    grep -R "PLACEHOLDER" labs/practitioner/09-key-vault-workload-identity/rendered || true

Placeholders ඉතිරි නම්, මේ values export කරලා render script එක නැවත run කරන්න:

    export AZURE_CLIENT_ID="$IDENTITY_CLIENT_ID"
    export AZURE_TENANT_ID="$(az account show --query tenantId -o tsv)"
    export KEYVAULT_NAME="$KEYVAULT_NAME"

### Federated identity subject mismatch

Federated credential subject එක මේකට exact match වෙන්න ඕන:

    system:serviceaccount:practitioner-keyvault:keyvault-reader

Namespace හෝ service account name වෙනස් කළොත්, federated credential එක recreate කරන්න.

## Cleanup

මෙම lab එක Azure සහ Kubernetes resources create කරනවා. Testing ඉවර වුණාම identities, role assignments, සහ Key Vault resources ඉතිරි නොවෙන්න clean up කරන්න.

Kubernetes resources delete කරන්න:

    kubectl delete namespace practitioner-keyvault --ignore-not-found

Managed identity delete කරන්න:

    az identity delete \
      --name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP"

Key Vault delete කරන්න:

    az keyvault delete \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP"

Optional purge:

    az keyvault purge \
      --name "$KEYVAULT_NAME" \
      --location "$LOCATION"

Purge protection enabled නම්, retention period එක ඉවර වෙනකම් Key Vault purge කරන්න බැහැ.

## Important note

මෙය learning lab එකක්.

මෙම lab එකෙන් Kubernetes pod එකක් raw Kubernetes Secret එකක් store නොකර Azure Key Vault access කරන විදිය පෙන්වනවා.

Production සඳහා least privilege access, workload එකකට වෙනම managed identities, අවශ්‍ය තැන්වල separate Key Vaults හෝ secret scopes, සහ documented secret rotation process එකක් use කරන්න.
