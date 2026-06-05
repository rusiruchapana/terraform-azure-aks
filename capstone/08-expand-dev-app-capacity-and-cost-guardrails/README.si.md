# Stage 08 - Dev App Expansion, Capacity Planning, and Cost Guardrails

## මේ stage එකේදී මොකක්ද කළේ?

මෙම stage එකේදී අපි Capstone Store dev app එක minimal setup එකෙන් advanced setup එකකට expand කළා.

කලින් dev app එකේ තිබුණේ:

- store-front
- product-service
- order-service
- rabbitmq

මෙම stage එකේදී add කළා:

- mongodb
- makeline-service

මේකෙන් app එක real event-driven workload එකක් වුණා.

Flow එක:

store-front
→ order-service
→ rabbitmq
→ makeline-service
→ mongodb

## ඇයි මේ stage එක වැදගත්?

Minimal app එක Gateway සහ GitOps path prove කරන්න හොඳයි.

නමුත් real-world microservices app එකකට backend dependencies, message queue, database, worker services, capacity planning, and troubleshooting අවශ්‍යයි.

මෙම stage එකෙන් අපි ඉගෙනගත්තේ:

- app එක step by step expand කරන විදිහ
- dependency failure identify කරන විදිහ
- Kubernetes scheduling issue analyze කරන විදිහ
- Azure quota limitation handle කරන විදිහ
- cost guardrails දාගෙන Pay-As-You-Go use කරන විදිහ
- CLI-created resource එක Terraform-managed කරන විදිහ

## Azure Free Account සහ Pay-As-You-Go ගැන වැදගත් දෙයක්

මෙම capstone එක Azure Free Account එකකින් start කරන්න පුළුවන්.

නමුත් Free Trial subscription එකේ default quota එක බොහෝ විට 4 vCPU වගේ අඩු limit එකක්.

AKS cluster එක, Argo CD, Gateway, Monitoring, OpenTelemetry, app workloads, සහ AIOps components ඔක්කොම එකට run කරන්න මේ quota එක ප්‍රමාණවත් නොවෙන්න පුළුවන්.

Recommended approach:

1. Azure Free Account එකක් create කරන්න
2. Subscription එක Pay-As-You-Go වලට upgrade කරන්න
3. Support plan එක Basic - Included ලෙස තියාගන්න
4. Paid support plans select කරන්න එපා
5. Resource deploy කරන්න කලින් Budget එකක් create කරන්න
6. Budget alerts 50%, 75%, 90%, 100% වලට set කරන්න
7. හැම lab session එකකම cost check කරන්න
8. Project එක complete වුණාම resources delete කරන්න

Pay-As-You-Go upgrade කළා කියලා unlimited free usage ලැබෙන්නේ නැහැ.

Remaining free credit තියෙනවා නම් ඒක credit period එක තුළ use වෙන්න පුළුවන්.

Credit ඉවර වුණාට පස්සේ හෝ credit period එක ඉවර වුණාට පස්සේ running resources වල cost එක payment card එකෙන් charge වෙන්න පුළුවන්.

Budget alert එකක් resources automatically stop කරන්නේ නැහැ.

ඒක warning email එකක් විතරයි.

ඒ නිසා cleanup discipline එක අනිවාර්යයි.

## Recommended budget guardrails

Example monthly budget:

    50 USD

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

මෙම project එකේදී budget guardrail එක create කළා:

- Monthly budget: 50 USD
- Alerts: Actual 50/75/90/100
- Alerts: Forecasted 50/75/100

## Quota issue එක

MongoDB add කළාට පස්සේ `mongodb-0` pod එක Pending වුණා.

makeline-service එක MongoDB connect වෙන්න බැරි නිසා CrashLoopBackOff වුණා.

Symptoms:

    mongodb-0 Pending
    makeline-service CrashLoopBackOff
    capstone-store-dev Synced / Progressing

Important event:

    0/2 nodes are available:
    1 Too many pods
    1 node(s) had untolerated taint(s)

Meaning:

- system node එක system workloads සඳහා tainted
- user node එකේ pod capacity full
- MongoDB schedule වෙන්න pod slot එකක් නැහැ
- makeline-service dependency unavailable නිසා crash වෙනවා

## Capacity planning lesson

Full capstone එකට minimum capacity:

- 1 system node
- 2 user/app nodes
- around 6 vCPU minimum

Better:

- 8 to 10 vCPU quota
- app workloads වෙනම node pool එකක run කිරීම

මෙම project එකේ Pay-As-You-Go upgrade පස්සේ Australia East quota:

- Total Regional vCPUs: 10
- current initially: 4

නමුත් VM family limits check කරන්නත් වැදගත්.

DSv5 family limit issue එකක් තිබුණා.

B2ms allowed නැහැ.

Bsv2 quota 0.

Dv4 family quota available.

ඒ නිසා apps node pool එකට selected VM size:

    Standard_D2_v4

## Apps node pool

Application workloads සඳහා additional node pool එකක් add කළා:

    node pool name: apps
    VM size: Standard_D2_v4
    mode: User
    min count: 1
    max count: 2
    autoscaler: enabled
    labels:
      workload=apps
      project=aks-capstone

Final node pools:

    system   Standard_D2s_v5   count 1
    user     Standard_D2s_v5   count 1
    apps     Standard_D2_v4    count 1

MongoDB pod එක apps node එකේ schedule වුණා.

## MongoDB සහ makeline-service expansion

GitOps repo එකේ base manifest එකට resources add කළා:

    apps/capstone-store/base/makeline-mongodb.yaml

Included resources:

- mongodb StatefulSet
- mongodb Service
- makeline-service Deployment
- makeline-service Service

Base kustomization update කළා:

    resources:
      - aks-store-quickstart.yaml
      - makeline-mongodb.yaml

GitOps commit:

    Add MongoDB and makeline service to dev workload

Argo CD app:

    capstone-store-dev

Final status:

    Synced / Healthy

## Final app status

Pods:

    store-front       1/1 Running
    product-service   1/1 Running
    order-service     1/1 Running
    rabbitmq          1/1 Running
    makeline-service  1/1 Running
    mongodb           1/1 Running

Gateway test:

    curl -I http://20.53.203.159

Expected:

    HTTP/1.1 200 OK

## Terraform drift fix

Apps node pool එක මුලින් Azure CLI වලින් create කළා.

ඒ නිසා Terraform state එක ඒ resource එක ගැන දැනගෙන තිබුණේ නැහැ.

Terraform config එකට apps node pool resource block එක add කළා.

ඊට පස්සේ existing Azure node pool එක Terraform state එකට import කළා.

Import meaning එක:

Terraform import resource create කරන්නේ නැහැ.

Terraform import resource delete කරන්නේත් නැහැ.

ඒකෙන් කරන්නේ existing Azure resource එක Terraform state එකට map කරන එක.

Example:

Azure existing resource:

    aks-capstone-ae-001 / agentPools / apps

Terraform resource address:

    module.aks.azurerm_kubernetes_cluster_node_pool.apps[0]

ඉන්පසු Terraform plan/apply කළා.

Final apply:

    0 added
    1 changed
    0 destroyed

මෙයින් apps node pool එක Terraform-managed වුණා.

## Production meaning

මෙම stage එකෙන් අපි real cloud engineering workflow එකක් follow කළා:

1. Application dependency add කළා
2. Kubernetes scheduling issue detect කළා
3. Pod events analyze කළා
4. Azure quota limitation identify කළා
5. Pay-As-You-Go upgrade කළා
6. Budget guardrails set කළා
7. Correct VM family choose කළා
8. Additional node pool add කළා
9. App healthy කළා
10. Manual cloud change එක Terraform state/config වලට align කළා

මේක production-style IaC discipline එකක්.

Manual change එකක් කළාට පස්සේ ඒක Terraform වලට import කරලා manage කළා.

## මේ stage එකෙන් මතක තියාගන්න ඕන දේ

Pods Pending වෙන්නේ image issue එකක් නිසාම නෙවෙයි.

Sometimes root cause එක cluster capacity, taints, pod limits, quota, or node pool design විය හැකියි.

Argo CD Synced වෙලා Progressing නම් Git state apply වෙලා තියෙනවා, නමුත් workload health තව ready නැහැ.

Cloud Engineer කෙනෙක් බලන්න ඕන:

- pod status
- events
- node capacity
- quota
- VM family limits
- autoscaler behavior
- cost guardrails
- Terraform drift
