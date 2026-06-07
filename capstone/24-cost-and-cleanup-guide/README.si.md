# Stage 24 - Cost and Cleanup Guide

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී AKS Capstone project එක run කරන විට Azure cost control කරන්නේ කොහොමද, unnecessary resources identify කරන්නේ කොහොමද, සහ lab/project work අවසන් වූ පසු safe cleanup කරන්නේ කොහොමද කියලා බලනවා.

මෙය production-style platform project එකකට ඉතා වැදගත් stage එකක්. Platform එක deploy කිරීම පමණක් ප්‍රමාණවත් නැහැ. Cloud cost, unused resources, public exposure, cleanup risk, සහ Terraform state safety වගේ දේවල් හරියට manage කරන්නත් platform engineer කෙනෙකුට දැනගන්න ඕන.

## ඇයි මේ stage එක වැදගත්?

Cloud environment එකක resource එකක් create කිරීම ලේසියි. නමුත් ඒ resource එක delete නොකර තබාගත්තොත් cost දිගටම generate වෙනවා.

AKS cluster එකක් run වෙද්දී cost එන්න පුළුවන් ප්‍රධාන තැන් කිහිපයක් තියෙනවා:

- AKS node pools වල virtual machines
- Load Balancer public IP resources
- Azure Container Registry
- Storage accounts
- Log Analytics / monitoring data
- Managed disks
- NAT Gateway හෝ වෙනත් networking resources
- Key Vault, DNS, certificates වගේ supporting services

ඒ නිසා project එක build කරන තරම්ම project එක responsibly stop/cleanup කරන එකත් වැදගත්.

## මේ stage එකෙන් ඉගෙනගන්න දේවල්

- Azure cost guardrail එකක් project එකට අවශ්‍ය ඇයි කියලා
- Pay-As-You-Go account එකක් use කරන විට සැලකිලිමත් විය යුතු දේවල්
- AKS cost වැඩි කරන common resources
- Public IP සහ LoadBalancer services avoid කරන හේතුව
- Terraform destroy කිරීමට පෙර check කළ යුතු දේවල්
- GitOps applications cleanup කිරීමේ safe order එක
- Monitoring සහ local UI access stop කිරීම
- Final cleanup checklist එකක් follow කරන ආකාරය

## Cost guardrail කියන්නේ මොකක්ද?

Cost guardrail කියන්නේ cloud bill එක unexpected විදිහට වැඩි නොවෙන්න දාගන්න protection layer එකක්.

මේ project එකේදී recommended guardrail එක වන්නේ Azure Budget එකක් configure කරලා alerts enable කිරීමයි.

උදාහරණයක් ලෙස:

- Monthly budget: 50 USD වගේ learning limit එකක්
- Actual cost alerts: 50%, 75%, 90%, 100%
- Forecasted cost alerts: 50%, 75%, 100%

මෙය cost stop කරන mechanism එකක් නෙවෙයි. නමුත් cost වැඩි වෙන්න පටන් ගන්න විට email alert එකක් ලැබෙන නිසා early action ගන්න පුළුවන්.

## Cost reduce කරන්න මේ project එකේ ගත්ත design decisions

මෙම capstone project එක learning environment එකක් නිසා cost-aware design decisions කිහිපයක් භාවිතා කරලා තියෙනවා.

### 1. QA සහ Prod store-front services ClusterIP කරලා තියෙනවා

QA සහ Prod environments වල store-front Service type එක ClusterIP ලෙස තියෙනවා. එයින් unnecessary external LoadBalancer public IPs create වීම වැළැක්වෙනවා.

Learning environment එකක every environment එකට public endpoint එකක් දෙන්න අවශ්‍ය නැහැ. Public exposure වැඩි වුණොත් cost සහ security risk දෙකම වැඩි වෙනවා.

### 2. Local UI access use කරනවා

Grafana, Prometheus, Alertmanager, සහ AIOps Dashboard වගේ tools public internet එකට expose නොකර localhost port-forwarding හරහා access කරනවා.

මෙය learning environment එකකට safer සහ cheaper approach එකක්.

### 3. Node pool size සීමා කරලා තියෙනවා

AKS node pools minimum count අඩුවෙන් තබාගෙන autoscaling limits controlled විදිහට configure කරනවා.

Production environment එකක high availability වෙනුවෙන් nodes වැඩියෙන් තියෙන්න පුළුවන්. නමුත් learning project එකකදී unnecessary nodes cost එක වැඩි කරනවා.

### 4. Terraform state separate storage එකක තියෙනවා

Terraform state backend එක separate storage account එකක තියෙනවා. මේක platform resources manage කිරීමේදී important.

State file එක delete වුණොත් Terraform resource ownership confuse වෙන්න පුළුවන්. ඒ නිසා backend storage cleanup කිරීම අවසානයේදී පමණක් සලකා බලන්න ඕන.

## Daily cost check commands

Azure Portal එකෙන් Cost Management + Billing section එකට ගිහින් subscription cost බලන්න පුළුවන්.

CLI වලින් subscription details check කරන්න:

```bash
az account show --output table
```

Resource groups list කරන්න:

```bash
az group list --output table
```

AKS cluster resource group එක identify කරන්න:

```bash
az aks list --output table
```

ACR list කරන්න:

```bash
az acr list --output table
```

Public IP resources check කරන්න:

```bash
az network public-ip list --output table
```

Load balancers check කරන්න:

```bash
az network lb list --output table
```

Managed disks check කරන්න:

```bash
az disk list --output table
```

මෙම commands වලින් cost generate කරන major resources identify කරගන්න පුළුවන්.

## Kubernetes side cleanup checks

Cluster එක තුළ namespaces check කරන්න:

```bash
kubectl get ns
```

Capstone namespaces check කරන්න:

```bash
kubectl get ns | grep capstone
```

Argo CD applications check කරන්න:

```bash
kubectl get applications -n argocd
```

All workloads status check කරන්න:

```bash
kubectl get pods -A
```

Services check කරන්න:

```bash
kubectl get svc -A
```

External IP තියෙන services විශේෂයෙන් check කරන්න:

```bash
kubectl get svc -A | grep LoadBalancer
```

Learning environment එකක unexpected LoadBalancer services තිබුණොත් ඒවා cost සහ exposure දෙකම වැඩි කළ හැකියි.

## Local UI sessions stop කිරීම

Stage 20 සිට local UI helper scripts භාවිතා කරලා Grafana, Prometheus, Alertmanager, සහ AIOps Dashboard localhost හරහා access කරනවා.

වැඩ අවසන් වූ පසු local port-forward sessions stop කරන්න:

```bash
./scripts/local-ui/stop-local-uis.sh
```

Status check කරන්න:

```bash
./scripts/local-ui/status-local-uis.sh
```

මෙය Azure cost reduce කරන දෙයක් නොවෙයි. නමුත් local machine එකේ background port-forward processes clean කරගන්න වැදගත්.

## GitOps cleanup order

GitOps managed platform එකක් cleanup කරන විට random delete කිරීම හොඳ practice එකක් නෙවෙයි.

Recommended safe order එක:

1. Demo traffic සහ local UI sessions stop කරන්න
2. Argo CD applications health check කරන්න
3. Application workloads remove කිරීමට පෙර GitOps desired state understand කරන්න
4. Non-critical demo applications remove කරන්න
5. Environment applications remove කරන්න
6. Platform add-ons remove කරන්න
7. Terraform managed infrastructure destroy කරන්න

මෙම order එකෙන් dependency issues සහ orphan resources අඩු කරගන්න පුළුවන්.

## Terraform destroy කිරීමට පෙර checklist

Terraform destroy කිරීම destructive action එකක්. ඒ නිසා destroy කිරීමට පෙර පහත දේවල් verify කරන්න.

- ඔබ නිවැරදි Azure subscription එකේද?
- ඔබ නිවැරදි Terraform root folder එකේද?
- Terraform backend access තියෙනවද?
- Git working tree clean ද?
- අවශ්‍ය screenshots, proof, notes save කරලා තියෙනවද?
- Public repo එකට secrets, private paths, live IPs commit කරලා නැද්ද?
- Cluster එක delete කිරීමෙන් පසු නැවත create කිරීමට අවශ්‍ය docs තියෙනවද?

Subscription check:

```bash
az account show --output table
```

Terraform state check:

```bash
terraform state list
```

Destroy plan එක බලන්න:

```bash
terraform plan -destroy
```

Destroy apply කරන්න අවශ්‍ය නම් පමණක්:

```bash
terraform destroy
```

Production environment එකකදී direct destroy කිරීම policy approval එකක් නැතුව කරන්න හොඳ නැහැ. මේ project එක learning environment එකක් නිසා destroy command එක document කරනවා.

## Terraform backend storage ගැන සැලකිලිමත් වීම

Terraform state backend storage account එක infrastructure management සඳහා critical.

Cluster resources destroy කළ පසුවත් backend storage එක තවදුරටත් තිබිය හැකියි.

Backend storage delete කිරීමට පෙර:

- State file backup අවශ්‍යද කියලා බලන්න
- නැවත deploy කරන්න plan එකක් තියෙනවද කියලා බලන්න
- Same project continue කරනවා නම් backend delete නොකර තබාගන්න
- Project එක permanently close කරනවා නම් පමණක් backend cleanup සලකා බලන්න

Terraform backend delete කිරීම ගැන careful විය යුතුයි. State නැති වුණොත් future Terraform management අවුල් විය හැකියි.

## ACR cleanup

Azure Container Registry එකේ old image tags වැඩි වුණොත් storage cost වැඩි වෙන්න පුළුවන්.

Repositories list කරන්න:

```bash
az acr repository list --name <acr-name> --output table
```

store-front tags list කරන්න:

```bash
az acr repository show-tags --name <acr-name> --repository store-front --output table
```

Old tag එකක් delete කරන්න අවශ්‍ය නම්:

```bash
az acr repository delete --name <acr-name> --image store-front:<tag> --yes
```

Important: Current Dev, QA, Prod environments use කරන image tag delete කරන්න එපා.

## Monitoring data cost

Monitoring stack එක Kubernetes තුළ run වෙන Prometheus/Grafana based setup එකක් වුණත් Azure side එකේ Log Analytics හෝ managed monitoring enabled නම් data ingestion cost ඇති විය හැකියි.

Monitoring cost reduce කරන්න:

- unnecessary verbose logs avoid කරන්න
- retention period learning environment එකට ගැළපෙන ලෙස තබාගන්න
- unused dashboards සහ test workloads remove කරන්න
- load testing unnecessary ලෙස දිගට run නොකරන්න

Stage 22 load test එක proof සඳහා short duration එකක් පමණක් run කළා. Long-running load tests learning account එකක avoid කරන්න.

## Public exposure cleanup

Public exposure තියෙන resources check කිරීම security සහ cost දෙකටම වැදගත්.

Public IPs:

```bash
az network public-ip list --output table
```

Kubernetes LoadBalancer services:

```bash
kubectl get svc -A | grep LoadBalancer
```

Gateway resources:

```bash
kubectl get gateway -A
```

HTTPRoutes:

```bash
kubectl get httproute -A
```

Learning environment එකකදී only required public entry point එක තබාගෙන අනෙක් internal services ClusterIP ලෙස තබාගන්න.

## Safe pause checklist

Project එක delete නොකර pause කරනවා නම් පහත checklist එක follow කරන්න.

- Local UI port-forwards stop කළා
- Unexpected LoadBalancer services නැහැ
- Argo CD apps Synced/Healthy
- Store-front deployment healthy
- No active incident alerts
- No long-running load tests
- Azure budget alerts active
- Git repos clean and pushed

Commands:

```bash
./scripts/local-ui/stop-local-uis.sh
kubectl get applications -n argocd
kubectl get svc -A | grep LoadBalancer
kubectl get pods -A
git status
```

## Full cleanup checklist

Project environment එක completely cleanup කරනවා නම් පහත high-level checklist එක use කරන්න.

1. Final proof screenshots සහ notes save කරන්න
2. Git repos clean and pushed බව verify කරන්න
3. Local UI sessions stop කරන්න
4. Kubernetes workloads සහ Argo CD apps status check කරන්න
5. Terraform root folder එකට යන්න
6. Correct Azure subscription verify කරන්න
7. `terraform plan -destroy` run කරලා review කරන්න
8. Only if safe, `terraform destroy` run කරන්න
9. Azure Portal එකෙන් resource groups, public IPs, disks, ACR, storage accounts verify කරන්න
10. Budget alerts keep කරනවාද remove කරනවාද decide කරන්න

## Common mistakes

### Mistake 1: Cluster delete කළා, නමුත් disks හෝ public IPs ඉතුරු වුණා

මෙය cost continue වීමට හේතු විය හැකියි. Azure resource list එකෙන් orphan resources check කරන්න.

### Mistake 2: Current image tag එක ACR එකෙන් delete කළා

එවිට deployment image pull fail වෙන්න පුළුවන්. Dev/QA/Prod use කරන tag delete කරන්න එපා.

### Mistake 3: Terraform state backend එක ඉක්මනින් delete කළා

State නැති වුණොත් future infrastructure management අමාරු වෙනවා.

### Mistake 4: LoadBalancer services accidentally create වුණා

Service type එක ClusterIP විය යුතු තැන LoadBalancer වුණොත් public IP සහ cost create වෙන්න පුළුවන්.

### Mistake 5: Load test දිගටම run කළා

Learning environment එකක load tests short and controlled විය යුතුයි.

## Real-world meaning

Production platform engineer කෙනෙකුට infrastructure deploy කිරීම පමණක් නෙවෙයි, cost, cleanup, security exposure, and lifecycle management ගැනත් වගකීමක් තියෙනවා.

මෙම stage එකෙන් project එක responsible cloud engineering practice එකකට complete කරයි.

මෙය interview එකකදී explain කළ හැකි strong point එකක්:

> I built an AKS GitOps platform and also documented cost guardrails, safe cleanup order, Terraform destroy safety, public exposure checks, ACR cleanup, and operational pause procedures.

## Stage 24 outcome

මෙම stage එක අවසන් වූ විට:

- AKS Capstone project එකට cost and cleanup guide එකක් තියෙනවා
- Learnersට Azure cost risk understand කරන්න පුළුවන්
- Cleanup කිරීමට safe order එකක් තියෙනවා
- Terraform destroy කිරීමට පෙර checklist එකක් තියෙනවා
- Public exposure සහ unused resources check කරන commands තියෙනවා
- Project එක pause කරන විට සහ completely cleanup කරන විට follow කළ හැකි process එකක් තියෙනවා

මෙයින් AKS Capstone project එක technical implementation එකකට අමතරව responsible cloud platform project එකක් බව පෙන්වයි.
