# Monitoring and Observability

This document explains the monitoring and observability design used in this AKS DevOps Practice Platform.

## Purpose

Monitoring helps you understand the health of the Kubernetes cluster.

Observability helps you understand what is happening inside applications.

This platform includes both:

- Cluster monitoring
- Application observability foundation

## Installed components

The platform currently uses:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter
- OpenTelemetry Collector

## Prometheus

Prometheus collects and stores metrics.

In this platform, Prometheus collects metrics from:

- Kubernetes nodes
- Kubernetes pods
- Kubernetes services
- kube-state-metrics
- node-exporter
- Prometheus Operator resources

Prometheus is useful for:

- Querying metrics
- Alerting
- Cluster health visibility
- Application metrics in future labs

## Grafana

Grafana is used for dashboards and visualization.

Grafana can show:

- Cluster dashboards
- Node metrics
- Pod metrics
- Workload health
- Prometheus metrics
- Future application metrics

## Alertmanager

Alertmanager handles alerts from Prometheus.

It can be used later for:

- Email alerts
- Slack or Teams alerts
- Routing alerts by severity
- Grouping alerts
- Silencing alerts

In the current platform, Alertmanager is installed as part of the monitoring foundation.

## kube-state-metrics

kube-state-metrics exposes Kubernetes object state as metrics.

Examples:

- Deployment status
- Pod status
- Node status
- Replica counts
- Job status

Prometheus scrapes these metrics.

## node-exporter

node-exporter exposes Linux node-level metrics.

Examples:

- CPU usage
- Memory usage
- Disk usage
- Network metrics

This helps monitor AKS worker nodes.

## OpenTelemetry Collector

OpenTelemetry Collector is used as the application telemetry pipeline foundation.

It can receive:

- Metrics
- Traces
- Logs

Current receiver endpoints inside the cluster:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317
    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318

Port 4317 is normally used for OTLP gRPC.

Port 4318 is normally used for OTLP HTTP.

## Why Prometheus/Grafana and OpenTelemetry?

They solve different problems.

Prometheus and Grafana:

    Cluster monitoring
    Metrics collection
    Dashboards
    Alerting

OpenTelemetry:

    Application telemetry
    Standardized metrics, traces, and logs
    Export to different observability backends

Both are useful for a complete observability learning platform.

## Safe default access model

Grafana, Prometheus, and Alertmanager are not exposed publicly by default.

They are ClusterIP services.

This is intentional.

Why?

Monitoring tools can expose sensitive cluster information such as:

- Namespace names
- Pod names
- Service names
- Node information
- Internal labels
- Application metrics

Public exposure without authentication is risky.

## Access Grafana locally

Get Grafana admin password:

    kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana \
      -o jsonpath="{.data.admin-password}" | base64 -d ; echo

Port-forward Grafana:

    kubectl port-forward svc/kube-prometheus-stack-grafana \
      -n monitoring \
      3000:80

Open:

    http://localhost:3000

Login:

    Username: admin
    Password: <password-from-command>

## Access Prometheus locally

Port-forward Prometheus:

    kubectl port-forward svc/kube-prometheus-stack-prometheus \
      -n monitoring \
      9090:9090

Open:

    http://localhost:9090

Test query:

    up

## Access Alertmanager locally

Port-forward Alertmanager:

    kubectl port-forward svc/kube-prometheus-stack-alertmanager \
      -n monitoring \
      9093:9093

Open:

    http://localhost:9093

## Helm values files

Monitoring values are stored in:

    platform-addons/monitoring/kube-prometheus-stack-values.yaml
    platform-addons/monitoring/otel-collector-values.yaml

These files make the monitoring setup repeatable.

## kube-prometheus-stack values

The platform keeps services internal:

    grafana.service.type = ClusterIP
    prometheus.service.type = ClusterIP
    alertmanager.service.type = ClusterIP

This supports the safe local access model.

## OpenTelemetry Collector values

The OpenTelemetry Collector is installed as a Deployment.

It uses:

- OTLP receiver
- memory_limiter processor
- batch processor
- debug exporter
- health check extension
- resource requests and limits

Resource requests and limits are important for stable operation.

Example resource baseline:

    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

## Verify monitoring pods

Run:

    kubectl get pods -n monitoring

Expected components:

    alertmanager-kube-prometheus-stack-alertmanager-0
    kube-prometheus-stack-grafana
    kube-prometheus-stack-kube-state-metrics
    kube-prometheus-stack-operator
    kube-prometheus-stack-prometheus-node-exporter
    prometheus-kube-prometheus-stack-prometheus-0
    otel-collector-opentelemetry-collector

All should be Running.

## Verify monitoring services

Run:

    kubectl get svc -n monitoring

Expected services:

    kube-prometheus-stack-grafana
    kube-prometheus-stack-prometheus
    kube-prometheus-stack-alertmanager
    kube-prometheus-stack-kube-state-metrics
    kube-prometheus-stack-prometheus-node-exporter
    otel-collector-opentelemetry-collector

Service type should be ClusterIP.

## Verify OpenTelemetry Collector

Check pod:

    kubectl get pods -n monitoring | grep otel

Check service:

    kubectl get svc -n monitoring | grep otel

Check logs:

    kubectl logs -n monitoring deploy/otel-collector-opentelemetry-collector

Expected ports:

    4317
    4318

## Application telemetry endpoint

Applications inside the cluster can send telemetry to:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317

or:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318

Use 4317 for OTLP gRPC.

Use 4318 for OTLP HTTP.

## Optional secure Grafana exposure

For learning, use port-forward.

For advanced labs, Grafana can be exposed securely through Gateway API.

Do not expose Grafana publicly without:

- HTTPS
- Authentication
- Access control
- SSO or OAuth
- Network restrictions

Prometheus should usually remain internal.

## Future observability labs

Planned labs:

- Access Grafana with port-forward
- Run basic Prometheus queries
- Create a simple dashboard
- Create a basic alert
- Send application telemetry to OpenTelemetry Collector
- Instrument a .NET API
- Instrument a Node.js API
- Export traces to Tempo or Jaeger
- Expose Grafana securely with Gateway API

## Common issues

### Grafana password not found

Check the secret:

    kubectl get secret -n monitoring | grep grafana

Then retry:

    kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana \
      -o jsonpath="{.data.admin-password}" | base64 -d ; echo

### Port-forward fails

Check if another process is using the port.

Try another local port:

    kubectl port-forward svc/kube-prometheus-stack-grafana \
      -n monitoring \
      3001:80

Then open:

    http://localhost:3001

### OpenTelemetry Collector not receiving telemetry

Check:

    kubectl logs -n monitoring deploy/otel-collector-opentelemetry-collector

Common causes:

- Wrong endpoint
- Wrong protocol
- App not instrumented
- Collector config issue
- Network policy blocking traffic

## Best practices

- Keep monitoring services internal by default
- Use port-forward for learning access
- Add authentication before exposing Grafana
- Keep Prometheus internal
- Set resource requests and limits for OpenTelemetry Collector
- Use application-specific telemetry labs instead of forcing all apps to use one pattern
