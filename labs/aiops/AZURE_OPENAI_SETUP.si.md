# AI Ops Labs සඳහා Azure OpenAI Setup

AI Ops labs වලදී Kubernetes evidence analyze කර structured operational recommendations ලබා ගැනීමට Azure OpenAI භාවිතා කරයි.

හැම learner කෙනෙක්ම තමන්ගේම Azure subscription එකේ තමන්ගේ Azure OpenAI resource එක create කර භාවිතා කළ යුතුයි.

Authorගේ Azure OpenAI endpoint, key, resource group, හෝ Azure subscription භාවිතා කරන්න එපා.

## මෙම setup එක create කරන දේවල්

මෙම shared setup එක create කරන්නේ:

- AI Ops labs සඳහා Azure resource group එකක්
- Azure OpenAI account එකක්
- chat model deployment එකක්
- AI Ops labs භාවිතා කරන terminal environment variables

AI Ops lab README files වලදී මේ environment variables භාවිතා කරයි:

```bash
AZURE_OPENAI_ENDPOINT
AZURE_OPENAI_KEY
AZURE_OPENAI_DEPLOYMENT
AZURE_OPENAI_API_VERSION
```

## අවශ්‍ය දේවල්

ආරම්භ කිරීමට පෙර ඔබට අවශ්‍යයි:

- Azure CLI installed
- Azure CLI logged in
- resource group create කිරීමට permission
- Azure OpenAI resource create කිරීමට permission
- ඔබ තෝරාගන්නා Azure region/subscription එකේ Azure OpenAI model availability

Model සහ region availability ඔබගේ Azure subscription අනුව වෙනස් විය හැක.

## Azure login check කිරීම

```bash
az account show --query "{name:name, subscriptionId:id, tenantId:tenantId}" -o table
```

වැරදි subscription එක selected නම්, change කරන්න:

```bash
az account set --subscription "<your-subscription-id>"
```

## Azure OpenAI variables set කිරීම

Resource group name එකක් සහ region එකක් තෝරන්න.

```bash
export AIOPS_OPENAI_RESOURCE_GROUP="<your-aiops-resource-group>"
export AIOPS_OPENAI_LOCATION="<azure-region>"
export AIOPS_OPENAI_ACCOUNT="aiops-openai-$RANDOM"

export AZURE_OPENAI_DEPLOYMENT="gpt-4-1-nano"
export AZURE_OPENAI_MODEL_NAME="gpt-4.1-nano"
export AZURE_OPENAI_MODEL_VERSION="2025-04-14"
export AZURE_OPENAI_API_VERSION="2024-10-21"
```

Example regions ලෙස `eastus`, `swedencentral`, හෝ ඔබගේ subscription එකට model access ඇති වෙනත් region එකක් භාවිතා කළ හැක.

Verify කරන්න:

```bash
echo "$AIOPS_OPENAI_RESOURCE_GROUP"
echo "$AIOPS_OPENAI_LOCATION"
echo "$AIOPS_OPENAI_ACCOUNT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_MODEL_NAME"
echo "$AZURE_OPENAI_MODEL_VERSION"
echo "$AZURE_OPENAI_API_VERSION"
```

## Resource group එක create කිරීම

```bash
az group create \
  --name "$AIOPS_OPENAI_RESOURCE_GROUP" \
  --location "$AIOPS_OPENAI_LOCATION"
```

## Azure OpenAI account එක create කිරීම

```bash
az cognitiveservices account create \
  --name "$AIOPS_OPENAI_ACCOUNT" \
  --resource-group "$AIOPS_OPENAI_RESOURCE_GROUP" \
  --location "$AIOPS_OPENAI_LOCATION" \
  --kind OpenAI \
  --sku S0 \
  --yes
```

## Model deployment එක create කිරීම

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

ඔබ තෝරාගත් region එකේ model, model version, deployment type, හෝ quota available නැති නිසා command එක fail වුණොත්, ඔබගේ Azure subscription එකට available වෙනත් region එකක් හෝ supported chat model එකක් තෝරන්න.

## Endpoint සහ key export කිරීම

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

Current terminal එකේ values තියෙනවද verify කරන්න.

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_API_VERSION"
test -n "$AZURE_OPENAI_KEY" && echo "AZURE_OPENAI_KEY is set"
```

Key value එක print කරන්න එපා. Key එක Git වලට commit කරන්න එපා.

## Azure OpenAI test කිරීම

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

Successful response එකක `choices` array එකක් තිබිය යුතුයි.

## මෙම setup එක AI Ops lab එකක භාවිතා කිරීම

මෙම setup එක complete වූ පසු, specific AI Ops lab එකට continue කරන්න.

හැම lab එකක්ම මෙම environment variables වලින් තමන්ගේ Kubernetes Secret එක create කරයි:

```bash
kubectl create secret generic aiops-openai-secret \
  -n "$AIOPS_NAMESPACE" \
  --from-literal=AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
  --from-literal=AZURE_OPENAI_KEY="$AZURE_OPENAI_KEY" \
  --from-literal=AZURE_OPENAI_DEPLOYMENT="$AZURE_OPENAI_DEPLOYMENT" \
  --from-literal=AZURE_OPENAI_API_VERSION="$AZURE_OPENAI_API_VERSION" \
  --dry-run=client -o yaml | kubectl apply -f -
```

හැම lab එකක්ම තමන්ගේ Kubernetes namespaces සහ workloads create කර clean කළ යුතුයි.

## Azure OpenAI cleanup

ඔබ Azure OpenAI resource group එක AI Ops labs සඳහා පමණක් create කරලා තව labs continue නොකරනවා නම්, ඔබගේ Azure subscription එකෙන් එම resource group එක delete කරන්න.

```bash
az group delete \
  --name "$AIOPS_OPENAI_RESOURCE_GROUP" \
  --yes
```

ඔබ තවත් AI Ops lab එකකට continue කරනවා නම්, මෙම Azure OpenAI resource එක තියාගෙන endpoint, deployment name, API version, සහ key නැවත භාවිතා කළ හැක.

Azure OpenAI තියාගත්තත් Kubernetes leftovers තියාගන්න බැහැ. හැම lab එකක්ම create කරන Kubernetes resources clean කළ යුතුයි.
