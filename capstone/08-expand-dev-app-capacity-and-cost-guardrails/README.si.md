# Stage 08 - Dev App Capacity, Azure Quota, Cost Guardrails, and Terraform Drift Fix

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි Capstone Store dev application එක expand කළාට පස්සේ ආපු real-world capacity issue එක fix කරනවා.

මුලින් app එකේ services ටික වැඩි කළා:

- store-front
- product-service
- order-service
- rabbitmq
- mongodb
- makeline-service

නමුත් cluster එකේ node capacity මදි වුණා. ඒ නිසා MongoDB pod එක Pending වුණා. MongoDB නැතුව makeline-service එකත් හරියට start වෙන්න බැරි වුණා.

මේක production වලට ගොඩක් common problem එකක්.

සරලව කියනවා නම්:

```text
Application එක ලොකු වුණා
        ↓
Pods වැඩි වුණා
        ↓
Current node capacity මදි වුණා
        ↓
MongoDB Pending වුණා
        ↓
Dependent service fail වුණා
        ↓
New node pool එකක් add කරන්න වුණා
        ↓
CLI එකෙන් add කළ node pool එක Terraform වලට import කරන්න වුණා
```

මේ stage එකෙන් අපි ඉගෙන ගන්න ප්‍රධාන දේවල්:

1. Azure Free Trial quota limitation එක production planning වලට බලපාන විදිහ
2. Pay-As-You-Go upgrade එකක් අවශ්‍ය වෙන අවස්ථා
3. Budget guardrail එකක් දාලා cost risk අඩු කරන විදිහ
4. AKS node pool එකක් add කරලා pod capacity issue එක fix කරන විදිහ
5. CLI එකෙන් හදපු resource එක Terraform state එකට import කරලා drift fix කරන විදිහ

---

## මේ stage එක වැදගත් ඇයි?

Kubernetes cluster එකක් හදලා app එක deploy කරන එක විතරක් production engineering නෙවෙයි.

Production වලදී app එක grow වෙනවා. Services වැඩි වෙනවා. Database, queue, background workers, admin UI වගේ components එකතු වෙනවා.

ඒ වෙලාවට cluster එකට ප්‍රශ්න එන්න පුළුවන්:

- pod schedule වෙන්නේ නැහැ
- node වල CPU/memory මදි වෙනවා
- cloud quota මදි වෙනවා
- new VM size එකක් create කරන්න Azure allow කරන්නේ නැහැ
- manually fix කළ resource Terraform වලින් manage නොවෙයි
- Terraform apply එකකදී drift හෝ conflict එන්න පුළුවන්

ඒ නිසා මේ stage එක beginner command lab එකක් නෙවෙයි. මේක real platform engineering lesson එකක්.

---

## Current platform status

මේ stage එකේදී platform එක මේ වගේ status එකක තිබුණා:

```text
Region: australiaeast
Resource group: rg-aks-capstone-ae-001
AKS cluster: aks-capstone-ae-001
ACR: acrakscapstoneae9954.azurecr.io
Key Vault: kv-aks-capstone-ae9954
Gateway external IP: http://20.53.203.159
```

Gateway test එක:

```bash
curl -I http://20.53.203.159
```

Expected result:

```text
HTTP/1.1 200 OK
```

---

## Problem එක මොකක්ද?

Dev app එක expand කළාට පස්සේ MongoDB pod එක Pending වුණා.

Check කරන්න:

```bash
kubectl get pods -n capstone-store-dev -o wide
```

Problem එකේදී MongoDB මේ වගේ පේන්න පුළුවන්:

```text
mongodb   0/1   Pending
```

Pod එක Pending නම් describe කරන්න:

```bash
kubectl describe pod -n capstone-store-dev -l app=mongodb
```

Typical reason එක:

```text
Insufficient cpu
Insufficient memory
No nodes are available that match all of the predicates
```

මෙහි සරල meaning එක:

Cluster එකේ available nodes වල MongoDB pod එක run කරන්න අවශ්‍ය resources නැහැ.

---

## මේක app bug එකක්ද platform capacity issue එකක්ද?

මෙතන වැදගත්ම thinking එක මෙන්න මේකයි.

MongoDB image එක වැරදි නැහැ. Kubernetes manifest එකත් වැරදි නැහැ. Argo CD sync එකත් success වුණා.

නමුත් pod එක schedule වෙන්නේ නැහැ.

ඒ කියන්නේ problem එක app code එකේ නෙවෙයි. Problem එක cluster capacity එකේ.

Production troubleshooting වලදී මේ වෙනස හඳුනාගන්න පුළුවන් වීම ගොඩක් වැදගත්.

```text
App bug:
  Pod start වෙනවා, නමුත් application crash වෙනවා.

Capacity issue:
  Pod start වෙන්නම node එකක් නැහැ.
```

---

## Azure quota check කිරීම

Azure වල VM create කරන්න quota තියෙන්න ඕන.

Free Trial එකේ quota අඩුයි. මේ project එකේදී මුලින් Total Regional vCPU quota එක 4/4 වගේ limit එකකට ගිහින් තිබුණා.

Quota බලන්න:

```bash
az vm list-usage \
  --location australiaeast \
  -o table
```

මේකෙන් region එකේ available vCPU quota බලන්න පුළුවන්.

Specific VM family quota බලන්න:

```bash
az vm list-usage \
  --location australiaeast \
  --query "[?contains(name.localizedValue, 'Dv4') || contains(name.localizedValue, 'DSv5') || contains(name.localizedValue, 'BSv2')]" \
  -o table
```

මේ project එකේදී history එක මෙහෙමයි:

```text
Free Trial:
  Total Regional vCPUs: 4/4
  Capacity insufficient

After Pay-As-You-Go upgrade:
  Total Regional vCPU quota increased to 10

DSv5 family:
  Weird family limit issue තිබුණා

Bsv2 family:
  quota 0

Standard_B2ms:
  allowed නැහැ

Dv4 family:
  available

Final choice:
  Standard_D2_v4
```

---

## Cost guardrail එකක් දාන්නේ ඇයි?

Pay-As-You-Go upgrade කළා කියලා unlimited cost spend කරන්න ඕන කියන එක නෙවෙයි.

Cloud platform engineer කෙනෙක් cluster capacity increase කරනකොට cost safety එකත් බලන්න ඕන.

ඒ නිසා budget guardrail එකක් දාලා තිබුණා:

```text
Monthly budget: 50 USD

Actual alerts:
  50%
  75%
  90%
  100%

Forecasted alerts:
  50%
  75%
  100%
```

සරලව:

```text
Quota නැතුව platform එක run වෙන්නේ නැහැ.
Budget නැතුව platform එක safe නැහැ.
```

---

## Current node pools

Capacity fix එකෙන් පස්සේ node pools මෙහෙමයි:

```text
system:
  VM size: Standard_D2s_v5
  count: 1
  min: 1
  max: 2
  mode: System

user:
  VM size: Standard_D2s_v5
  count: 1
  min: 1
  max: 2
  mode: User

apps:
  VM size: Standard_D2_v4
  count: 1
  min: 1
  max: 2
  mode: User
```

apps node pool එක add කළේ application workloads run කරන්න.

---

## Node pool design එකේ meaning එක

AKS cluster එකක system node pool එක platform/system workloads සඳහා තබාගන්න එක හොඳ practice එකක්.

Example:

```text
system node pool:
  Core Kubernetes / platform components

user node pool:
  General workloads

apps node pool:
  Application-specific workloads
```

මේක production වලදී useful වෙන්නේ:

- app workload එක platform pods වලට disturb නොකරන්න
- scaling policy වෙනම manage කරන්න
- cost control කරන්න
- troubleshooting පහසු කරන්න
- future taints/tolerations හෝ node selectors apply කරන්න

---

## apps node pool එක CLI එකෙන් add කිරීම

Quota issue එක solve වුණාට පස්සේ apps node pool එක add කළා.

Command pattern එක:

```bash
az aks nodepool add \
  --resource-group rg-aks-capstone-ae-001 \
  --cluster-name aks-capstone-ae-001 \
  --name apps \
  --node-count 1 \
  --min-count 1 \
  --max-count 2 \
  --enable-cluster-autoscaler \
  --node-vm-size Standard_D2_v4 \
  --mode User
```

මෙහි meaning එක:

```text
--name apps:
  node pool එකේ නම

--node-count 1:
  initially node එකක් 1

--min-count 1:
  autoscaler minimum node count

--max-count 2:
  autoscaler maximum node count

--enable-cluster-autoscaler:
  demand එක වැඩි වුණොත් node count scale කරන්න

--node-vm-size Standard_D2_v4:
  quota available VM size එක

--mode User:
  application workloads සඳහා user node pool එකක්
```

---

## Node pool එක verify කිරීම

```bash
az aks nodepool list \
  --resource-group rg-aks-capstone-ae-001 \
  --cluster-name aks-capstone-ae-001 \
  -o table
```

Expected idea:

```text
Name     VmSize           Count    Mode
system   Standard_D2s_v5  1        System
user     Standard_D2s_v5  1        User
apps     Standard_D2_v4   1        User
```

Kubernetes nodes බලන්න:

```bash
kubectl get nodes -o wide
```

---

## MongoDB schedule වුණාද බලන්න

```bash
kubectl get pods -n capstone-store-dev -o wide
```

Expected result:

```text
store-front        1/1   Running
product-service    1/1   Running
order-service      1/1   Running
rabbitmq           1/1   Running
makeline-service   1/1   Running
mongodb            1/1   Running
```

MongoDB apps node එකේ run වෙනවාද බලන්න:

```bash
kubectl get pod -n capstone-store-dev -l app=mongodb -o wide
```

---

## Argo CD status check කිරීම

```bash
kubectl get application -n argocd
```

Expected:

```text
capstone-store-dev   Synced   Healthy
```

Argo CD app details බලන්න:

```bash
kubectl describe application capstone-store-dev -n argocd
```

මේ stage එකේදී latest GitOps revision එක:

```text
860377657fa9e8804dae18d9cea30a373761190d
```

---

## Gateway test

Application එක browser හෝ curl වලින් test කරන්න:

```bash
curl -I http://20.53.203.159
```

Expected:

```text
HTTP/1.1 200 OK
```

මේකෙන් අදහස් වෙන්නේ:

```text
User request
  ↓
Gateway external IP
  ↓
HTTPRoute
  ↓
store-front service
  ↓
store-front pod
  ↓
Application response
```

---

## Terraform drift කියන්නේ මොකක්ද?

apps node pool එක මුලින් CLI එකෙන් add කළා.

නමුත් අපේ platform source of truth එක Terraform.

ඒ කියන්නේ resource එක Azure වල තියෙනවා. නමුත් Terraform config/state වල නැත්නම් Terraform ඒක manage කරන්නේ නැහැ.

මේකට කියන්නේ drift.

සරල example:

```text
Azure reality:
  apps node pool exists

Terraform knowledge:
  apps node pool unknown

Problem:
  Terraform is no longer the full source of truth
```

Production වලදී drift dangerous වෙන්නේ:

- future terraform apply එකකදී unexpected changes එන්න පුළුවන්
- team members ට actual platform state එක නොතේරෙන්න පුළුවන්
- auditability අඩු වෙනවා
- disaster recovery අමාරු වෙනවා
- infrastructure documentation mismatch වෙනවා

ඒ නිසා CLI fix එක පස්සේ Terraform import අනිවාර්යයි.

---

## Terraform config එකට apps node pool එක add කිරීම

Terraform module/config එක update කරලා apps node pool එක manage කරන්න.

Conceptually config එකේ apps node pool එක මේ වගේ meaning එකක් තියෙන්න ඕන:

```hcl
apps = {
  name                 = "apps"
  vm_size              = "Standard_D2_v4"
  node_count           = 1
  min_count            = 1
  max_count            = 2
  enable_auto_scaling  = true
  mode                 = "User"
}
```

Actual file structure එක project එකේ module design එකට අනුව වෙනස් වෙන්න පුළුවන්.

වැදගත්ම දේ:

```text
Azure වල තියෙන apps node pool එක
Terraform configuration එකේත් represent වෙන්න ඕන.
```

---

## Terraform import කිරීම

Import command එක resource address එක project Terraform structure එකට අනුව වෙනස් වෙන්න පුළුවන්.

Command pattern එක:

```bash
terraform import \
  '<terraform_resource_address_for_apps_node_pool>' \
  '/subscriptions/<subscription-id>/resourceGroups/rg-aks-capstone-ae-001/providers/Microsoft.ContainerService/managedClusters/aks-capstone-ae-001/agentPools/apps'
```

මෙහි meaning එක:

```text
terraform import:
  Existing Azure resource එක Terraform state එකට connect කරනවා.

resource address:
  Terraform config එකේ resource එකේ address එක.

Azure resource ID:
  Azure වල already තියෙන apps node pool එකේ full ID එක.
```

Import කළා කියලා resource එක create වෙන්නේ නැහැ. ඒක already තියෙන resource එක Terraform state එකට register කරන එක.

---

## Terraform plan කිරීම

Import පස්සේ plan run කරන්න:

```bash
terraform plan
```

Expected idea:

```text
No destructive changes
```

හෝ මේ stage එකේදී වගේ:

```text
0 added, 1 changed, 0 destroyed
```

වැදගත්ම දේ:

```text
destroy වෙන resource නොතිබිය යුතුයි.
```

Plan එකේ unexpected destroy එකක් පේනවා නම් apply කරන්න එපා.

---

## Terraform apply කිරීම

Plan එක safe නම්:

```bash
terraform apply
```

මේ stage එකේදී apply result එක:

```text
0 added, 1 changed, 0 destroyed
```

මෙයින් අදහස් වෙන්නේ:

```text
apps node pool එක දැන් Terraform-managed.
Manual CLI drift එක fix වෙලා.
```

---

## Final verification

Node pools:

```bash
az aks nodepool list \
  --resource-group rg-aks-capstone-ae-001 \
  --cluster-name aks-capstone-ae-001 \
  -o table
```

Pods:

```bash
kubectl get pods -n capstone-store-dev -o wide
```

Argo CD:

```bash
kubectl get application capstone-store-dev -n argocd
```

Gateway:

```bash
curl -I http://20.53.203.159
```

Expected final status:

```text
AKS cluster: Running
Node pools: system, user, apps
MongoDB: Running
makeline-service: Running
Argo CD: Synced / Healthy
Gateway: HTTP 200
Terraform: apps node pool managed
```

---

## Troubleshooting

### Issue 1 - MongoDB pod Pending

Check:

```bash
kubectl describe pod -n capstone-store-dev -l app=mongodb
```

If you see insufficient CPU or memory:

```text
Insufficient cpu
Insufficient memory
```

Meaning:

```text
Cluster capacity is not enough.
```

Fix:

```text
Check quota
Add suitable node pool
Verify pod scheduling
```

---

### Issue 2 - Azure says quota exceeded

Check quota:

```bash
az vm list-usage \
  --location australiaeast \
  -o table
```

Fix options:

```text
Option 1:
  Use available VM family

Option 2:
  Request quota increase

Option 3:
  Upgrade from Free Trial to Pay-As-You-Go

Option 4:
  Reduce node count or VM size
```

---

### Issue 3 - VM size not allowed

If Standard_B2ms or another VM size is not allowed:

```text
The selected VM size is not available or allowed for this subscription/region.
```

Fix:

```text
Choose another VM size with available quota.
```

In this project:

```text
Standard_D2_v4 was used for apps node pool.
```

---

### Issue 4 - Terraform wants to destroy something

If `terraform plan` shows destroy:

```text
Plan: x to add, x to change, x to destroy
```

Do not apply immediately.

Check:

```bash
terraform state list
terraform plan
```

Possible reasons:

```text
Resource address mismatch
Import target wrong
Terraform config does not match Azure reality
Provider default values differ
```

Fix carefully before apply.

---

### Issue 5 - Argo CD OutOfSync

Check:

```bash
kubectl get application capstone-store-dev -n argocd
```

If OutOfSync:

```bash
kubectl describe application capstone-store-dev -n argocd
```

Then check GitOps repo revision and manifests.

---

### Issue 6 - Gateway does not return HTTP 200

Check HTTP response:

```bash
curl -I http://20.53.203.159
```

Check Gateway and routes:

```bash
kubectl get gateway -A
kubectl get httproute -A
kubectl describe httproute -n capstone-store-dev
```

Check store-front service:

```bash
kubectl get svc -n capstone-store-dev
kubectl get endpoints -n capstone-store-dev
```

If service endpoints are empty, selector labels may be wrong or pods may not be ready.

---

## Learner summary

මේ stage එකේදී අපි command ටිකක් run කළා කියන එකට වඩා වැදගත් lesson එකක් ඉගෙන ගත්තා.

Real-world platform engineering flow එක මෙන්න මේකයි:

```text
Application grows
  ↓
Cluster capacity becomes insufficient
  ↓
Pods fail to schedule
  ↓
Cloud quota must be checked
  ↓
Cost guardrails must be added
  ↓
Safe node pool must be selected
  ↓
Application recovers
  ↓
Manual cloud changes must be imported into Terraform
  ↓
Terraform becomes source of truth again
```

මේක production වලදී ගොඩක් වැදගත්.

Good engineer කෙනෙක් incident එක fix කරනවා.

Better platform engineer කෙනෙක් incident එක fix කරලා, cost risk manage කරලා, Terraform drift එකත් clean කරනවා.

---

## Stage 08 completion checklist

- [x] Azure Free Trial limitation understood
- [x] Pay-As-You-Go upgrade completed
- [x] Budget guardrail created
- [x] Azure quota checked
- [x] apps node pool created
- [x] MongoDB scheduled successfully
- [x] makeline-service recovered
- [x] Argo CD app Synced / Healthy
- [x] Gateway returned HTTP 200
- [x] apps node pool imported into Terraform state
- [x] Terraform config updated
- [x] Terraform apply completed without destroy
- [x] apps node pool is now Terraform-managed

---

## Next stage

Next likely stage:

```text
Stage 09 - Add store-admin, virtual-customer, and virtual-worker to dev app
```

Stage 09 එකේදී අපි app එක තව expand කරනවා. ඒකෙන් learner ට microservices application එකක admin UI, simulated customers, and background workers production-style GitOps workflow එකෙන් deploy කරන විදිහ ඉගෙන ගන්න පුළුවන්.
