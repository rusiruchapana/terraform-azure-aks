# Key Vault සහ Workload Identity

මෙම document එකෙන් Azure Key Vault සහ AKS Workload Identity මෙම platform එකේ use කරන ආකාරය පැහැදිලි කරනවා.

## Purpose

Goal එක තමයි Kubernetes workloads වලට Azure credentials pods ඇතුළේ store නොකර Azure resources secure විදියට access කරන්න ඉඩ දීම.

Recommended pattern:

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

## Key Vault optional

Key Vault terraform.tfvars file එකෙන් enable/disable කරන්න පුළුවන්.

Key Vault enable කරන්න:

    enable_keyvault = true

Key Vault disable කරන්න:

    enable_keyvault = false

Enabled නම් Terraform Azure Key Vault එකක් create කරනවා.

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

Key Vault name globally unique වෙන්න ඕන.

## Key Vault RBAC mode

මෙම project එක Key Vault RBAC mode use කරනවා.

ඒ කියන්නේ access control Azure RBAC roles වලින් වෙනවා.

Project එක use කරන setting එක:

    rbac_authorization_enabled = true

RBAC mode එකේදී Key Vault access policies use වෙන්නේ නැහැ.

## Management plane vs data plane

Azure permissions වල important layers දෙකක් තියෙනවා.

Management plane:

    Azure resources create/update/delete කිරීම.

Data plane:

    Resource එකක් ඇතුළේ data read/write කිරීම.

Key Vault සඳහා:

- Key Vault resource එක create කිරීම management-plane access
- Secrets read/write කිරීම data-plane access

Important:

Subscription Owner හෝ Contributor කෙනෙක්ට Key Vault create කරන්න පුළුවන්. හැබැයි secrets create/read කරන්න data-plane RBAC roles නැත්නම් permission නැහැ.

## Important Key Vault roles

Secrets create/update කරන human/operator users සඳහා:

    Key Vault Secrets Officer

Secrets read කරන applications සඳහා:

    Key Vault Secrets User

Recommended pattern:

- Human/operator account එකට Key Vault Secrets Officer
- Application workload identity එකට Key Vault Secrets User

## Workload Identity use කරන්නේ ඇයි?

Azure client secrets Kubernetes pods ඇතුළේ store කරන්න එපා.

ඒ වෙනුවට AKS Workload Identity use කරන්න.

Benefits:

- Kubernetes secrets වල Azure client secrets නැහැ
- Identity එක Kubernetes ServiceAccount එකකට bind වෙනවා
- Azure RBAC මගින් access control වෙනවා
- Key Vault සමඟ හොඳට work වෙනවා
- App identity model එක clean සහ secure වෙනවා

## AKS OIDC issuer

AKS Workload Identity සඳහා AKS OIDC issuer අවශ්‍යයි.

Recommended setting:

    aks_oidc_issuer_enabled = true

Terraform output:

    aks_oidc_issuer_url

මේ URL එක Azure ට AKS cluster එකෙන් එන tokens trust කරන්න use වෙනවා.

## Workload Identity enable කිරීම

Recommended setting:

    aks_workload_identity_enabled = true

මේකෙන් cluster එකට Workload Identity use කරන්න enable වෙනවා.

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

Federated identity credential subject එක Kubernetes ServiceAccount එකට match වෙන්න ඕන.

Format:

    system:serviceaccount:<namespace>:<service-account-name>

Example:

    system:serviceaccount:app-secrets-demo:kv-reader-sa

Namespace හෝ ServiceAccount name match නොවුනොත් login fail වෙනවා.

## ServiceAccount annotation

ServiceAccount එක managed identity client ID එකෙන් annotate කරන්න ඕන.

Example:

    azure.workload.identity/client-id: "<managed-identity-client-id>"

## Pod label

Pod එකට මේ label එක තියෙන්න ඕන:

    azure.workload.identity/use: "true"

මේ label එක නැත්නම් Workload Identity webhook එක required environment variables සහ token file inject නොකරන්න පුළුවන්.

## Expected injected environment variables

Correctly configured pod එකක් ඇතුළේ මේ variables තියෙන්න ඕන:

    AZURE_CLIENT_ID
    AZURE_TENANT_ID
    AZURE_FEDERATED_TOKEN_FILE

Token file path සාමාන්‍යයෙන්:

    /var/run/secrets/azure/tokens/azure-identity-token

## Federated token login pattern

Pod එක ඇතුළේ federated token login use කරන්න:

    az login \
      --service-principal \
      --username "$AZURE_CLIENT_ID" \
      --tenant "$AZURE_TENANT_ID" \
      --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"

AKS Workload Identity සඳහා මේක use කරන්න එපා:

    az login --identity

ඒ command එක managed identity endpoint login සඳහා. Federated token login සඳහා නෙවෙයි.

## Key Vault secret test

Operator ලෙස Key Vault secret එකක් create කරන්න.

Operator account එකට ඕන:

    Key Vault Secrets Officer

Example:

    az keyvault secret set \
      --vault-name <keyvault-name> \
      --name demo-message \
      --value "hello-from-keyvault"

ඊට පස්සේ Key Vault Secrets User role තියෙන workload identity එකකට secret read කරන්න පුළුවන්.

Example:

    az keyvault secret show \
      --vault-name <keyvault-name> \
      --name demo-message \
      --query value -o tsv

## Common error: ForbiddenByRbac

Error:

    ForbiddenByRbac
    Caller is not authorized to perform action

ඇයි වෙන්නේ?

Caller ට correct Key Vault data-plane role නැහැ.

Fix:

Secrets set කරන්න assign කරන්න:

    Key Vault Secrets Officer

Secrets read කරන්න assign කරන්න:

    Key Vault Secrets User

Role assignment propagation වෙන්න minutes කිහිපයක් ගත වෙන්න පුළුවන්.

## Common error: Identity not found

Error:

    ERROR: Identity not found
    Please run az login

Common cause:

Workload Identity pod එක ඇතුළේ මේ command එක use කිරීම:

    az login --identity

Fix:

Federated token login use කරන්න:

    az login \
      --service-principal \
      --username "$AZURE_CLIENT_ID" \
      --tenant "$AZURE_TENANT_ID" \
      --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"

## Common error: environment variables missing

AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_FEDERATED_TOKEN_FILE missing නම් check කරන්න:

- Pod එකට azure.workload.identity/use: "true" label තියෙනවද
- ServiceAccount annotation correct ද
- Pod එක correct ServiceAccount use කරනවද
- AKS වල Workload Identity enabled ද
- Azure Workload Identity webhook running ද

## Cleanup guidance

Testing පස්සේ demo workload identity resources remove කරන්න පුළුවන්.

Delete කරන්න safe දේවල්:

- Demo test pod
- Demo namespace
- Demo ServiceAccount
- Demo federated credential
- Demo app managed identity
- Demo role assignment

Cluster එකට Workload Identity support disable කරන්න ඕන නැත්නම් core AKS OIDC හෝ Workload Identity settings delete කරන්න එපා.

## Demo identity permanent තියාගන්න එපා ඇයි?

මෙම platform එක app-agnostic.

Real application එකක් තමන්ගේම මේ resources define කරන්න ඕන:

- Namespace
- ServiceAccount
- Managed identity
- Federated identity credential
- Key Vault role assignment

Demo identities core platform එකේ permanent තියාගත්තොත් leftover resources සහ confusion ඇති වෙන්න පුළුවන්.

## Recommended learning path

Beginner:

1. Key Vault RBAC තේරුම් ගන්න
2. Secret එකක් manually create කරන්න
3. Azure CLI වලින් secret read කරන්න

Practitioner:

1. ServiceAccount create කරන්න
2. Managed identity create කරන්න
3. Federated credential create කරන්න
4. Key Vault Secrets User assign කරන්න
5. Pod එකකින් secret read කරන්න

Professional:

1. Application එකකට වෙනම identity create කරන්න
2. Least privilege RBAC use කරන්න
3. Identity resources Terraform හෝ GitOps වලින් manage කරන්න
4. Access regularly rotate සහ audit කරන්න
5. Secret access monitoring add කරන්න
