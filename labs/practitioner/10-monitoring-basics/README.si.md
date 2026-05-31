# Practitioner Lab 10 - Monitoring Basics

මෙම lab එකෙන් AKS cluster එකක basic monitoring සහ observability signals inspect කරන විදිය ඉගෙන ගන්නවා.

මෙම lab එක focus කරන්නේ AKS operator කෙනෙක් දැනගන්න ඕන practical checks වලට:

- Node සහ pod metrics
- System pod health
- Kubernetes events
- In-cluster Prometheus සහ Grafana discovery
- Azure Monitor / Container Insights status
- Monitoring install වෙලා නැත්නම් optional setup steps
- Cleanup steps

මෙම lab එකට අලුත් application deployment එකක් අවශ්‍ය නැහැ.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- AKS cluster health check කරන විදිය
- Node සහ pod metrics බලන්න `kubectl top` use කරන විදිය
- metrics-server වැඩ කරනවද verify කරන විදිය
- kube-system pods inspect කරන විදිය
- recent Kubernetes events inspect කරන විදිය
- Prometheus සහ Grafana install වෙලා තියෙනවද check කරන විදිය
- port-forward use කරලා Grafana locally access කරන විදිය
- port-forward use කරලා Prometheus locally access කරන විදිය
- Azure Monitor / Container Insights enabled ද check කරන විදිය
- In-cluster monitoring missing නම් install කරන විදිය
- Optional monitoring resources clean up කරන විදිය

## Architecture

මෙම lab එක monitoring approaches දෙකක් cover කරනවා.

In-cluster monitoring:

    AKS cluster
      |
      v
    metrics-server
      |
      v
    kubectl top

    AKS cluster
      |
      v
    Prometheus
      |
      v
    Grafana

Optional Azure-native monitoring:

    AKS cluster
      |
      v
    Azure Monitor agent
      |
      v
    Log Analytics workspace
      |
      v
    Container Insights

Default lab path එක Kubernetes සහ in-cluster monitoring checks use කරනවා.

Azure Monitor / Container Insights optional. ඒක Azure resources create හෝ use කරන්න පුළුවන් නිසා cost add වෙන්න පුළුවන්.

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- Azure CLI
- kubectl
- Helm
- Existing AKS cluster
- AKS cluster access
- AKS cluster details list කරන්න permission
- Optional Helm charts install කරන්න permission
- Optional Azure Monitor addon enable කරන්න permission

Azure සහ Kubernetes access check කරන්න:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl get nodes

## Lab files

මෙම lab එකේ files:

    scripts/
      Monitoring status check කරන්න helper script එක

Files:

    scripts/check-monitoring.sh

## Set lab variables

ඔයාගේ environment එකට values set කරන්න:

    RESOURCE_GROUP="rg-aks-dev-001"
    AKS_NAME="aks-dev-001"
    LOCATION="southeastasia"
    MONITORING_NAMESPACE="monitoring"
    PROMETHEUS_RELEASE="kube-prometheus-stack"

## Verify AKS cluster access

AKS cluster එක check කරන්න:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "{name:name, resourceGroup:resourceGroup, location:location, kubernetesVersion:kubernetesVersion, powerState:powerState.code}" \
      --output table

Current Kubernetes context එක check කරන්න:

    kubectl config current-context

Nodes check කරන්න:

    kubectl get nodes -o wide

Expected result:

    Nodes Ready වෙලා තියෙන්න ඕන.

## Check Kubernetes metrics

Node metrics check කරන්න:

    kubectl top nodes

All namespaces වල pod metrics check කරන්න:

    kubectl top pods --all-namespaces

මේ commands වැඩ කරනවා නම් metrics-server වැඩ කරනවා.

metrics-server check කරන්න:

    kubectl get deployment metrics-server -n kube-system

`kubectl top` වැඩ කරන්නේ නැත්නම්, cluster create කළාට පස්සේ ටික වෙලාවක් wait කරලා metrics-server pods check කරන්න:

    kubectl get pods -n kube-system | grep metrics-server

AKS වල metrics-server සාමාන්‍යයෙන් default install වෙලා තියෙනවා.

## Check system pod health

kube-system pods check කරන්න:

    kubectl get pods -n kube-system

Important system pods සියල්ල Running වෙලා තියෙන්න ඕන.

Wider view එකකට:

    kubectl get pods --all-namespaces

Useful troubleshooting commands:

    kubectl describe pod <pod-name> -n <namespace>
    kubectl logs <pod-name> -n <namespace>

Pod එකේ containers කිහිපයක් තියෙනවා නම්:

    kubectl logs <pod-name> -n <namespace> -c <container-name>

## Check recent Kubernetes events

Recent events check කරන්න:

    kubectl get events --all-namespaces --sort-by=.lastTimestamp | tail -20

Events වලින් scheduling issues, image pull issues, probe failures, volume mount issues, permission problems වගේ දේවල් identify කරන්න පුළුවන්.

එක namespace එකක් විතරක් inspect කරන්න:

    kubectl get events -n <namespace> --sort-by=.lastTimestamp

## Check if in-cluster monitoring exists

Monitoring namespace එක check කරන්න:

    kubectl get ns "$MONITORING_NAMESPACE"

Monitoring pods check කරන්න:

    kubectl get pods -n "$MONITORING_NAMESPACE"

Monitoring services check කරන්න:

    kubectl get svc -n "$MONITORING_NAMESPACE"

Helm releases check කරන්න:

    helm list -n "$MONITORING_NAMESPACE"

`kube-prometheus-stack` release එකක් දැක්කොත්, සාමාන්‍යයෙන් Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter install වෙලා තියෙනවා.

## If missing: install kube-prometheus-stack

Monitoring namespace එක හෝ Helm release එක නැත්නම්, kube-prometheus-stack install කරන්න.

Helm repo එක add කරන්න:

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

Namespace එක create කරන්න:

    kubectl create namespace "$MONITORING_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kube-prometheus-stack install කරන්න:

    helm upgrade --install "$PROMETHEUS_RELEASE" prometheus-community/kube-prometheus-stack \
      --namespace "$MONITORING_NAMESPACE"

Verify කරන්න:

    kubectl get pods -n "$MONITORING_NAMESPACE"
    kubectl get svc -n "$MONITORING_NAMESPACE"
    helm list -n "$MONITORING_NAMESPACE"

මේක complete වෙන්න minutes කිහිපයක් යන්න පුළුවන්.

## Access Grafana locally

Grafana admin password එක ගන්න:

    kubectl get secret \
      --namespace "$MONITORING_NAMESPACE" \
      "${PROMETHEUS_RELEASE}-grafana" \
      -o jsonpath="{.data.admin-password}" | base64 --decode; echo

Grafana port-forward කරන්න:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-grafana \
      3000:80

Grafana locally open කරන්න:

    http://localhost:3000

Default username:

    admin

Secret command එකෙන් ගත්ත password එක use කරන්න.

Port-forward stop කරන්න:

    Ctrl+C

## Access Prometheus locally

Prometheus port-forward කරන්න:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-prometheus \
      9090:9090

Prometheus locally open කරන්න:

    http://localhost:9090

Example Prometheus queries:

    up
    node_cpu_seconds_total
    kube_pod_info

Port-forward stop කරන්න:

    Ctrl+C

## Check Azure Monitor / Container Insights

Azure Monitor addon status එක check කරන්න:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.omsagent" \
      --output json

Output එක empty හෝ null නම්, Azure Monitor addon එක enabled නෙවෙයි.

ඒකෙන් cluster එකේ monitoring නැහැ කියන එක අදහස් වෙන්නේ නෑ. ඒකෙන් අදහස් වෙන්නේ Azure-native Container Insights AKS addon එක enabled නැහැ කියන එක විතරයි.

## Optional: enable Azure Monitor / Container Insights

Azure-native monitoring අවශ්‍ය නම් විතරක් මෙය use කරන්න.

මෙය Log Analytics workspace එකක් create හෝ use කරන්න පුළුවන්. Azure cost add වෙන්න පුළුවන්.

Monitoring addon එක enable කරන්න:

    az aks enable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons monitoring

Verify කරන්න:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.omsagent" \
      --output json

Resource group එකේ Log Analytics workspaces list කරන්න:

    az monitor log-analytics workspace list \
      --resource-group "$RESOURCE_GROUP" \
      --query "[].{name:name, location:location, resourceGroup:resourceGroup}" \
      --output table

## Run the helper script

Common monitoring checks collect කරන්න helper script එක run කරන්න:

    ./labs/practitioner/10-monitoring-basics/scripts/check-monitoring.sh

Script එක check කරන දේවල්:

- AKS cluster details
- Current Kubernetes context
- Nodes
- Node metrics
- kube-system pods
- metrics-server
- Recent events
- Azure Monitor addon status
- Monitoring namespace
- Monitoring pods
- Monitoring services
- Helm releases

## Cleanup

මෙම lab එකට විතරක් kube-prometheus-stack install කළා නම් සහ තව අවශ්‍ය නැත්නම්, remove කරන්න:

    helm uninstall "$PROMETHEUS_RELEASE" -n "$MONITORING_NAMESPACE"

Monitoring namespace එක delete කරන්න:

    kubectl delete namespace "$MONITORING_NAMESPACE" --ignore-not-found

මෙම lab එකට විතරක් Azure Monitor / Container Insights enable කළා නම් සහ disable කරන්න ඕන නම්:

    az aks disable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons monitoring

Addon status එක නැවත check කරන්න:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.omsagent" \
      --output json

තවත් lab එකක් monitoring stack එක මත depend වෙනවා නම්, ඒක keep කරන්න.

## What you completed

ඔයා check කළා:

- AKS cluster health
- Node readiness
- Node සහ pod metrics
- metrics-server status
- kube-system health
- Kubernetes events
- In-cluster monitoring status
- Grafana local access
- Prometheus local access
- Azure Monitor addon status
- Optional enable සහ cleanup paths

මෙය next practitioner lab එකට cluster එක prepare කරනවා:

    Practitioner Lab 11 - OpenTelemetry App
