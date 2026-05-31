# Practitioner Lab 11 - OpenTelemetry App

This lab shows how to send OpenTelemetry telemetry into a dedicated OpenTelemetry Collector and visualize the resulting metrics with Prometheus and Grafana.

The default path uses `telemetrygen`, a public OpenTelemetry telemetry generator image. This avoids needing to build and push a custom container image.

The flow is:

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

## What you will learn

You will learn:

- How OpenTelemetry fits into an AKS monitoring stack
- How to deploy a dedicated OpenTelemetry Collector for a lab
- How to receive OTLP telemetry over gRPC
- How to expose collector metrics for Prometheus
- How to create a ServiceMonitor for Prometheus Operator
- How to generate test traces and metrics with telemetrygen
- How to verify telemetry in collector logs
- How to query OpenTelemetry metrics in Prometheus
- How to visualize OpenTelemetry metrics in Grafana
- How to clean up lab resources safely

## Architecture

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

The existing monitoring stack remains in:

    monitoring

Prometheus and Grafana are provided by kube-prometheus-stack.

This lab does not modify the shared OpenTelemetry Collector in the monitoring namespace.

## What this lab requires

You need:

- Azure CLI
- kubectl
- Existing AKS cluster
- Existing kube-prometheus-stack
- Prometheus Operator CRDs
- Grafana access
- Internet access from AKS nodes to pull the telemetrygen image

Check Kubernetes access:

    kubectl get nodes

Check monitoring stack:

    kubectl get pods -n monitoring
    helm list -n monitoring

Check Prometheus Operator CRDs:

    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

## Lab files

This lab includes:

    app/
      Optional FastAPI app files for a custom image path

    manifests/
      Kubernetes manifests for the lab collector, ServiceMonitor, and telemetry generator

    scripts/
      Helper scripts can be added later if needed

Files:

    manifests/namespace.yaml
    manifests/otel-collector.yaml
    manifests/servicemonitor.yaml
    manifests/telemetrygen.yaml
    app/Dockerfile
    app/main.py
    app/requirements.txt

## Set lab variables

Set these values for your environment:

    NAMESPACE="practitioner-otel"
    MONITORING_NAMESPACE="monitoring"

## Verify existing monitoring

Check Prometheus, Grafana, and the existing monitoring components:

    kubectl get pods -n "$MONITORING_NAMESPACE"
    kubectl get svc -n "$MONITORING_NAMESPACE"
    helm list -n "$MONITORING_NAMESPACE"

Check ServiceMonitor support:

    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

If the ServiceMonitor CRD is missing, complete Practitioner Lab 10 first and install kube-prometheus-stack.

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

    kubectl rollout status deployment/otel-lab-collector -n "$NAMESPACE"

The collector listens on:

    4317 for OTLP gRPC
    4318 for OTLP HTTP
    8889 for Prometheus metrics scraping

## Create the ServiceMonitor

Apply the ServiceMonitor:

    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/servicemonitor.yaml

Verify:

    kubectl get servicemonitor -n "$NAMESPACE"

The ServiceMonitor lets Prometheus scrape:

    http://otel-lab-collector.practitioner-otel.svc.cluster.local:8889/metrics

## Verify the Prometheus target

Port-forward Prometheus:

    kubectl port-forward \
      --namespace monitoring \
      svc/kube-prometheus-stack-prometheus \
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
      --namespace monitoring \
      svc/kube-prometheus-stack-prometheus \
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
      --namespace monitoring \
      svc/kube-prometheus-stack-grafana \
      3000:80

Get the Grafana admin password:

    kubectl get secret \
      --namespace monitoring \
      kube-prometheus-stack-grafana \
      -o jsonpath="{.data.admin-password}" | base64 --decode; echo

Open Grafana:

    http://localhost:3000

Login:

    Username: admin
    Password: use the password from the secret command

If Grafana opens without asking for a password and edit options are disabled, sign out and log in again as `admin`. You can also use an incognito or private browser window.

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

This lab includes a simple FastAPI app under:

    app/

You can build and push it to your own registry if your environment allows image push.

Example variables:

    ACR_NAME="<your-acr-name>"
    ACR_LOGIN_SERVER="<your-acr-login-server>"
    IMAGE_NAME="practitioner-otel-app"
    IMAGE_TAG="v1"
    IMAGE="$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"

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

If Azure ACR Tasks are disabled in your subscription, `az acr build` may fail. In that case, continue with the default telemetrygen path.

## Troubleshooting

Check lab namespace resources:

    kubectl get all -n "$NAMESPACE"

Check collector logs:

    kubectl logs deployment/otel-lab-collector -n "$NAMESPACE" --tail=120

Check ServiceMonitor:

    kubectl get servicemonitor -n "$NAMESPACE"
    kubectl describe servicemonitor otel-lab-collector -n "$NAMESPACE"

Check Prometheus targets:

    kubectl port-forward \
      --namespace monitoring \
      svc/kube-prometheus-stack-prometheus \
      9090:9090

Then open:

    http://localhost:9090/targets

If a target is down, check:

- Service labels
- ServiceMonitor selector labels
- Service port name
- Collector pod readiness
- Collector metrics port

If telemetrygen has image pull errors, check the image tag in:

    manifests/telemetrygen.yaml

This lab uses:

    ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.152.0

## Cleanup

Delete telemetry generator jobs:

    kubectl delete job telemetrygen-traces telemetrygen-metrics -n "$NAMESPACE" --ignore-not-found

Delete the lab namespace and all lab resources:

    kubectl delete namespace "$NAMESPACE" --ignore-not-found

This removes:

- Dedicated lab OpenTelemetry Collector
- ServiceMonitor
- telemetrygen jobs
- Optional lab app resources

This does not remove:

- kube-prometheus-stack
- Prometheus
- Grafana
- The shared monitoring namespace
- The shared OpenTelemetry Collector in the monitoring namespace

Keep the monitoring stack if you plan to continue with later observability or troubleshooting labs.

## What you completed

You completed:

- Dedicated OpenTelemetry Collector deployment
- OTLP receiver setup
- Prometheus exporter setup
- ServiceMonitor integration
- Telemetry generation with telemetrygen
- Collector log verification
- Prometheus query verification
- Grafana visualization

This completes the current Practitioner lab flow.
