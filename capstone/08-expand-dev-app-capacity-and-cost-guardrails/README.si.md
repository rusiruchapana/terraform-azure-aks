# Stage 08 - Dev App Expansion, Capacity Planning, Pay-As-You-Go, and Terraform Import

## මේ stage එකේදී මොකක්ද කරන්නේ?

මෙම stage එකේදී Capstone Store dev app එක minimal setup එකෙන් තවත් real-world workload එකකට expand කරනවා.

කලින් dev app එකේ තිබුණේ:

- store-front
- product-service
- order-service
- rabbitmq

මෙම stage එකේදී add කරනවා:

- mongodb
- makeline-service

මේකෙන් app එක event-driven microservices flow එකකට යනවා:

```text
store-front
→ order-service
→ rabbitmq
→ makeline-service
→ mongodb
```

මෙම stage එක application deployment එකක් විතරක් නෙවෙයි. මෙතන අපිට real cloud engineering issue එකක් ආවා:

- MongoDB pod එක Pending වුණා
- makeline-service එක CrashLoopBackOff වුණා
- root cause එක app bug එකක් නෙවෙයි
- root cause එක cluster capacity / Azure quota limitation එකක්

ඊට පස්සේ අපි issue එක troubleshoot කරලා, Free Trial quota limitation identify කරලා, Pay-As-You-Go upgrade කරලා, budget guardrails දාලා, correct VM family choose කරලා, apps node pool add කරලා, app healthy කරලා, manual node pool එක Terraform state/config වලට import කළා.

---

## Repo path setup

මෙම guide එකේ commands run කරන්න කලින් local repo paths variables ලෙස set කරගන්න.

ඔබේ machine එකේ path වෙනස් නම් මේ values වෙනස් කරන්න.

```bash
export PLATFORM_REPO="$HOME/projcts/terraform-azure-aks"
export GITOPS_REPO="$HOME/projcts/aks-capstone-gitops"
export APP_REPO="$HOME/projcts/aks-capstone-store-app"
```

Repos තුනේ meaning එක:

```text
PLATFORM_REPO = Terraform / platform guides repo
GITOPS_REPO   = Kubernetes manifests / Argo CD repo
APP_REPO      = Capstone Store application source repo
```

---

## Part 1 - Add MongoDB and makeline-service to GitOps

### 1.1 Extract MongoDB and makeline-service manifests

App source repo එකේ full manifest එකෙන් MongoDB සහ makeline-service resources extract කරනවා.

```bash
cd "$GITOPS_REPO"

python3 - <<'EXTRACT_MONGO_MAKELINE'
from pathlib import Path
import os
import re

app_repo = Path(os.environ["APP_REPO"])
gitops_repo = Path(os.environ["GITOPS_REPO"])

src = app_repo / "aks-store-all-in-one.yaml"
out = gitops_repo / "apps/capstone-store/base/makeline-mongodb.yaml"

text = src.read_text()
docs = re.split(r"\n---\s*\n", text)

wanted = {
    ("StatefulSet", "mongodb"),
    ("Service", "mongodb"),
    ("Deployment", "makeline-service"),
    ("Service", "makeline-service"),
}

selected = []

for doc in docs:
    kind_match = re.search(r"(?m)^kind:\s*(\S+)\s*$", doc)
    name_match = re.search(r"(?m)^metadata:\s*\n(?:[^\n]*\n)*?\s{2}name:\s*([A-Za-z0-9-]+)\s*$", doc)

    if not kind_match or not name_match:
        continue

    kind = kind_match.group(1)
    name = name_match.group(1)

    if (kind, name) in wanted:
        selected.append(doc.strip())

if len(selected) != 4:
    raise SystemExit(f"Expected 4 resources, found {len(selected)}")

out.write_text("---\n" + "\n---\n".join(selected) + "\n")
print(f"Wrote {len(selected)} resources to {out}")
EXTRACT_MONGO_MAKELINE
```

### 1.2 Update base kustomization

```bash
cd "$GITOPS_REPO"

cat > apps/capstone-store/base/kustomization.yaml <<'EOF_KUSTOMIZE'
resources:
  - aks-store-quickstart.yaml
  - makeline-mongodb.yaml
EOF_KUSTOMIZE
```

### 1.3 Validate Kustomize output

මෙම command එක **GitOps repo** එකේ run කරන්න ඕන.

```bash
cd "$GITOPS_REPO"

kubectl kustomize apps/capstone-store/overlays/dev | grep -nE 'kind: StatefulSet|kind: Deployment|kind: Service|name: mongodb|name: makeline-service|ORDER_DB_URI|ORDER_QUEUE_URI|image:|containerPort:|type: ClusterIP' -A10 | head -220
```

### 1.4 Commit and push GitOps change

```bash
cd "$GITOPS_REPO"

git status --short

git add apps/capstone-store/base/kustomization.yaml \
  apps/capstone-store/base/makeline-mongodb.yaml

git commit -m "Add MongoDB and makeline service to dev workload"
git push
```

### 1.5 Sync Argo CD application

```bash
kubectl annotate application capstone-store-dev -n argocd \
  argocd.argoproj.io/refresh=hard \
  --overwrite

kubectl patch application capstone-store-dev -n argocd --type merge \
  -p '{"operation":{"sync":{"revision":"main"}}}'
```

---

## Part 2 - Verify the issue

### 2.1 Check Argo CD and pods

```bash
kubectl get application capstone-store-dev -n argocd -o wide
kubectl get all -n capstone-dev
```

Possible issue:

```text
capstone-store-dev   Synced   Progressing
mongodb-0            Pending
makeline-service     CrashLoopBackOff
```

Important:

```text
Argo CD Synced = Git desired state cluster එකට apply වෙලා
Argo CD Progressing = workload health තව ready නැහැ
```

### 2.2 Check MongoDB pod details

```bash
kubectl describe pod mongodb-0 -n capstone-dev
```

Observed event:

```text
0/2 nodes are available:
1 Too many pods,
1 node(s) had untolerated taint(s)
```

Meaning:

- system node එක critical system workloads සඳහා tainted
- app pods system node එකට schedule වෙන්නේ නැහැ
- user node එකේ pod capacity full
- MongoDB schedule වෙන්න තැනක් නැහැ

### 2.3 Check makeline-service

```bash
kubectl describe pod -n capstone-dev -l app=makeline-service | tail -180

kubectl logs -n capstone-dev deployment/makeline-service --tail=120 || true
kubectl logs -n capstone-dev deployment/makeline-service --previous --tail=120 || true
```

makeline-service MongoDB connect වෙන්න try කරනවා. MongoDB Pending නිසා service එක Ready වෙන්නේ නැහැ.

---

## Part 3 - Check Azure quota before scaling

### 3.1 Check current node pools

```bash
az aks nodepool list \
  --cluster-name aks-capstone-ae-001 \
  --resource-group rg-aks-capstone-ae-001 \
  --query '[].{name:name,count:count,minCount:minCount,maxCount:maxCount,vmSize:vmSize,mode:mode,enableAutoScaling:enableAutoScaling,powerState:powerState.code}' \
  -o table
```

Initial node pools:

```text
system  Standard_D2s_v5  count 1
user    Standard_D2s_v5  count 1
```

### 3.2 Try scaling user node pool

If cluster autoscaler is enabled, this command can fail:

```bash
az aks nodepool scale \
  --resource-group rg-aks-capstone-ae-001 \
  --cluster-name aks-capstone-ae-001 \
  --name user \
  --node-count 2
```

Observed error:

```text
Cannot scale cluster autoscaler enabled node pool.
```

Correct method is updating autoscaler min/max:

```bash
az aks nodepool update \
  --resource-group rg-aks-capstone-ae-001 \
  --cluster-name aks-capstone-ae-001 \
  --name user \
  --update-cluster-autoscaler \
  --min-count 2 \
  --max-count 2
```

But in Free Trial this can fail with quota issue:

```text
ErrCode_InsufficientVCPUQuota
left regional vcpu quota 0
```

### 3.3 Check quota

```bash
az vm list-usage \
  --location australiaeast \
  --query "[?name.localizedValue=='Total Regional vCPUs' || name.localizedValue=='Standard DSv5 Family vCPUs'].{name:name.localizedValue,current:currentValue,limit:limit}" \
  -o table
```

Free Trial situation:

```text
Total Regional vCPUs        4 / 4
Standard DSv5 Family vCPUs  4 / 4
```

Meaning:

- current cluster already uses 4 vCPU
- another node cannot be added
- full capstone cannot run comfortably with default free trial quota

---

## Part 4 - Azure Free Account to Pay-As-You-Go

### 4.1 Why upgrade?

Azure Free Account can start this project. But default Free Trial quota can be too small for the full capstone.

Full capstone includes AKS, Argo CD, Gateway API, NGINX Gateway Fabric, monitoring, OpenTelemetry, app workloads, MongoDB, RabbitMQ, and future AIOps components.

Recommended minimum for full practical setup:

```text
6 vCPU = workable
8 vCPU = better
10+ vCPU = comfortable
```

### 4.2 Upgrade instruction for learners

In Azure Portal:

```text
Subscriptions
→ Free Trial subscription
→ Upgrade
→ Select Basic - Included support plan
→ Do not select paid support plans
→ Upgrade to Pay-As-You-Go
```

Important:

- Pay-As-You-Go does not mean unlimited free usage
- remaining free credit can still apply during the credit period
- after credit is used or expired, running resources can charge the payment card
- users must set budget alerts before continuing

### 4.3 Create cost guardrails

In Azure Portal:

```text
Cost Management + Billing
→ Cost Management
→ Budgets
→ Add
```

Recommended budget:

```text
Monthly budget: 50 USD
```

Recommended alerts:

Actual cost:

- 50%
- 75%
- 90%
- 100%

Forecasted cost:

- 50%
- 75%
- 100%

Important:

```text
Budget alerts do not stop resources automatically.
They only send email alerts.
Users must still clean up resources manually.
```

---

## Part 5 - Check quota after Pay-As-You-Go upgrade

After upgrade, check quota again:

```bash
az vm list-usage \
  --location australiaeast \
  --query "[?name.localizedValue=='Total Regional vCPUs' || name.localizedValue=='Standard DSv5 Family vCPUs' || name.localizedValue=='Standard BS Family vCPUs' || name.localizedValue=='Standard Dv4 Family vCPUs' || name.localizedValue=='Standard Dv5 Family vCPUs'].{name:name.localizedValue,current:currentValue,limit:limit}" \
  -o table
```

Observed after upgrade:

```text
Total Regional vCPUs        current 4  limit 10
Standard DSv5 Family vCPUs  current 4  limit 0
Standard BS Family vCPUs    current 0  limit 10
Standard Dv4 Family vCPUs   current 0  limit 10
Standard Dv5 Family vCPUs   current 0  limit 0
```

Important lesson:

```text
Total regional quota alone is not enough.
You must also check VM family quota.
```

In this project, DSv5 was already used, B2ms was not allowed, Bsv2 quota was 0, Dv4 family had quota, therefore `Standard_D2_v4` was selected.

---

## Part 6 - Select correct VM size

### 6.1 B2ms attempt

We first tried:

```bash
az aks nodepool add \
  --resource-group rg-aks-capstone-ae-001 \
  --cluster-name aks-capstone-ae-001 \
  --name apps \
  --node-vm-size Standard_B2ms \
  --node-count 1 \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 2 \
  --mode User \
  --labels workload=apps project=aks-capstone
```

Observed error:

```text
The VM size of Standard_B2ms is not allowed in your subscription in location 'australiaeast'
```

### 6.2 Check D-series family quota

```bash
az vm list-usage \
  --location australiaeast \
  --query "[?name.localizedValue=='Total Regional vCPUs' || name.localizedValue=='Standard Dv5 Family vCPUs' || name.localizedValue=='Standard Dv4 Family vCPUs' || name.localizedValue=='Standard D Family vCPUs' || name.localizedValue=='Standard DSv5 Family vCPUs'].{name:name.localizedValue,current:currentValue,limit:limit}" \
  -o table
```

Result:

```text
Standard DSv5 Family vCPUs  current 4  limit 0
Total Regional vCPUs        current 4  limit 10
Standard D Family vCPUs     current 0  limit 10
Standard Dv4 Family vCPUs   current 0  limit 10
Standard Dv5 Family vCPUs   current 0  limit 0
```

Decision:

```text
Use Standard_D2_v4 for apps node pool.
Avoid Standard_D2s_v5 for new pools.
Avoid Standard_D2_v5 because Dv5 family limit is 0.
```

---

## Part 7 - Add apps node pool

### 7.1 Add apps node pool using CLI

```bash
az aks nodepool add \
  --resource-group rg-aks-capstone-ae-001 \
  --cluster-name aks-capstone-ae-001 \
  --name apps \
  --node-vm-size Standard_D2_v4 \
  --node-count 1 \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 2 \
  --mode User \
  --labels workload=apps project=aks-capstone
```

Watch nodes:

```bash
kubectl get nodes -w
```

Expected node pool:

```text
apps   Standard_D2_v4   User   Running
```

### 7.2 Verify node pools

```bash
az aks nodepool list \
  --cluster-name aks-capstone-ae-001 \
  --resource-group rg-aks-capstone-ae-001 \
  --query '[].{name:name,count:count,minCount:minCount,maxCount:maxCount,vmSize:vmSize,mode:mode,powerState:powerState.code}' \
  -o table
```

Expected:

```text
system  1  Standard_D2s_v5
user    1  Standard_D2s_v5
apps    1  Standard_D2_v4
```

---

## Part 8 - Verify application after apps node pool

### 8.1 Check dev pods

```bash
kubectl get pods -n capstone-dev -o wide
```

Expected:

```text
mongodb-0            1/1 Running
makeline-service     1/1 Running
order-service        1/1 Running
product-service      1/1 Running
rabbitmq             1/1 Running
store-front          1/1 Running
```

MongoDB should schedule on apps node:

```text
mongodb-0   aks-apps-xxxxx
```

### 8.2 Check Argo CD

```bash
kubectl get application capstone-store-dev -n argocd -o wide
```

Expected:

```text
capstone-store-dev   Synced   Healthy
```

### 8.3 Test Gateway

```bash
GATEWAY_IP="$(kubectl get gateway platform-gateway -n platform-gateway -o jsonpath='{.status.addresses[0].value}')"
echo "Open in browser: http://$GATEWAY_IP"
curl -I "http://$GATEWAY_IP"
```

Expected:

```text
HTTP/1.1 200 OK
```

---

## Part 9 - Terraform drift problem

### 9.1 Why Terraform drift happened

Apps node pool was created manually using Azure CLI. But the AKS platform is managed by Terraform.

So after CLI creation:

```text
Azure knows about apps node pool.
Terraform config does not know about apps node pool.
Terraform state does not know about apps node pool.
```

This is infrastructure drift.

Production rule:

```text
Manual cloud changes must be added back into Terraform config and state.
```

### 9.2 Add apps node pool support to Terraform module

Module updated:

```text
modules/aks/main.tf
modules/aks/variables.tf
```

Environment updated:

```text
environments/capstone-platform/main.tf
environments/capstone-platform/variables.tf
environments/capstone-platform/terraform.tfvars.example
```

Added variables:

```text
enable_apps_node_pool
apps_node_pool_name
apps_node_vm_size
apps_node_min_count
apps_node_max_count
apps_node_os_disk_size_gb
apps_node_labels
```

Example values:

```hcl
enable_apps_node_pool     = true
apps_node_pool_name       = "apps"
apps_node_vm_size         = "Standard_D2_v4"
apps_node_min_count       = 1
apps_node_max_count       = 2
apps_node_os_disk_size_gb = 128

apps_node_labels = {
  workload = "apps"
  project  = "aks-capstone"
}
```

---

## Part 10 - Terraform import

### 10.1 What is terraform import?

Terraform import does not create a resource.

Terraform import does not delete a resource.

Terraform import maps an existing cloud resource into Terraform state.

In this case:

Existing Azure resource:

```text
AKS cluster: aks-capstone-ae-001
Node pool: apps
```

Terraform resource address:

```text
module.aks.azurerm_kubernetes_cluster_node_pool.apps[0]
```

Import connects those two.

### 10.2 Import command

```bash
cd "$PLATFORM_REPO/environments/capstone-platform"

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

terraform import \
  'module.aks.azurerm_kubernetes_cluster_node_pool.apps[0]' \
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-aks-capstone-ae-001/providers/Microsoft.ContainerService/managedClusters/aks-capstone-ae-001/agentPools/apps"
```

After import, Terraform state knows that this existing Azure node pool belongs to this Terraform resource block.

### 10.3 Plan after import

```bash
terraform plan -out=tfplan-apps-nodepool
```

Important:

```text
If plan shows destroy/recreate, stop.
```

Expected safe result:

```text
Plan: 0 to add, 0 or few to change, 0 to destroy
```

In this project final apply was:

```text
0 added
1 changed
0 destroyed
```

### 10.4 Apply safe plan

```bash
terraform apply "tfplan-apps-nodepool-final"
```

### 10.5 Verify after Terraform apply

```bash
az aks nodepool list \
  --cluster-name aks-capstone-ae-001 \
  --resource-group rg-aks-capstone-ae-001 \
  --query '[].{name:name,count:count,minCount:minCount,maxCount:maxCount,vmSize:vmSize,mode:mode,powerState:powerState.code}' \
  -o table

kubectl get application capstone-store-dev -n argocd -o wide
kubectl get pods -n capstone-dev -o wide
```

Expected:

```text
apps node pool still Running
capstone-store-dev Synced / Healthy
All dev app pods Running
```

---

## Part 11 - Commit Terraform changes

After Terraform apply and verification:

```bash
cd "$PLATFORM_REPO"

git status --short

git add modules/aks/main.tf \
  modules/aks/variables.tf \
  environments/capstone-platform/main.tf \
  environments/capstone-platform/variables.tf \
  environments/capstone-platform/terraform.tfvars.example \
  modules/resource-group/outputs.tf \
  modules/resource-group/variables.tf

git commit -m "Manage capstone apps node pool with Terraform"

git push
```

Do not commit local `terraform.tfvars` if it contains local/private values.

---

## Final result of this stage

Final node pools:

```text
system  Standard_D2s_v5  count 1
user    Standard_D2s_v5  count 1
apps    Standard_D2_v4   count 1
```

Final app status:

```text
capstone-store-dev   Synced / Healthy
mongodb              1/1 Running
makeline-service     1/1 Running
store-front          1/1 Running
```

Gateway:

```text
HTTP/1.1 200 OK
```

---

## Production meaning

This stage demonstrates a real platform engineering scenario:

1. A new app dependency was added.
2. The workload failed because of cluster capacity.
3. The issue was diagnosed using Kubernetes events.
4. Azure quota limitations were identified.
5. Subscription was upgraded safely with budget guardrails.
6. VM family quota was checked.
7. Correct node pool size was selected.
8. Additional node pool was added.
9. App health recovered.
10. Manual cloud resource was imported into Terraform.
11. Terraform became the source of truth again.

This is exactly how infrastructure should be handled in a production-style platform project.
