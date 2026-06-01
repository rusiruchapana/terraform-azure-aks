# Practitioner Lab 10 - Monitoring Basics

මෙම lab එකෙන් AKS cluster එකක basic monitoring සහ observability signals inspect කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone AKS operations lab එකක්.

මෙම lab එක default ලෙස අලුත් application එකක් deploy කරන්නේ නැහැ.

Default lab path එක read-only monitoring checks වලට focus කරනවා:

- Node සහ pod metrics
- metrics-server status
- System pod health
- Kubernetes events
- In-cluster Prometheus සහ Grafana discovery
- Azure Monitor / Container Insights status

Optional sections වල monitoring features missing නම් in-cluster monitoring install කරන හෝ Azure Monitor enable කරන විදිය පෙන්වනවා.

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා කරන්න පුළුවන් විය යුතුයි:

- AKS cluster access verify කිරීම
- `kubectl top` use කරලා node සහ pod metrics check කිරීම
- metrics-server working ද confirm කිරීම
- kube-system pod health inspect කිරීම
- recent Kubernetes events inspect කිරීම
- Prometheus සහ Grafana cluster එකේ install වෙලාද check කිරීම
- `kubectl port-forward` use කරලා Grafana locally access කිරීම
- `kubectl port-forward` use කරලා Prometheus locally access කිරීම
- Azure Monitor / Container Insights enabled ද check කිරීම
- Common monitoring checks collect කරන helper script එක run කිරීම
- මෙම lab එකේදී install කළ optional monitoring resources පමණක් clean up කිරීම

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- AKS cluster health check කරන විදිය
- Node සහ pod metrics බලන්න `kubectl top` use කරන විදිය
- metrics-server working ද verify කරන විදිය
- kube-system pods inspect කරන විදිය
- recent Kubernetes events inspect කරන විදිය
- Prometheus සහ Grafana install වෙලාද check කරන විදිය
- Grafana locally access කරන්න port-forward use කරන විදිය
- Prometheus locally access කරන්න port-forward use කරන විදිය
- Azure Monitor / Container Insights enabled ද check කරන විදිය
- In-cluster monitoring missing නම් install කරන විදිය
- මෙම lab එකෙන් create නොකළ monitoring resources delete නොකරන විදිය

## Lab architecture

මෙම lab එක common monitoring approaches දෙකක් cover කරනවා.

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

Azure Monitor / Container Insights optional, මොකද එය Azure resources create හෝ use කරලා cost add කරන්න පුළුවන්.

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- Azure CLI
- kubectl
- Helm
- Terminal එකක්
- Web browser එකක්
- Existing AKS cluster එකක්
- AKS cluster access
- AKS cluster details list කරන්න permission
- Optional Helm charts install කරන්න permission
- Optional Azure Monitor addon enable කරන්න permission

මෙම lab එකට අවශ්‍ය නැහැ:

- Docker Desktop
- Container registry
- CI/CD platform
- අලුත් application deployment එකක්

## Install required local tools

### Azure CLI

Azure CLI install කරන්න:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Azure CLI verify කරන්න:

    az version

Azure වලට login වෙන්න:

    az login

Active account එක verify කරන්න:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

### kubectl

kubectl install කරන්න:

    https://kubernetes.io/docs/tasks/tools/

kubectl verify කරන්න:

    kubectl version --client

### Helm

Helm install කරන්න:

    https://helm.sh/docs/intro/install/

Helm verify කරන්න:

    helm version

## Check local tools and Azure access

Continue කරන්න කලින් verify කරන්න:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl version --client
    helm version

ඔයාගේ AKS values set කරන්න:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"

AKS credentials ගන්න:

    az aks get-credentials \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --overwrite-existing

AKS access verify කරන්න:

    kubectl get nodes

## Find your Azure values

ඔයාගේ resource group, AKS cluster, සහ location values හොයාගන්න මේ commands use කරන්න.

Resource groups list කරන්න:

    az group list --query "[].{name:name, location:location}" -o table

AKS clusters list කරන්න:

    az aks list --query "[].{name:name, resourceGroup:resourceGroup, location:location}" -o table

ඔයාගේ values set කරන්න:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"
    LOCATION="<your-azure-region>"

Example location format:

    southeastasia

Verify කරන්න:

    echo "$RESOURCE_GROUP"
    echo "$AKS_NAME"
    echo "$LOCATION"

වෙන environment එකක values copy කරන්න එපා.

ඔයාගේම Azure subscription එකේ values use කරන්න.

## Files in this lab

මෙම lab එකේ files:

    scripts/
      Monitoring status check කරන්න helper script

Files:

    scripts/check-monitoring.sh

## Set lab variables

ඔයාගේ environment එකට මේ values set කරන්න:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"
    LOCATION="<your-azure-region>"
    MONITORING_NAMESPACE="monitoring"
    PROMETHEUS_RELEASE="kube-prometheus-stack"

Verify කරන්න:

    echo "$RESOURCE_GROUP"
    echo "$AKS_NAME"
    echo "$LOCATION"
    echo "$MONITORING_NAMESPACE"
    echo "$PROMETHEUS_RELEASE"

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

    Nodes Ready වෙන්න ඕන.

## Check Kubernetes metrics

Node metrics check කරන්න:

    kubectl top nodes

All namespaces වල pod metrics check කරන්න:

    kubectl top pods --all-namespaces

මේ commands වැඩ කරනවා නම්, metrics-server working.

metrics-server check කරන්න:

    kubectl get deployment metrics-server -n kube-system

`kubectl top` වැඩ කරන්නේ නැත්නම්, cluster create කළාට පස්සේ ටික වෙලාවක් wait කරලා metrics-server pods check කරන්න:

    kubectl get pods -n kube-system | grep metrics-server

AKS වල metrics-server සාමාන්‍යයෙන් default install වෙලා තියෙනවා.

## Check system pod health

kube-system pods check කරන්න:

    kubectl get pods -n kube-system

Important system pods සියල්ල Running වෙන්න ඕන.

Wider view එකකට:

    kubectl get pods --all-namespaces

Useful troubleshooting commands:

    kubectl describe pod <pod-name> -n <namespace>
    kubectl logs <pod-name> -n <namespace>

Pod එකක containers කිහිපයක් තියෙනවා නම්:

    kubectl logs <pod-name> -n <namespace> -c <container-name>

## Check recent Kubernetes events

Recent events check කරන්න:

    kubectl get events --all-namespaces --sort-by=.lastTimestamp | tail -20

Events scheduling issues, image pull issues, probe failures, volume mount issues, සහ permission problems හඳුනාගන්න උදව් වෙනවා.

එක namespace එකක් පමණක් inspect කරන්න:

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

`kube-prometheus-stack` release එකක් දැක්කොත්, සාමාන්‍යයෙන් Prometheus, Grafana, Alertmanager, kube-state-metrics, සහ node-exporter install වෙලා තියෙනවා.

Namespace එක නැත්නම්, ඒකෙන් අදහස් වෙන්නේ එම namespace එකේ මෙම in-cluster monitoring stack එක install වෙලා නැහැ කියන එක විතරයි.

## If missing: install kube-prometheus-stack

මෙම lab එක සඳහා in-cluster Prometheus සහ Grafana අවශ්‍ය නම් විතරක් මෙම stack එක install කරන්න.

Cluster එකේ දැනටමත් වෙන කෙනෙක් manage කරන monitoring stack එකක් තියෙනවා නම්, ඒක replace කරන්න එපා.

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

මෙයට විනාඩි කිහිපයක් යන්න පුළුවන්.

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

Secret command එකෙන් ලැබුණු password එක use කරන්න.

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

Output එක empty හෝ null නම්, Azure Monitor addon enabled නැහැ.

ඒකෙන් cluster එකේ monitoring නැහැ කියන එක අදහස් වෙන්නේ නැහැ.

ඒකෙන් අදහස් වෙන්නේ Azure-native Container Insights AKS addon එක හරහා enabled නැහැ කියන එක විතරයි.

## Optional: enable Azure Monitor / Container Insights

Azure-native monitoring අවශ්‍ය නම් විතරක් මෙය use කරන්න.

මෙය Log Analytics workspace එකක් create හෝ use කරන්න පුළුවන්. Azure cost add වෙන්න පුළුවන්.

Monitoring addon enable කරන්න:

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

Helper script එකට මේ variables අවශ්‍යයි:

    RESOURCE_GROUP
    AKS_NAME

Optional variable:

    MONITORING_NAMESPACE

Repository root එකේ සිට helper script එක run කරන්න:

    ./labs/practitioner/10-monitoring-basics/scripts/check-monitoring.sh

Script එක check කරන දේවල්:

- AKS cluster details
- Current Kubernetes context
- Nodes
- Node metrics
- Pod metrics
- kube-system pods
- metrics-server
- Recent Kubernetes events
- Azure Monitor addon status
- In-cluster monitoring namespace
- In-cluster monitoring pods
- In-cluster monitoring services
- Monitoring namespace එකේ Helm releases

## Cleanup

මෙම lab එකේදී install හෝ enable කළ resources පමණක් remove කරන්න.

මෙම lab එකට විතරක් kube-prometheus-stack install කළා නම් සහ තව අවශ්‍ය නැත්නම්, remove කරන්න:

    helm uninstall "$PROMETHEUS_RELEASE" -n "$MONITORING_NAMESPACE"

Monitoring namespace එක delete කරන්න, එය මෙම lab එකට create කළා නම් පමණක්:

    kubectl delete namespace "$MONITORING_NAMESPACE" --ignore-not-found

Azure Monitor disable කරන්න, එය මෙම lab එකට enable කළා නම් සහ තව අවශ්‍ය නැත්නම් පමණක්:

    az aks disable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons monitoring

Azure Monitor addon status verify කරන්න:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.omsagent" \
      --output json

මෙම lab එකෙන් පිටත create කළ shared monitoring resources remove කරන්න එපා.

## What you completed

ඔයා inspect කළ දේවල්:

- AKS cluster health
- Kubernetes node සහ pod metrics
- metrics-server status
- kube-system health
- Recent Kubernetes events
- In-cluster monitoring status
- Grafana local access
- Prometheus local access
- Azure Monitor / Container Insights status
- Optional enable සහ cleanup paths

## Important note

මෙය learning lab එකක්.

Monitoring setups බොහෝ විට teams සහ clusters අතර shared වෙනවා.

Monitoring components install හෝ remove කරන්න කලින් ඒවා කවුද own කරන්නේ සහ ඒවා මත depend වෙන දේවල් මොනවද කියලා තේරුම් ගන්න.
