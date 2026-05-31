# Practitioner Lab 10 - Monitoring Basics

This lab shows how to inspect basic monitoring and observability signals in an AKS cluster.

The lab focuses on practical checks that every AKS operator should know:

- Node and pod metrics
- System pod health
- Kubernetes events
- In-cluster Prometheus and Grafana discovery
- Azure Monitor / Container Insights status
- Optional setup steps if monitoring is not already installed
- Cleanup steps

This lab does not require a new application deployment.

## What you will learn

You will learn:

- How to check AKS cluster health
- How to use `kubectl top` for node and pod metrics
- How to verify that metrics-server is working
- How to inspect kube-system pods
- How to inspect recent Kubernetes events
- How to check whether Prometheus and Grafana are installed
- How to access Grafana locally with port-forward
- How to access Prometheus locally with port-forward
- How to check whether Azure Monitor / Container Insights is enabled
- How to install in-cluster monitoring if it is missing
- How to clean up optional monitoring resources

## Architecture

This lab covers two common monitoring approaches.

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

The default lab path uses Kubernetes and in-cluster monitoring checks.

Azure Monitor / Container Insights is optional because it may create or use Azure resources that can add cost.

## What this lab requires

You need:

- Azure CLI
- kubectl
- Helm
- Existing AKS cluster
- Access to the AKS cluster
- Permission to list AKS cluster details
- Optional permission to install Helm charts
- Optional permission to enable Azure Monitor addon

Check Azure and Kubernetes access:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl get nodes

## Lab files

This lab includes:

    scripts/
      Helper script to check monitoring status

Files:

    scripts/check-monitoring.sh

## Set lab variables

Set these values for your environment:

    RESOURCE_GROUP="rg-aks-dev-001"
    AKS_NAME="aks-dev-001"
    LOCATION="southeastasia"
    MONITORING_NAMESPACE="monitoring"
    PROMETHEUS_RELEASE="kube-prometheus-stack"

## Verify AKS cluster access

Check the AKS cluster:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "{name:name, resourceGroup:resourceGroup, location:location, kubernetesVersion:kubernetesVersion, powerState:powerState.code}" \
      --output table

Check the current Kubernetes context:

    kubectl config current-context

Check nodes:

    kubectl get nodes -o wide

Expected result:

    Nodes should be Ready.

## Check Kubernetes metrics

Check node metrics:

    kubectl top nodes

Check pod metrics across all namespaces:

    kubectl top pods --all-namespaces

If these commands work, metrics-server is working.

Check metrics-server:

    kubectl get deployment metrics-server -n kube-system

If `kubectl top` does not work, wait a few minutes after cluster creation and check metrics-server pods:

    kubectl get pods -n kube-system | grep metrics-server

On AKS, metrics-server is normally installed by default.

## Check system pod health

Check kube-system pods:

    kubectl get pods -n kube-system

All important system pods should be Running.

For a wider view:

    kubectl get pods --all-namespaces

Useful troubleshooting commands:

    kubectl describe pod <pod-name> -n <namespace>
    kubectl logs <pod-name> -n <namespace>

If a pod has multiple containers:

    kubectl logs <pod-name> -n <namespace> -c <container-name>

## Check recent Kubernetes events

Check recent events:

    kubectl get events --all-namespaces --sort-by=.lastTimestamp | tail -20

Events help identify scheduling issues, image pull issues, probe failures, volume mount issues, and permission problems.

To inspect one namespace only:

    kubectl get events -n <namespace> --sort-by=.lastTimestamp

## Check if in-cluster monitoring exists

Check the monitoring namespace:

    kubectl get ns "$MONITORING_NAMESPACE"

Check monitoring pods:

    kubectl get pods -n "$MONITORING_NAMESPACE"

Check monitoring services:

    kubectl get svc -n "$MONITORING_NAMESPACE"

Check Helm releases:

    helm list -n "$MONITORING_NAMESPACE"

If you see a `kube-prometheus-stack` release, Prometheus, Grafana, Alertmanager, kube-state-metrics, and node-exporter are usually installed.

## If missing: install kube-prometheus-stack

If the monitoring namespace or Helm release does not exist, install kube-prometheus-stack.

Add the Helm repo:

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

Create the namespace:

    kubectl create namespace "$MONITORING_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

Install kube-prometheus-stack:

    helm upgrade --install "$PROMETHEUS_RELEASE" prometheus-community/kube-prometheus-stack \
      --namespace "$MONITORING_NAMESPACE"

Verify:

    kubectl get pods -n "$MONITORING_NAMESPACE"
    kubectl get svc -n "$MONITORING_NAMESPACE"
    helm list -n "$MONITORING_NAMESPACE"

This can take a few minutes.

## Access Grafana locally

Get the Grafana admin password:

    kubectl get secret \
      --namespace "$MONITORING_NAMESPACE" \
      "${PROMETHEUS_RELEASE}-grafana" \
      -o jsonpath="{.data.admin-password}" | base64 --decode; echo

Port-forward Grafana:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-grafana \
      3000:80

Open Grafana locally:

    http://localhost:3000

Default username:

    admin

Use the password from the secret command.

Stop port-forward with:

    Ctrl+C

## Access Prometheus locally

Port-forward Prometheus:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-prometheus \
      9090:9090

Open Prometheus locally:

    http://localhost:9090

Example Prometheus queries:

    up
    node_cpu_seconds_total
    kube_pod_info

Stop port-forward with:

    Ctrl+C

## Check Azure Monitor / Container Insights

Check the Azure Monitor addon status:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.omsagent" \
      --output json

If the output is empty or null, the Azure Monitor addon is not enabled.

This does not mean the cluster has no monitoring. It only means Azure-native Container Insights is not enabled through the AKS addon.

## Optional: enable Azure Monitor / Container Insights

Use this only if you want Azure-native monitoring.

This may create or use a Log Analytics workspace and may add Azure cost.

Enable the monitoring addon:

    az aks enable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons monitoring

Verify:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.omsagent" \
      --output json

List Log Analytics workspaces in the resource group:

    az monitor log-analytics workspace list \
      --resource-group "$RESOURCE_GROUP" \
      --query "[].{name:name, location:location, resourceGroup:resourceGroup}" \
      --output table

## Run the helper script

You can run the helper script to collect common monitoring checks:

    ./labs/practitioner/10-monitoring-basics/scripts/check-monitoring.sh

The script checks:

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

If you installed kube-prometheus-stack only for this lab and do not need it anymore, remove it:

    helm uninstall "$PROMETHEUS_RELEASE" -n "$MONITORING_NAMESPACE"

Delete the monitoring namespace:

    kubectl delete namespace "$MONITORING_NAMESPACE" --ignore-not-found

If you enabled Azure Monitor / Container Insights only for this lab and want to disable it:

    az aks disable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons monitoring

Check addon status again:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.omsagent" \
      --output json

If another lab depends on the monitoring stack, keep it.

## What you completed

You checked:

- AKS cluster health
- Node readiness
- Node and pod metrics
- metrics-server status
- kube-system health
- Kubernetes events
- In-cluster monitoring status
- Grafana local access
- Prometheus local access
- Azure Monitor addon status
- Optional enable and cleanup paths

This prepares the cluster for the next practitioner lab:

    Practitioner Lab 11 - OpenTelemetry App
