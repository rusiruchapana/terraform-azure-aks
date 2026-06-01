# Practitioner Lab 11 - OpenTelemetry App

This lab shows how to send OpenTelemetry telemetry into a dedicated OpenTelemetry Collector and visualize the resulting metrics with Prometheus and Grafana.

This is a standalone AKS observability lab.

The default path uses `telemetrygen`, a public OpenTelemetry telemetry generator image.

This avoids needing to build and push a custom container image.

The lab uses:

- AKS
- Existing Prometheus Operator or kube-prometheus-stack
- A dedicated OpenTelemetry Collector for this lab
- A ServiceMonitor for Prometheus scraping
- `telemetrygen` jobs to generate traces and metrics
- Prometheus for metric queries
- Grafana for visualization

## Lab goal

By the end of this lab, you should have:

- A Kubernetes namespace named `practitioner-otel`
- A dedicated OpenTelemetry Collector deployment named `otel-lab-collector`
- A collector service that receives OTLP traffic on ports `4317` and `4318`
- A collector metrics endpoint on port `8889`
- A ServiceMonitor that lets Prometheus scrape the collector
- Telemetry generator jobs for traces and metrics
- OpenTelemetry-generated metrics visible in Prometheus
- A basic Grafana query or panel for OpenTelemetry metrics

This lab does not modify a shared OpenTelemetry Collector.

This lab does not require a custom application image by default.

## What you will learn

You will learn:

- How OpenTelemetry fits into an AKS monitoring stack
- How to deploy a dedicated OpenTelemetry Collector for a lab
- How to receive OTLP telemetry over gRPC and HTTP
- How to expose collector metrics for Prometheus
- How to create a ServiceMonitor for Prometheus Operator
- How to generate test traces and metrics with telemetrygen
- How to verify telemetry in collector logs
- How to query OpenTelemetry metrics in Prometheus
- How to visualize OpenTelemetry metrics in Grafana
- How to clean up lab resources safely

## Lab architecture

The default flow is:

    telemetrygen
      |
      | OTLP gRPC
      v
    OpenTelemetry Collector
      |
      | Prometheus metrics endpoint
      v
    Prometheus
      |
      v
    Grafana

This lab uses a dedicated namespace:

    practitioner-otel

The lab resources are:

    practitioner-otel namespace
      |
      |-- otel-lab-collector
      |     |
      |     | receives OTLP on 4317 and 4318
      |     | exposes Prometheus metrics on 8889
      |
      |-- telemetrygen-traces job
      |
      |-- telemetrygen-metrics job
      |
      |-- ServiceMonitor for Prometheus scraping

The existing monitoring stack is usually in:

    monitoring

Prometheus and Grafana are commonly provided by kube-prometheus-stack.

## What this lab requires

You need:

- kubectl
- Helm
- A terminal
- A web browser
- Existing AKS cluster access
- Existing Prometheus Operator or kube-prometheus-stack
- ServiceMonitor CRD installed
- Grafana access
- Internet access from AKS nodes to pull the telemetrygen image

Optional custom app image path requires:

- Docker
- Azure CLI
- Azure Container Registry or another container registry

This lab does not require by default:

- Azure Container Registry
- Docker Desktop
- CI/CD platform
- Custom image build or push

## Install required local tools

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

### Azure CLI for optional custom image path

Azure CLI is only needed if you use the optional custom image path with Azure Container Registry.

Install Azure CLI:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Verify Azure CLI:

    az version

### Docker for optional custom image path

Docker is only needed if you build and push the optional FastAPI app image.

Verify Docker:

    docker version

## Check local tools and cluster access

Before continuing, verify:

    kubectl version --client
    helm version
    kubectl get nodes

Set lab variables:

    NAMESPACE="practitioner-otel"
    MONITORING_NAMESPACE="monitoring"
    PROMETHEUS_RELEASE="kube-prometheus-stack"

Verify:

    echo "$NAMESPACE"
    echo "$MONITORING_NAMESPACE"
    echo "$PROMETHEUS_RELEASE"

## Files in this lab

This lab includes:

    app/
      Optional FastAPI app files for a custom image path

    manifests/
      Kubernetes manifests for the lab collector, ServiceMonitor, and telemetry generator

Files:

    manifests/namespace.yaml
    manifests/otel-collector.yaml
    manifests/servicemonitor.yaml
    manifests/telemetrygen.yaml
    app/Dockerfile
    app/main.py
    app/requirements.txt

The default lab path uses only the manifests and the public telemetrygen image.

The app folder is optional.

## Verify existing monitoring

Check Prometheus, Grafana, and the existing monitoring components:

    kubectl get pods -n "$MONITORING_NAMESPACE"
    kubectl get svc -n "$MONITORING_NAMESPACE"
    helm list -n "$MONITORING_NAMESPACE"

Check ServiceMonitor support:

    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

Expected:

    ServiceMonitor CRD exists

If the ServiceMonitor CRD is missing, install Prometheus Operator or kube-prometheus-stack before continuing.

For kube-prometheus-stack:

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    kubectl create namespace "$MONITORING_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    helm upgrade --install "$PROMETHEUS_RELEASE" prometheus-community/kube-prometheus-stack \
      --namespace "$MONITORING_NAMESPACE"

Verify after installation:

    kubectl get pods -n "$MONITORING_NAMESPACE"
    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

## Create the lab namespace

Apply the namespace:

    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/namespace.yaml

Verify:

    kubectl get ns "$NAMESPACE"

## Deploy the dedicated OpenTelemetry Collector

Apply the collector manifest:

    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/otel-collector.yaml

Verify:

    kubectl get pods -n "$NAMESPACE"
    kubectl get svc -n "$NAMESPACE"

Wait until the collector is Running:

    kubectl rollout status deployment/otel-lab-collector -n "$NAMESPACE" --timeout=180s

The collector listens on:

    4317 for OTLP gRPC
    4318 for OTLP HTTP
    8889 for Prometheus metrics scraping

## Create the ServiceMonitor

Apply the ServiceMonitor:

    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/servicemonitor.yaml

Verify:

    kubectl get servicemonitor -n "$NAMESPACE"
    kubectl describe servicemonitor otel-lab-collector -n "$NAMESPACE"

The ServiceMonitor lets Prometheus scrape:

    http://otel-lab-collector.practitioner-otel.svc.cluster.local:8889/metrics

## Verify the Prometheus target

Port-forward Prometheus:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-prometheus \
      9090:9090

Open Prometheus:

    http://localhost:9090/targets

Search for:

    otel-lab-collector

Expected result:

    serviceMonitor/practitioner-otel/otel-lab-collector/0
    1 / 1 up

Stop port-forward with:

    Ctrl+C

## Generate OpenTelemetry telemetry

Apply the telemetry generator jobs:

    kubectl delete job telemetrygen-traces telemetrygen-metrics -n "$NAMESPACE" --ignore-not-found
    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/telemetrygen.yaml

Check jobs and pods:

    kubectl get jobs -n "$NAMESPACE"
    kubectl get pods -n "$NAMESPACE"

Check telemetrygen logs:

    kubectl logs job/telemetrygen-traces -n "$NAMESPACE"
    kubectl logs job/telemetrygen-metrics -n "$NAMESPACE"

The logs should show that telemetrygen connected to:

    otel-lab-collector.practitioner-otel.svc.cluster.local:4317

## Verify collector logs

Check the lab collector logs:

    kubectl logs deployment/otel-lab-collector -n "$NAMESPACE" --tail=120

Expected log signals include:

    Traces
    Metrics
    otelcol.signal

For metrics, you should see that the collector received generated metrics and data points.

## Query metrics in Prometheus

Port-forward Prometheus:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-prometheus \
      9090:9090

Open Prometheus:

    http://localhost:9090

Query:

    gen

You should see a metric similar to:

    gen{job="otel-lab-collector", namespace="practitioner-otel", exported_job="practitioner-otel-telemetrygen"}

You can also query:

    {job="otel-lab-collector"}

Stop port-forward with:

    Ctrl+C

## Visualize metrics in Grafana

Port-forward Grafana:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-grafana \
      3000:80

Get the Grafana admin password:

    kubectl get secret \
      --namespace "$MONITORING_NAMESPACE" \
      ${PROMETHEUS_RELEASE}-grafana \
      -o jsonpath="{.data.admin-password}" | base64 --decode; echo

Open Grafana:

    http://localhost:3000

Login:

    Username: admin
    Password: use the password from the secret command

If Grafana opens without asking for a password and edit options are disabled, sign out and log in again as `admin`.

You can also use an incognito or private browser window.

In Grafana:

    Explore
      |
      v
    Select Prometheus datasource
      |
      v
    Run this query:

    gen{job="otel-lab-collector"}

Create a dashboard panel with:

    Query: gen{job="otel-lab-collector"}
    Panel title: OpenTelemetry Generated Metric

You can also use:

    sum(gen{job="otel-lab-collector"})

Stop port-forward with:

    Ctrl+C

## Optional: custom application image path

The default lab path uses telemetrygen and does not need a custom image.

This optional path uses the simple FastAPI app under:

    app/

Use this optional path only if your environment allows image push to a container registry.

Example variables:

    ACR_NAME="<your-acr-name>"
    ACR_LOGIN_SERVER="<your-acr-login-server>"
    IMAGE_NAME="practitioner-otel-app"
    IMAGE_TAG="v1"
    IMAGE="$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"

Find ACR values:

    az acr list --query "[].{name:name, resourceGroup:resourceGroup, loginServer:loginServer}" -o table

Login to ACR:

    az acr login --name "$ACR_NAME"

Build and push from an Apple Silicon Mac for AKS Linux nodes:

    docker buildx build \
      --platform linux/amd64 \
      -t "$IMAGE" \
      labs/practitioner/11-opentelemetry-app/app \
      --push

If Docker push times out, check network access to ACR:

    curl -I https://$ACR_LOGIN_SERVER/v2/

If Azure ACR Tasks are disabled in your subscription, `az acr build` may fail.

In that case, continue with the default telemetrygen path.

## Troubleshooting

### Check lab namespace resources

Check all lab resources:

    kubectl get all -n "$NAMESPACE"

### Collector logs do not show telemetry

Check collector logs:

    kubectl logs deployment/otel-lab-collector -n "$NAMESPACE" --tail=120

Check telemetrygen jobs:

    kubectl get jobs -n "$NAMESPACE"
    kubectl logs job/telemetrygen-traces -n "$NAMESPACE"
    kubectl logs job/telemetrygen-metrics -n "$NAMESPACE"

### ServiceMonitor target does not appear

Check ServiceMonitor:

    kubectl get servicemonitor -n "$NAMESPACE"
    kubectl describe servicemonitor otel-lab-collector -n "$NAMESPACE"

Check Prometheus targets:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-prometheus \
      9090:9090

Then open:

    http://localhost:9090/targets

Look for:

    otel-lab-collector

### ServiceMonitor CRD is missing

Check CRDs:

    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

If missing, install Prometheus Operator or kube-prometheus-stack.

### telemetrygen image pull fails

If telemetrygen has image pull errors, check the image tag in:

    labs/practitioner/11-opentelemetry-app/manifests/telemetrygen.yaml

The current image is:

    ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.152.0

Also check whether AKS nodes can pull images from GitHub Container Registry.

### Grafana service name is different

If this service does not exist:

    svc/${PROMETHEUS_RELEASE}-grafana

List services:

    kubectl get svc -n "$MONITORING_NAMESPACE"

Use the Grafana service name that exists in your cluster.

### Prometheus service name is different

If this service does not exist:

    svc/${PROMETHEUS_RELEASE}-prometheus

List services:

    kubectl get svc -n "$MONITORING_NAMESPACE"

Use the Prometheus service name that exists in your cluster.

## Cleanup

Delete telemetry generator jobs:

    kubectl delete job telemetrygen-traces telemetrygen-metrics -n "$NAMESPACE" --ignore-not-found

Delete the lab namespace and all lab resources:

    kubectl delete namespace "$NAMESPACE" --ignore-not-found

This removes:

- Dedicated lab OpenTelemetry Collector
- Lab ServiceMonitor
- telemetrygen jobs
- Optional lab resources in the `practitioner-otel` namespace

Do not delete shared monitoring resources that were not created by this lab.

Do not delete:

- kube-prometheus-stack
- Prometheus Operator CRDs
- The shared monitoring namespace
- Any shared OpenTelemetry Collector outside this lab namespace

## Security cleanup

If you used the optional custom image path, remove any image tags that you no longer need.

Do not commit registry credentials or local environment secrets.

For production, prefer:

- Least privilege access
- Separate collectors per environment or workload boundary
- Controlled telemetry retention
- Secure OTLP endpoints
- Resource limits on collectors
- Dashboards and alerts owned by the service team

## Important note

This is a learning lab.

It demonstrates how telemetry flows from an OpenTelemetry source to a collector and then into Prometheus and Grafana.

For production, design your OpenTelemetry architecture around ownership, scaling, security, retention, and alerting requirements.
