# Azure OpenAI Setup for AI Ops Labs

AI Ops labs use Azure OpenAI to analyze Kubernetes evidence and return structured operational recommendations.

Each learner must create and use their own Azure OpenAI resource in their own Azure subscription.

Do not use the author's Azure OpenAI endpoint, key, resource group, or Azure subscription.

## What this setup creates

This shared setup creates:

- An Azure resource group for AI Ops labs
- An Azure OpenAI account
- A chat model deployment
- Terminal environment variables used by the AI Ops labs

The AI Ops lab README files use these environment variables:

```bash
AZURE_OPENAI_ENDPOINT
AZURE_OPENAI_KEY
AZURE_OPENAI_DEPLOYMENT
AZURE_OPENAI_API_VERSION
```

## What you need

Before you start, you need:

- Azure CLI installed
- Azure CLI logged in
- Permission to create a resource group
- Permission to create an Azure OpenAI resource
- Azure OpenAI model availability in your selected Azure region and subscription

Model and region availability can vary by Azure subscription.

## Check Azure login

```bash
az account show --query "{name:name, subscriptionId:id, tenantId:tenantId}" -o table
```

If the wrong subscription is selected, change it:

```bash
az account set --subscription "<your-subscription-id>"
```

## Set Azure OpenAI variables

Choose a resource group name and a region.

```bash
export AIOPS_OPENAI_RESOURCE_GROUP="<your-aiops-resource-group>"
export AIOPS_OPENAI_LOCATION="<azure-region>"
export AIOPS_OPENAI_ACCOUNT="aiops-openai-$RANDOM"

export AZURE_OPENAI_DEPLOYMENT="gpt-4-1-nano"
export AZURE_OPENAI_MODEL_NAME="gpt-4.1-nano"
export AZURE_OPENAI_MODEL_VERSION="2025-04-14"
export AZURE_OPENAI_API_VERSION="2024-10-21"
```

Example regions may include `eastus`, `swedencentral`, or another region where your subscription has access to the model you want to deploy.

Verify:

```bash
echo "$AIOPS_OPENAI_RESOURCE_GROUP"
echo "$AIOPS_OPENAI_LOCATION"
echo "$AIOPS_OPENAI_ACCOUNT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_MODEL_NAME"
echo "$AZURE_OPENAI_MODEL_VERSION"
echo "$AZURE_OPENAI_API_VERSION"
```

## Create the resource group

```bash
az group create \
  --name "$AIOPS_OPENAI_RESOURCE_GROUP" \
  --location "$AIOPS_OPENAI_LOCATION"
```

## Create the Azure OpenAI account

```bash
az cognitiveservices account create \
  --name "$AIOPS_OPENAI_ACCOUNT" \
  --resource-group "$AIOPS_OPENAI_RESOURCE_GROUP" \
  --location "$AIOPS_OPENAI_LOCATION" \
  --kind OpenAI \
  --sku S0 \
  --yes
```

## Create the model deployment

```bash
az cognitiveservices account deployment create \
  --name "$AIOPS_OPENAI_ACCOUNT" \
  --resource-group "$AIOPS_OPENAI_RESOURCE_GROUP" \
  --deployment-name "$AZURE_OPENAI_DEPLOYMENT" \
  --model-name "$AZURE_OPENAI_MODEL_NAME" \
  --model-version "$AZURE_OPENAI_MODEL_VERSION" \
  --model-format OpenAI \
  --sku-name GlobalStandard \
  --sku-capacity 1
```

If this command fails because the model, model version, deployment type, or quota is not available in your selected region, choose another region or another supported chat model available to your Azure subscription.

## Export endpoint and key

```bash
export AZURE_OPENAI_ENDPOINT="$(az cognitiveservices account show \
  --name "$AIOPS_OPENAI_ACCOUNT" \
  --resource-group "$AIOPS_OPENAI_RESOURCE_GROUP" \
  --query properties.endpoint -o tsv)"

export AZURE_OPENAI_KEY="$(az cognitiveservices account keys list \
  --name "$AIOPS_OPENAI_ACCOUNT" \
  --resource-group "$AIOPS_OPENAI_RESOURCE_GROUP" \
  --query key1 -o tsv)"
```

Verify that the values are available in your current terminal.

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_API_VERSION"
test -n "$AZURE_OPENAI_KEY" && echo "AZURE_OPENAI_KEY is set"
```

Do not print the key value. Do not commit the key to Git.

## Test Azure OpenAI

```bash
curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_OPENAI_API_VERSION" \
  -H "Content-Type: application/json" \
  -H "api-key: $AZURE_OPENAI_KEY" \
  -d '{
    "messages": [
      {
        "role": "system",
        "content": "Return concise JSON only."
      },
      {
        "role": "user",
        "content": "Return {\"status\":\"ok\"}"
      }
    ],
    "temperature": 0,
    "max_tokens": 50
  }'
```

A successful response should include a `choices` array.

## Use this setup in an AI Ops lab

After this setup is complete, continue with the specific AI Ops lab.

Each lab creates its own Kubernetes Secret from these environment variables:

```bash
kubectl create secret generic aiops-openai-secret \
  -n "$AIOPS_NAMESPACE" \
  --from-literal=AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
  --from-literal=AZURE_OPENAI_KEY="$AZURE_OPENAI_KEY" \
  --from-literal=AZURE_OPENAI_DEPLOYMENT="$AZURE_OPENAI_DEPLOYMENT" \
  --from-literal=AZURE_OPENAI_API_VERSION="$AZURE_OPENAI_API_VERSION" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Each lab must still create and clean its own Kubernetes namespaces and workloads.

## Cleanup Azure OpenAI

If you created the Azure OpenAI resource group only for the AI Ops labs and you are not continuing, delete the resource group from your own Azure subscription.

```bash
az group delete \
  --name "$AIOPS_OPENAI_RESOURCE_GROUP" \
  --yes
```

If you are continuing to another AI Ops lab, you may keep this Azure OpenAI resource and reuse the endpoint, deployment name, API version, and key.

Keeping Azure OpenAI does not mean keeping Kubernetes leftovers. Each lab must still clean the Kubernetes resources it creates.
