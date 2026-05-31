# Azure Login and CI/CD Variables

මෙම guide එකෙන් deployment pipeline labs වලට අවශ්‍ය Azure values සහ CI/CD variables හදාගන්නේ කොහොමද කියලා පැහැදිලි කරනවා.

GitHub Actions, GitLab CI/CD, Azure DevOps, Jenkins deployment labs run කරන්න කලින් මෙම guide එක follow කරන්න.

## What you will prepare

බොහෝ deployment pipelines වලට මේ values ඕන වෙනවා:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

මේවා pipeline එකට Azure login වෙන්න, ACR එකට image push කරන්න, AKS cluster එකට deploy කරන්න අවශ්‍ය values.

## Step 1 - Login to Azure

Azure CLI login වෙන්න:

    az login

Active account එක check කරන්න:

    az account show -o table

ඔයාට subscriptions කිහිපයක් තියෙනවා නම් correct subscription එක set කරන්න:

    az account set --subscription "<subscription-id>"

## Step 2 - Get subscription ID and tenant ID

Run කරන්න:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

Output එක map කරන්න:

    AZURE_SUBSCRIPTION_ID = subscriptionId
    AZURE_TENANT_ID       = tenantId

## Step 3 - Find AKS cluster values

AKS clusters list කරන්න:

    az aks list -o table

Output එකෙන් මේ values ගන්න:

    AZURE_RESOURCE_GROUP = ResourceGroup
    AKS_CLUSTER_NAME     = Name

Example:

    AZURE_RESOURCE_GROUP = rg-aks-dev-001
    AKS_CLUSTER_NAME     = aks-dev-001

## Step 4 - Find ACR login server

ACR registries list කරන්න:

    az acr list -o table

Login server එක ගන්න:

    az acr show --name <acr-name> --query loginServer -o tsv

Output එක use කරන්න:

    REGISTRY_LOGIN_SERVER = <acr-name>.azurecr.io

Example:

    REGISTRY_LOGIN_SERVER = acraksdev001andrew.azurecr.io

## Step 5 - Create a service principal

Learning labs වලට එක service principal එකක් හදාගෙන CI/CD pipelines වල use කරන්න පුළුවන්.

Run කරන්න:

    az ad sp create-for-rbac \
      --name "sp-aks-cicd-labs" \
      --role Contributor \
      --scopes /subscriptions/<subscription-id> \
      --sdk-auth

Output එකේ මේ values තියෙනවා:

    clientId
    clientSecret
    tenantId
    subscriptionId

Map කරන්න:

    AZURE_CLIENT_ID        = clientId
    AZURE_CLIENT_SECRET    = clientSecret
    AZURE_TENANT_ID        = tenantId
    AZURE_SUBSCRIPTION_ID  = subscriptionId

මෙම learning labs වල ACR login සඳහා:

    REGISTRY_USERNAME      = AZURE_CLIENT_ID
    REGISTRY_PASSWORD      = AZURE_CLIENT_SECRET

## Step 6 - Give ACR push permission

ACR resource ID එක ගන්න:

    ACR_ID=$(az acr show --name <acr-name> --query id -o tsv)

AcrPush permission දෙන්න:

    az role assignment create \
      --assignee <AZURE_CLIENT_ID> \
      --role AcrPush \
      --scope "$ACR_ID"

මෙයින් service principal එකට ACR එකට Docker image push කරන්න permission ලැබෙනවා.

## Step 7 - If you forgot the client secret

Azure existing client secret එක නැවත show කරන්නේ නැහැ.

Secret එක අමතක නම් new secret එකක් create කරන්න:

    az ad app credential reset \
      --id <AZURE_CLIENT_ID> \
      --display-name "cicd-lab-secret" \
      --query "{clientSecret:password}" \
      -o table

New value එක use කරන්න:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

Secret values chat එකට, code එකට, README එකට, Git commit එකට, screenshot එකට paste කරන්න එපා.

## Step 8 - GitHub Actions secrets

GitHub repo එකේ:

    GitHub repository
    -> Settings
    -> Secrets and variables
    -> Actions
    -> New repository secret

Add කරන්න:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

## Step 9 - GitLab CI/CD variables

GitLab project එකේ:

    GitLab project
    -> Settings
    -> CI/CD
    -> Variables

Add කරන්න:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Secret values සඳහා:

    Masked: yes
    Protected: no for learning branches

Masked කරන්න:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

## Step 10 - Azure DevOps pipeline variables

Azure DevOps project එකේ:

    Azure DevOps project
    -> Pipelines
    -> Select pipeline
    -> Edit
    -> Variables
    -> New variable

Add කරන්න:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Secret ලෙස mark කරන්න:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

## Step 11 - Verify values

Local machine එකෙන් AKS access check කරන්න:

    az aks get-credentials \
      --resource-group "<resource-group>" \
      --name "<aks-cluster-name>" \
      --overwrite-existing

    kubectl get nodes

ACR login server එක check කරන්න:

    az acr show --name <acr-name> --query loginServer -o tsv

## Cleanup and security

Testing ඉවර වුණාම CI/CD systems වලින් secrets remove කරන්න.

Service principal credentials list කරන්න:

    az ad app credential list \
      --id <AZURE_CLIENT_ID> \
      --query "[].{displayName:displayName,endDateTime:endDateTime,keyId:keyId}" \
      -o table

Temporary credential එකක් delete කරන්න:

    az ad app credential delete \
      --id <AZURE_CLIENT_ID> \
      --key-id <KEY_ID>

Production වලට prefer කරන්න:

- Least privilege permissions
- Environment එකකට වෙනම service principal
- Secret rotation
- Azure DevOps service connections
- OIDC / federated credentials where possible
