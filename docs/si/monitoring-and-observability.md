# Monitoring සහ Observability

මෙම document එකෙන් AKS DevOps Practice Platform එකේ monitoring සහ observability design එක පැහැදිලි කරනවා.

## Purpose

Monitoring මගින් Kubernetes cluster health එක තේරුම් ගන්න පුළුවන්.

Observability මගින් applications ඇතුළේ මොකක්ද වෙන්නේ කියලා තේරුම් ගන්න පුළුවන්.

මෙම platform එකේ දෙකම තියෙනවා:

- Cluster monitoring
- Application observability foundation

## Installed components

Platform එක currently use කරන components:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter
- OpenTelemetry Collector

## Prometheus

Prometheus metrics collect සහ store කරනවා.

මෙම platform එකේ Prometheus metrics collect කරන sources:

- Kubernetes nodes
- Kubernetes pods
- Kubernetes services
- kube-state-metrics
- node-exporter
- Prometheus Operator resources

Prometheus useful වෙන දේවල්:

- Metrics query කිරීම
- Alerting
- Cluster health visibility
- Future labs වල application metrics

## Grafana

Grafana dashboards සහ visualization සඳහා use කරනවා.

Grafana show කරන්න පුළුවන්:

- Cluster dashboards
- Node metrics
- Pod metrics
- Workload health
- Prometheus metrics
- Future application metrics

## Alertmanager

Alertmanager Prometheus alerts handle කරනවා.

Later use කරන්න පුළුවන්:

- Email alerts
- Slack හෝ Teams alerts
- Severity අනුව alerts route කිරීම
- Alerts group කිරීම
- Alerts silence කිරීම

Current platform එකේ Alertmanager monitoring foundation එකේ කොටසක්.

## kube-state-metrics

kube-state-metrics Kubernetes object state metrics ලෙස expose කරනවා.

Examples:

- Deployment status
- Pod status
- Node status
- Replica counts
- Job status

Prometheus මේ metrics scrape කරනවා.

## node-exporter

node-exporter Linux node-level metrics expose කරනවා.

Examples:

- CPU usage
- Memory usage
- Disk usage
- Network metrics

මේක AKS worker nodes monitor කරන්න help වෙනවා.

## OpenTelemetry Collector

OpenTelemetry Collector application telemetry pipeline foundation එක ලෙස use කරනවා.

එයට receive කරන්න පුළුවන්:

- Metrics
- Traces
- Logs

Cluster එක ඇතුළේ current receiver endpoints:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317
    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318

Port 4317 සාමාන්‍යයෙන් OTLP gRPC සඳහා.

Port 4318 සාමාන්‍යයෙන් OTLP HTTP සඳහා.

## Prometheus/Grafana සහ OpenTelemetry දෙකම ඇයි?

මේවා solve කරන problems වෙනස්.

Prometheus සහ Grafana:

    Cluster monitoring
    Metrics collection
    Dashboards
    Alerting

OpenTelemetry:

    Application telemetry
    Standardized metrics, traces, logs
    Different observability backends වලට export කිරීම

Complete observability learning platform එකකට දෙකම useful.

## Safe default access model

Grafana, Prometheus, Alertmanager public expose කරලා නැහැ.

ඒවා ClusterIP services.

මේක intentional.

ඇයි?

Monitoring tools sensitive cluster information expose කරන්න පුළුවන්:

- Namespace names
- Pod names
- Service names
- Node information
- Internal labels
- Application metrics

Authentication නැතුව public expose කිරීම risky.

## Grafana local access

Grafana admin password ගන්න:

    kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana \
      -o jsonpath="{.data.admin-password}" | base64 -d ; echo

Grafana port-forward කරන්න:

    kubectl port-forward svc/kube-prometheus-stack-grafana \
      -n monitoring \
      3000:80

Open කරන්න:

    http://localhost:3000

Login:

    Username: admin
    Password: <command එකෙන් ලැබුණු password එක>

## Prometheus local access

Prometheus port-forward කරන්න:

    kubectl port-forward svc/kube-prometheus-stack-prometheus \
      -n monitoring \
      9090:9090

Open කරන්න:

    http://localhost:9090

Test query:

    up

## Alertmanager local access

Alertmanager port-forward කරන්න:

    kubectl port-forward svc/kube-prometheus-stack-alertmanager \
      -n monitoring \
      9093:9093

Open කරන්න:

    http://localhost:9093

## Helm values files

Monitoring values files තියෙන්නේ:

    platform-addons/monitoring/kube-prometheus-stack-values.yaml
    platform-addons/monitoring/otel-collector-values.yaml

මේ files monitoring setup එක repeatable කරනවා.

## kube-prometheus-stack values

Platform එක services internal තියාගන්නවා:

    grafana.service.type = ClusterIP
    prometheus.service.type = ClusterIP
    alertmanager.service.type = ClusterIP

මේක safe local access model එක support කරනවා.

## OpenTelemetry Collector values

OpenTelemetry Collector Deployment එකක් ලෙස install කරලා තියෙනවා.

එය use කරනවා:

- OTLP receiver
- memory_limiter processor
- batch processor
- debug exporter
- health check extension
- resource requests and limits

Stable operation සඳහා resource requests සහ limits වැදගත්.

Example resource baseline:

    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

## Monitoring pods verify කිරීම

Run කරන්න:

    kubectl get pods -n monitoring

Expected components:

    alertmanager-kube-prometheus-stack-alertmanager-0
    kube-prometheus-stack-grafana
    kube-prometheus-stack-kube-state-metrics
    kube-prometheus-stack-operator
    kube-prometheus-stack-prometheus-node-exporter
    prometheus-kube-prometheus-stack-prometheus-0
    otel-collector-opentelemetry-collector

ඒවා Running වෙලා තියෙන්න ඕන.

## Monitoring services verify කිරීම

Run කරන්න:

    kubectl get svc -n monitoring

Expected services:

    kube-prometheus-stack-grafana
    kube-prometheus-stack-prometheus
    kube-prometheus-stack-alertmanager
    kube-prometheus-stack-kube-state-metrics
    kube-prometheus-stack-prometheus-node-exporter
    otel-collector-opentelemetry-collector

Service type ClusterIP වෙන්න ඕන.

## OpenTelemetry Collector verify කිරීම

Pod check කරන්න:

    kubectl get pods -n monitoring | grep otel

Service check කරන්න:

    kubectl get svc -n monitoring | grep otel

Logs check කරන්න:

    kubectl logs -n monitoring deploy/otel-collector-opentelemetry-collector

Expected ports:

    4317
    4318

## Application telemetry endpoint

Cluster එක ඇතුළේ applications telemetry send කරන්න පුළුවන් endpoint:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317

හෝ:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318

4317 OTLP gRPC සඳහා.

4318 OTLP HTTP සඳහා.

## Optional secure Grafana exposure

Learning සඳහා port-forward use කරන්න.

Advanced labs වලදී Grafana Gateway API හරහා securely expose කරන්න පුළුවන්.

මේවා නැතුව Grafana public expose කරන්න එපා:

- HTTPS
- Authentication
- Access control
- SSO හෝ OAuth
- Network restrictions

Prometheus සාමාන්‍යයෙන් internal තියාගන්න හොඳයි.

## Future observability labs

Planned labs:

- Grafana port-forward access
- Basic Prometheus queries
- Simple dashboard create කිරීම
- Basic alert create කිරීම
- Application telemetry OpenTelemetry Collector වෙත send කිරීම
- .NET API instrument කිරීම
- Node.js API instrument කිරීම
- Tempo හෝ Jaeger වෙත traces export කිරීම
- Gateway API හරහා Grafana securely expose කිරීම

## Common issues

### Grafana password ලැබෙන්නේ නැහැ

Secret check කරන්න:

    kubectl get secret -n monitoring | grep grafana

ඊට පස්සේ retry කරන්න:

    kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana \
      -o jsonpath="{.data.admin-password}" | base64 -d ; echo

### Port-forward fail වෙනවා

එම local port එක වෙන process එකක් use කරනවද බලන්න.

වෙන local port එකක් try කරන්න:

    kubectl port-forward svc/kube-prometheus-stack-grafana \
      -n monitoring \
      3001:80

ඊට පස්සේ open කරන්න:

    http://localhost:3001

### OpenTelemetry Collector telemetry receive කරන්නේ නැහැ

Check කරන්න:

    kubectl logs -n monitoring deploy/otel-collector-opentelemetry-collector

Common causes:

- Wrong endpoint
- Wrong protocol
- App instrument කරලා නැහැ
- Collector config issue
- Network policy block කරනවා

## Best practices

- Monitoring services default internal තියාගන්න
- Learning access සඳහා port-forward use කරන්න
- Grafana expose කරනවා නම් authentication add කරන්න
- Prometheus internal තියාගන්න
- OpenTelemetry Collector සඳහා resource requests සහ limits set කරන්න
- හැම app එකකටම එක pattern එක force නොකර application-specific telemetry labs use කරන්න
