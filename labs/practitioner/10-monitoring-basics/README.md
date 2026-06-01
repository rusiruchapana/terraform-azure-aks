# Practitioner Lab 10 - Monitoring Basics

This lab shows how to inspect basic monitoring and observability signals in an AKS cluster.

This is a standalone AKS operations lab.

This lab does not deploy a new application by default.

The default lab path focuses on read-only monitoring checks:

- Node and pod metrics
- metrics-server status
- System pod health
- Kubernetes events
- In-cluster Prometheus and Grafana discovery
- Azure Monitor / Container Insights status

Optional sections show how to install in-cluster monitoring or enable Azure Monitor if those features are missing.

## Lab goal

By the end of this lab, you should be able to:

- Verify AKS cluster access
- Check node and pod metrics with `kubectl top`
- Confirm whether metrics-server is working
- Inspect kube-system pod health
- Inspect recent Kubernetes events
- Check whether Prometheus and Grafana are installed in the cluster
- Access Grafana locally with `kubectl port-forward`
- Access Prometheus locally with `kubectl port-forward`
- Check whether Azure Monitor / Container Insights is enabled
- Run a helper script that collects common monitoring checks
- Clean up only the optional monitoring resources that you installed during this lab

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
- How to avoid deleting monitoring resources that were not created by this lab

## Lab architecture

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
- A terminal
- A web browser
- Existing AKS cluster
- Access to the AKS cluster
- Permission to list AKS cluster details
- Optional permission to install Helm charts
- Optional permission to enable Azure Monitor addon

This lab does not require:

- Docker Desktop
- A container registry
- A CI/CD platform
- A new application deployment

## Install required local tools

### Azure CLI

Install Azure CLI:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Verify Azure CLI:

    az version

Login to Azure:

    az login

Verify the active account:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

### kubectl

Install kubectl:

    https://kubernetes.io/docs/tasks/tools/

Verify kubectl:

    kubectl version --client

### Helm

Install Helm:

    https://helm.sh/docs/intro/install/

Verify Helm:

    helm version

## Check local tools and Azure access

Before continuing, verify:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl version --client
    helm version

Set your AKS values:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"

Get AKS credentials:

    az aks get-credentials \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --overwrite-existing

Verify AKS access:

    kubectl get nodes

## Find your Azure values

Use these commands to find your resource group, AKS cluster, and location.

List resource groups:

    az group list --query "[].{name:name, location:location}" -o table

List AKS clusters:

    az aks list --query "[].{name:name, resourceGroup:resourceGroup, location:location}" -o table

Set your values:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"
    LOCATION="<your-azure-region>"

Example location format:

    southeastasia

Verify:

    echo "$RESOURCE_GROUP"
    echo "$AKS_NAME"
    echo "$LOCATION"

Do not copy values from another environment.

Use values from your own Azure subscription.

## Files in this lab

This lab includes:

    scripts/
      Helper script to check monitoring status

Files:

    scripts/check-monitoring.sh

## Set lab variables

Set these values for your environment:

    RESOURCE_GROUP="<your-resource-group>"
    AKS_NAME="<your-aks-cluster-name>"
    LOCATION="<your-azure-region>"
    MONITORING_NAMESPACE="monitoring"
    PROMETHEUS_RELEASE="kube-prometheus-stack"

Verify:

    echo "$RESOURCE_GROUP"
    echo "$AKS_NAME"
    echo "$LOCATION"
    echo "$MONITORING_NAMESPACE"
    echo "$PROMETHEUS_RELEASE"

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

If the namespace does not exist, that only means this in-cluster monitoring stack is not installed in that namespace.

## If missing: install kube-prometheus-stack

Only install this stack if you want in-cluster Prometheus and Grafana for this lab.

If your cluster already has a monitoring stack managed by someone else, do not replace it.

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

This does not mean the cluster has no monitoring.

It only means Azure-native Container Insights is not enabled through the AKS addon.

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

The helper script requires these variables:

    RESOURCE_GROUP
    AKS_NAME

Optional variable:

    MONITORING_NAMESPACE

Run the helper script from the repository root:

    ./labs/practitioner/10-monitoring-basics/scripts/check-monitoring.sh

The script checks:

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
- Helm releases in the monitoring namespace

## Cleanup

Only remove resources that you installed or enabled during this lab.

If you installed kube-prometheus-stack only for this lab and do not need it anymore, remove it:

    helm uninstall "$PROMETHEUS_RELEASE" -n "$MONITORING_NAMESPACE"

Delete the monitoring namespace only if you created it for this lab:

    kubectl delete namespace "$MONITORING_NAMESPACE" --ignore-not-found

Disable Azure Monitor only if you enabled it for this lab and you no longer need it:

    az aks disable-addons \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --addons monitoring

Verify Azure Monitor addon status:

    az aks show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --query "addonProfiles.omsagent" \
      --output json

Do not remove shared monitoring resources that were created outside this lab.

## What you completed

You inspected:

- AKS cluster health
- Kubernetes node and pod metrics
- metrics-server status
- kube-system health
- Recent Kubernetes events
- In-cluster monitoring status
- Grafana local access
- Prometheus local access
- Azure Monitor / Container Insights status
- Optional enable and cleanup paths

## Important note

This is a learning lab.

Monitoring setups are often shared across teams and clusters.

Only install or remove monitoring components when you understand who owns them and what depends on them.
