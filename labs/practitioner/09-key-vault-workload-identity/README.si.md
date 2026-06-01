# Practitioner Lab 09 - Key Vault and Workload Identity

මෙම lab එකෙන් AKS Workload Identity use කරලා Kubernetes pod එකකට Azure Key Vault එකෙන් secret එකක් read කරන්න ඉඩ දෙන විදිය ඉගෙන ගන්නවා.

මෙය standalone AKS security lab එකක්.

Pod එක raw Kubernetes Secret එකක් ලෙස secret එක store කරන්නේ නැහැ.

ඒ වෙනුවට pod එක use කරන්නේ:

- Azure Key Vault
- AKS Workload Identity
- User-assigned managed identity
- Federated identity credential
- Secrets Store CSI Driver
- Azure Key Vault provider for Secrets Store CSI Driver

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- Lab එක සඳහා Azure Key Vault එකක්
- Azure Key Vault තුළ stored demo secret එකක්
- User-assigned managed identity එකක්
- Kubernetes ServiceAccount එක managed identity එකට map කරන federated identity credential එකක්
- `practitioner-keyvault` කියන Kubernetes namespace එකක්
- `keyvault-reader` කියන ServiceAccount එකක්
- Azure Key Vault සඳහා configured SecretProviderClass එකක්
- `keyvault-demo` කියන pod එකක්
- Key Vault secret එක pod එකට file එකක් ලෙස mount වීම

Secret එක pod එක තුළ mount වෙන path එක:

    /mnt/secrets-store/demo-message

Expected pod log output:

    Reading mounted Key Vault secret...
    Hello from Azure Key Vault using AKS Workload Identity

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- AKS Workload Identity works කරන විදිය
- AKS OIDC issuer සහ Workload Identity settings verify කරන විදිය
- Azure Key Vault Secrets Provider addon verify කරන විදිය
- Key Vault secret එකක් create කරන විදිය
- User-assigned managed identity එකක් create කරන විදිය
- Kubernetes ServiceAccount එකක් Azure managed identity එකකට map කරන විදිය
- Federated identity credential එකක් create කරන විදිය
- Azure values සමඟ Kubernetes manifests render කරන විදිය
- Key Vault secret එකක් pod එකකට mount කරන විදිය
- Identity, RBAC, සහ CSI mount issues troubleshoot කරන විදිය
- Testing ඉවර වුණාට පස්සේ Azure සහ Kubernetes resources clean up කරන විදිය

## Lab architecture

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

Kubernetes pod එක ServiceAccount එක use කරනවා.

ServiceAccount එක Azure managed identity client ID එකෙන් annotate කරනවා.

Federated identity credential එක AKS OIDC issuer එකෙන් එන ServiceAccount subject tokens Azure AD trust කරන්න ඉඩ දෙනවා.

Secrets Store CSI Driver එක Key Vault secret එක pod එක තුළ file එකක් ලෙස mount කරනවා.

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- Azure CLI
- kubectl
- Terminal එකක්
- AKS cluster එකක්
- AKS OIDC issuer enabled වීම
- AKS Workload Identity enabled වීම
- Azure Key Vault Secrets Provider addon enabled වීම, නැත්නම් එය enable කරන්න permission
- Azure Key Vaults create කරන්න permission
- Azure Key Vault secrets create/update කරන්න permission
- User-assigned managed identities create කරන්න permission
- Azure role assignments create කරන්න permission
- Federated identity credentials create කරන්න permission

මෙම lab එකට අවශ්‍ය නැහැ:

- Docker Desktop
- Container registry
- CI/CD platform
- Public application endpoint

## Install required local tools

### Azure CLI

Azure CLI install කරන්න:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Azure CLI verify කරන්න:

    az version

Azure වලට login වෙන්න:

    az login

Active account එක verify කරන්න:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

### kubectl

kubectl install කරන්න:

    https://kubernetes.io/docs/tasks/tools/

kubectl verify කරන්න:

    kubectl version --client

## Check local tools and Azure access

Continue කරන්න කලින් verify කරන්න:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl version --client

ඔයාගේ AKS values set කරන්න:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"

AKS credentials ගන්න:

    az aks get-credentials \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --overwrite-existing

AKS access verify කරන්න:

    kubectl get nodes

## Find your Azure values

ඔයාගේ resource group, AKS cluster, සහ location values හොයාගන්න මේ commands use කරන්න.

Resource groups list කරන්න:

    az group list --query "[].{name:name, location:location}" -o table

AKS clusters list කරන්න:

    az aks list --query "[].{name:name, resourceGroup:resourceGroup, location:location}" -o table

ඔයාගේ values set කරන්න:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"
    LOCATION="<your-azure-region>"

Example location format:

    southeastasia

Verify කරන්න:

    echo "$RESOURCE_GROUP"
    echo "$AKS_NAME"
    echo "$LOCATION"

වෙන environment එකක values copy කරන්න එපා.

ඔයාගේම Azure subscription එකේ values use කරන්න.

## Files in this lab

මෙම lab එකේ files:

    manifests/
      Placeholders සහිත Kubernetes manifest templates

    scripts/
      Real Azure values use කරලා manifests render කරන්න helper script

Files:

    manifests/namespace.yaml
    manifests/serviceaccount.yaml
    manifests/secretproviderclass.yaml
    manifests/pod.yaml
    scripts/render-manifests.sh

Render script එක lab එක කරන අතරතුර මේ folder එක create කරනවා:

    rendered/

`rendered/` folder එක generated output එකක්. එය Git වලට commit කරන්න එපා.

## Set lab variables

ඔයාගේ environment එකට මේ values set කරන්න:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"
    LOCATION="<your-azure-region>"
    NAMESPACE="practitioner-keyvault"
    SERVICE_ACCOUNT="keyvault-reader"
    IDENTITY_NAME="id-practitioner-keyvault-reader"
    KEYVAULT_NAME="<globally-unique-key-vault-name>"
    SECRET_NAME="demo-message"
    SECRET_VALUE="Hello from Azure Key Vault using AKS Workload Identity"

Key Vault names globally unique වෙන්න ඕන.

ඔයාගේ initials සහ short random suffix එකක් use කරන pattern එක හොඳයි:

    KEYVAULT_NAME="kv-akswi-<your-initials>-<random-number>"

Verify කරන්න:

    echo "$RESOURCE_GROUP"
    echo "$AKS_NAME"
    echo "$LOCATION"
    echo "$KEYVAULT_NAME"

## Verify AKS Workload Identity and CSI addon

AKS configuration එක check කරන්න:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "{workloadIdentity:securityProfile.workloadIdentity.enabled, oidcIssuer:oidcIssuerProfile.issuerUrl, keyvaultProvider:addonProfiles.azureKeyvaultSecretsProvider.enabled}" \
      -o table

Expected:

    workloadIdentity is true
    oidcIssuer has a URL
    keyvaultProvider is true

CSI provider pods check කරන්න:

    kubectl get pods -n kube-system | grep -E "csi-secrets-store|secrets-store|keyvault"

Key Vault provider addon missing නම් enable කරන්න:

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

Workload Identity හෝ OIDC issuer enabled නැත්නම්, continue කරන්න කලින් ඒවා enable කරන්න:

    az aks update \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --enable-oidc-issuer \
      --enable-workload-identity

ඊට පස්සේ AKS configuration නැවත verify කරන්න.

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

Expected:

    rbac is true

## Give yourself permission to create the secret

මෙම lab එක Key Vault RBAC use කරන නිසා, demo secret එක create කරන්න signed-in Azure user එකට permission අවශ්‍යයි.

Signed-in user object ID එක ගන්න:

    USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

Key Vault resource ID එක ගන්න:

    KEYVAULT_ID=$(az keyvault show \
      --name "$KEYVAULT_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query id \
      -o tsv)

ඔයාට Key Vault Secrets Officer role assign කරන්න:

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

Secret එක තියෙනවද verify කරන්න:

    az keyvault secret show \
      --vault-name "$KEYVAULT_NAME" \
      --name "$SECRET_NAME" \
      --query "{name:name, enabled:attributes.enabled}" \
      -o table

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

Values verify කරන්න:

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

RBAC permissions propagate වෙන්න ටික වෙලාවක් යන්න පුළුවන්.

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

මෙම lab එකට subject එක:

    system:serviceaccount:practitioner-keyvault:keyvault-reader

Federated credential verify කරන්න:

    az identity federated-credential list \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      -o table

## Render Kubernetes manifests

Render script එකට values export කරන්න:

    export AZURE_CLIENT_ID="$IDENTITY_CLIENT_ID"
    export AZURE_TENANT_ID="$(az account show --query tenantId -o tsv)"
    export KEYVAULT_NAME="$KEYVAULT_NAME"

Repository root එකේ සිට render script එක run කරන්න:

    ./labs/practitioner/09-key-vault-workload-identity/scripts/render-manifests.sh

Rendered files check කරන්න:

    find labs/practitioner/09-key-vault-workload-identity/rendered -maxdepth 1 -type f -print

Placeholders replace වුණාද verify කරන්න:

    grep -R "PLACEHOLDER" labs/practitioner/09-key-vault-workload-identity/rendered || true

Expected:

    PLACEHOLDER output කිසිවක් නොපෙන්විය යුතුයි.

Rendered ServiceAccount සහ SecretProviderClass verify කරන්න:

    grep -n "azure.workload.identity/client-id" \
      labs/practitioner/09-key-vault-workload-identity/rendered/serviceaccount.yaml

    grep -n "keyvaultName" \
      labs/practitioner/09-key-vault-workload-identity/rendered/secretproviderclass.yaml

## Deploy the lab

Rendered manifests apply කරන්න:

    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/namespace.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/serviceaccount.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/secretproviderclass.yaml
    kubectl apply -f labs/practitioner/09-key-vault-workload-identity/rendered/pod.yaml

Kubernetes resources verify කරන්න:

    kubectl get namespace "$NAMESPACE"
    kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE"
    kubectl get secretproviderclass keyvault-demo-secrets -n "$NAMESPACE"
    kubectl get pod keyvault-demo -n "$NAMESPACE"

## Verify the secret mount

Pod එක check කරන්න:

    kubectl get pod keyvault-demo -n "$NAMESPACE"

Pod logs check කරන්න:

    kubectl logs keyvault-demo -n "$NAMESPACE"

Expected output:

    Reading mounted Key Vault secret...
    Hello from Azure Key Vault using AKS Workload Identity

Mounted file එක inspect කරන්න:

    kubectl exec -n "$NAMESPACE" keyvault-demo -- cat /mnt/secrets-store/demo-message

Expected output:

    Hello from Azure Key Vault using AKS Workload Identity

## Troubleshooting

### Key Vault provider addon is missing

මෙය empty output හෝ disabled status return කරනවා නම්:

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

### Workload Identity or OIDC issuer is missing

Workload Identity හෝ OIDC issuer disabled නම්, දෙකම enable කරන්න:

    az aks update \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --enable-oidc-issuer \
      --enable-workload-identity

ඊට පස්සේ AKS verification command නැවත run කරන්න.

### RBAC permission delay

Role assignment කළාට පස්සේ secret set/read fail වුණොත්, විනාඩි එකක් දෙකක් ඉඳලා retry කරන්න.

Azure RBAC role assignments propagate වෙන්න වෙලාවක් යන්න පුළුවන්.

### Pod is stuck in ContainerCreating

Pod එක describe කරන්න:

    kubectl describe pod keyvault-demo -n "$NAMESPACE"

CSI mount errors, identity errors, හෝ Key Vault access errors බලන්න.

### SecretProviderClass placeholders were not replaced

Rendered files check කරන්න:

    grep -R "PLACEHOLDER" labs/practitioner/09-key-vault-workload-identity/rendered || true

Placeholders තවම තියෙනවා නම්, මේ values export කරලා render script එක නැවත run කරන්න:

    export AZURE_CLIENT_ID="$IDENTITY_CLIENT_ID"
    export AZURE_TENANT_ID="$(az account show --query tenantId -o tsv)"
    export KEYVAULT_NAME="$KEYVAULT_NAME"

### Federated identity subject mismatch

Federated credential subject එක මේකට exact match වෙන්න ඕන:

    system:serviceaccount:practitioner-keyvault:keyvault-reader

Verify කරන්න:

    az identity federated-credential list \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query "[].{name:name, subject:subject, issuer:issuer}" \
      -o table

### Key Vault access denied

Managed identity එකට Key Vault scope එකේ Key Vault Secrets User role තියෙනවද verify කරන්න:

    az role assignment list \
      --assignee "$IDENTITY_PRINCIPAL_ID" \
      --scope "$KEYVAULT_ID" \
      --query "[].{role:roleDefinitionName, principalId:principalId}" \
      -o table

## Cleanup

Kubernetes resources delete කරන්න:

    kubectl delete namespace "$NAMESPACE" --ignore-not-found

Federated identity credential delete කරන්න:

    az identity federated-credential delete \
      --name "fic-practitioner-keyvault-reader" \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --yes

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

Purge protection enabled නම් හෝ account එකට purge permission නැත්නම් purge fail වෙන්න පුළුවන්.

Generated rendered manifests delete කරන්න:

    rm -rf labs/practitioner/09-key-vault-workload-identity/rendered

Template manifests delete කරන්න එපා:

    labs/practitioner/09-key-vault-workload-identity/manifests/

## Security cleanup

Testing ඉවර වුණාම Azure Key Vault තුළ ඉතිරි විය යුතු නැති demo secrets remove හෝ rotate කරන්න.

Real Azure values තියෙන rendered manifests commit කරන්න එපා.

Production සඳහා prefer කරන්න:

- Least privilege access
- Workload එකකට වෙනම managed identities
- අවශ්‍ය තැන්වල separate Key Vaults හෝ secret scopes
- Secret rotation
- Key Vault access monitoring
- Workload identity සහ Key Vault access සඳහා Azure Policy controls

## Important note

මෙය learning lab එකක්.

මෙම lab එක Kubernetes pod එකකට raw Kubernetes Secret එකක් ලෙස secret store නොකර Azure Key Vault access කරන්න පුළුවන් විදිය demonstrate කරනවා.

Production සඳහා least privilege access, workload එකකට වෙනම managed identities, අවශ්‍ය තැන්වල separate Key Vaults හෝ secret scopes, සහ documented secret rotation process එකක් use කරන්න.
