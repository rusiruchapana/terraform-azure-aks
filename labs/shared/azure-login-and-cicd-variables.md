# Azure Login and CI/CD Variables

This guide explains how to prepare Azure values and CI/CD variables used by deployment pipeline labs.

Use this guide before running GitHub Actions, GitLab CI/CD, Azure DevOps, or Jenkins deployment labs.

## What you will prepare

Most deployment pipelines need these values:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

## Step 1 - Login to Azure

Login:

    az login

Check the active account:

    az account show -o table

If you have multiple subscriptions, set the correct one:

    az account set --subscription "<subscription-id>"

## Step 2 - Get subscription ID and tenant ID

Run:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

Use the output as:

    AZURE_SUBSCRIPTION_ID = subscriptionId
    AZURE_TENANT_ID       = tenantId

## Step 3 - Find AKS cluster values

List AKS clusters:

    az aks list -o table

Use the output as:

    AZURE_RESOURCE_GROUP = ResourceGroup
    AKS_CLUSTER_NAME     = Name

Example:

    AZURE_RESOURCE_GROUP = rg-aks-dev-001
    AKS_CLUSTER_NAME     = aks-dev-001

## Step 4 - Find ACR login server

List ACR registries:

    az acr list -o table

Get login server:

    az acr show --name <acr-name> --query loginServer -o tsv

Use the output as:

    REGISTRY_LOGIN_SERVER = <acr-name>.azurecr.io

Example:

    REGISTRY_LOGIN_SERVER = acraksdev001andrew.azurecr.io

## Step 5 - Create a service principal

For learning labs, you can create one service principal and use it for CI/CD pipelines.

Run:

    az ad sp create-for-rbac \
      --name "sp-aks-cicd-labs" \
      --role Contributor \
      --scopes /subscriptions/<subscription-id> \
      --sdk-auth

The output contains:

    clientId
    clientSecret
    tenantId
    subscriptionId

Map them like this:

    AZURE_CLIENT_ID        = clientId
    AZURE_CLIENT_SECRET    = clientSecret
    AZURE_TENANT_ID        = tenantId
    AZURE_SUBSCRIPTION_ID  = subscriptionId

For ACR login in these learning labs, use:

    REGISTRY_USERNAME      = AZURE_CLIENT_ID
    REGISTRY_PASSWORD      = AZURE_CLIENT_SECRET

## Step 6 - Give ACR push permission

Get the ACR resource ID:

    ACR_ID=$(az acr show --name <acr-name> --query id -o tsv)

Grant AcrPush:

    az role assignment create \
      --assignee <AZURE_CLIENT_ID> \
      --role AcrPush \
      --scope "$ACR_ID"

## Step 7 - If you forgot the client secret

Azure does not show an existing client secret again.

Create a new one:

    az ad app credential reset \
      --id <AZURE_CLIENT_ID> \
      --display-name "cicd-lab-secret" \
      --query "{clientSecret:password}" \
      -o table

Use the new value as:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

Do not paste secrets into chat, code, README files, Git commits, or screenshots.

## Step 8 - GitHub Actions secrets

Go to:

    GitHub repository
    -> Settings
    -> Secrets and variables
    -> Actions
    -> New repository secret

Add:

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

Go to:

    GitLab project
    -> Settings
    -> CI/CD
    -> Variables

Add:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

For secret values:

    Masked: yes
    Protected: no for learning branches

Mark these as masked:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

## Step 10 - Azure DevOps pipeline variables

Go to:

    Azure DevOps project
    -> Pipelines
    -> Select pipeline
    -> Edit
    -> Variables
    -> New variable

Add:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Mark these as secret:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

## Step 11 - Verify values

Check AKS access locally:

    az aks get-credentials \
      --resource-group "<resource-group>" \
      --name "<aks-cluster-name>" \
      --overwrite-existing

    kubectl get nodes

Check ACR login server:

    az acr show --name <acr-name> --query loginServer -o tsv

## Cleanup and security

After testing, remove secrets from CI/CD systems if you no longer need them.

List service principal credentials:

    az ad app credential list \
      --id <AZURE_CLIENT_ID> \
      --query "[].{displayName:displayName,endDateTime:endDateTime,keyId:keyId}" \
      -o table

Delete a temporary credential:

    az ad app credential delete \
      --id <AZURE_CLIENT_ID> \
      --key-id <KEY_ID>

For production, prefer:

- Least privilege permissions
- Separate service principals per environment
- Secret rotation
- Azure DevOps service connections
- OIDC or federated credentials where possible
