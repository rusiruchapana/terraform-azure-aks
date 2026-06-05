# Stage 02 - Kubernetes Access and Platform Verification

## මේ stage එකේදී මොකක්ද වෙන්නේ?

මෙම stage එකේදී Terraform වලින් create කළ AKS cluster එකට connect වෙලා platform foundation එක healthy ද කියලා verify කරනවා.

මෙහිදී app එක deploy කරන්නේ නැහැ.

මුලින් cluster එක ready ද, nodes ready ද, system pods running ද, ACR access ready ද, Workload Identity base ready ද කියලා බලනවා.

## ඇයි මේ stage එක වැදගත්?

Cloud platform එකක් provision වුණා කියලා ඒක use කරන්න ready කියලා assume කරන්න බැහැ.

Production වල platform එකක් ready කියන්න නම් මේවා verify කරන්න ඕන:

- cluster provisioning state
- node pools
- kubectl access
- node readiness
- kube-system pods
- container registry access
- identity and secret access foundation

මේ checks pass වුණාම තමයි next tools install කරන්න පුළුවන්.

## Architecture එකේ මේ stage එක කොතනද?

මෙම stage එක Terraform provisioning සහ platform tools installation අතර තියෙන verification stage එක.

Flow එක:

Terraform apply
→ AKS cluster create වෙනවා
→ kubeconfig configure කරනවා
→ kubectl access verify කරනවා
→ nodes සහ system pods check කරනවා
→ platform tools install කරන්න ready වෙනවා

## kubeconfig කියන්නේ මොකක්ද?

kubeconfig කියන්නේ kubectl tool එක cluster එකට connect වෙන්න use කරන configuration file එක.

සරලව:

kubectl command එක run කරනකොට එය දැනගන්න ඕන:

- මොන cluster එකට connect වෙන්නද?
- මොන user/identity එකෙන් connect වෙන්නද?
- API server endpoint එක මොකක්ද?

ඒ details kubeconfig එකේ තියෙනවා.

AKS kubeconfig get කරන්නේ:

    az aks get-credentials \
      --name aks-capstone-ae-001 \
      --resource-group rg-aks-capstone-ae-001 \
      --overwrite-existing

## kubectl context කියන්නේ මොකක්ද?

kubectl context කියන්නේ current active Kubernetes cluster reference එක.

ඔයාගේ machine එකේ clusters කිහිපයක් තිබුණොත් kubectl command එක යන්නේ current context එකට.

Current context බලන්න:

    kubectl config current-context

Expected:

    aks-capstone-ae-001

## Node pools කියන්නේ මොනවද?

AKS cluster එකේ nodes VM Scale Sets විදිහට run වෙනවා.

මෙම capstone එකේ node pools දෙකක් තියෙනවා:

### system node pool

System node pool එක cluster system workloads සඳහා.

Example:

- CoreDNS
- konnectivity-agent
- metrics-server
- Azure networking pods

### user node pool

User node pool එක application/platform workloads සඳහා.

Example:

- Argo CD
- Gateway controller
- monitoring stack
- capstone app
- AIOps controller

Learning/free quota mode නිසා user node pool එක min 1, max 2 ලෙස configure කරලා තියෙනවා.

Real production වල high availability සඳහා user node pool එක min 2 හෝ ඊට වැඩි nodes තියාගන්න පුළුවන්.

## kube-system pods කියන්නේ මොනවද?

kube-system namespace එකේ Kubernetes cluster එක run වෙන්න අවශ්‍ය system components තියෙනවා.

Examples:

- CoreDNS
- kube-proxy
- metrics-server
- Azure CNI components
- CSI storage drivers
- Workload Identity webhook

මේ pods Running නම් cluster base health හොඳයි කියලා කියන්න පුළුවන්.

Check කරන්න:

    kubectl get pods -n kube-system

## ACR Pull role assignment වැදගත් ඇයි?

AKS cluster එකට private ACR එකෙන් Docker images pull කරන්න permission ඕන.

ඒ permission එක AcrPull role assignment එකෙන් ලැබෙනවා.

මෙම project එකේ ACR:

    acrakscapstoneae9954

AKS kubelet identityට AcrPull role assign කරලා තියෙනවා.

මේක නැත්නම් app deploy කරනකොට pods ImagePullBackOff වෙන්න පුළුවන්.

## Workload Identity verify කරන්නේ ඇයි?

Workload Identity එකෙන් Kubernetes pod එකකට Azure Managed Identity එකක් වගේ Azure resources access කරන්න පුළුවන්.

මෙම capstone එකේ target flow එක:

capstone-prod namespace
→ capstone-api-sa service account
→ federated identity credential
→ Azure managed identity
→ Key Vault Secrets User role
→ Key Vault secret read access

මෙයින් app එකට static password/client secret store කරන්න ඕන නැහැ.

## Commands used in this stage

AKS cluster verify කිරීම:

    az aks show \
      --name aks-capstone-ae-001 \
      --resource-group rg-aks-capstone-ae-001 \
      --query '{name:name, location:location, kubernetesVersion:kubernetesVersion, provisioningState:provisioningState, powerState:powerState.code}' \
      -o table

Node pools verify කිරීම:

    az aks nodepool list \
      --cluster-name aks-capstone-ae-001 \
      --resource-group rg-aks-capstone-ae-001 \
      --query '[].{name:name, vmSize:vmSize, count:count, minCount:minCount, maxCount:maxCount, mode:mode, powerState:powerState.code}' \
      -o table

Kubeconfig configure කිරීම:

    az aks get-credentials \
      --name aks-capstone-ae-001 \
      --resource-group rg-aks-capstone-ae-001 \
      --overwrite-existing

Nodes verify කිරීම:

    kubectl config current-context
    kubectl get nodes -o wide

System pods verify කිරීම:

    kubectl get pods -n kube-system

ACR Pull role verify කිරීම:

    az role assignment list \
      --scope "$(az acr show --name acrakscapstoneae9954 --resource-group rg-aks-capstone-ae-001 --query id -o tsv)" \
      --query "[?roleDefinitionName=='AcrPull'].{principalId:principalId, role:roleDefinitionName, scope:scope}" \
      -o table

Federated identity credential verify කිරීම:

    az identity federated-credential list \
      --identity-name id-capstone-app-kv-ae-001 \
      --resource-group rg-aks-capstone-ae-001 \
      --query '[].{name:name, issuer:issuer, subject:subject}' \
      -o table

## Expected result

AKS cluster:

    aks-capstone-ae-001
    australiaeast
    Succeeded
    Running

Node pools:

    system  Standard_D2s_v5  1  min 1  max 2
    user    Standard_D2s_v5  1  min 1  max 2

Nodes:

    system node Ready
    user node Ready

System pods:

    kube-system pods Running

ACR:

    AcrPull role assignment exists

Workload Identity:

    federated credential exists for:
    system:serviceaccount:capstone-prod:capstone-api-sa

## Troubleshooting

### kubectl points to old cluster

Problem:

kubectl current context points to old deleted cluster.

Fix:

    az aks get-credentials \
      --name aks-capstone-ae-001 \
      --resource-group rg-aks-capstone-ae-001 \
      --overwrite-existing

Then check:

    kubectl config current-context

### Node pool fails due to quota

Problem:

Azure says insufficient regional vCPU quota.

Fix:

For learning/free subscription mode, reduce user node pool:

    user_node_min_count = 1
    user_node_max_count = 2

Production clusters should use higher availability, but learning accounts may need quota-friendly settings.

### ImagePullBackOff later

Possible cause:

AKS does not have permission to pull from ACR.

Check AcrPull role assignment.

## Production meaning

මෙම stage එක production platform validation step එකක්.

Platform team එකක් Terraform apply කරලා cluster create කළාට පස්සේ immediately apps deploy කරන්නේ නැහැ.

මුලින් cluster health verify කරනවා.

- cluster running ද?
- nodes ready ද?
- system pods healthy ද?
- registry access ready ද?
- identity foundation ready ද?

මේ checks pass වුණාට පස්සේ තමයි Argo CD, Gateway, monitoring, and apps deploy කරන next stages වලට යන්නේ.

## මේ stage එකෙන් මතක තියාගන්න ඕන දේ

AKS cluster එක create වුණා කියලා project එක complete නෑ.

Cluster එක use කරන්න ready ද කියලා verify කිරීම production workflow එකේ අනිවාර්ය step එකක්.
