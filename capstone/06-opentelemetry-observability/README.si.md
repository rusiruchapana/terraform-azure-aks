# Stage 06 - OpenTelemetry Observability

## මේ stage එකේදී මොකක්ද වෙන්නේ?

මෙම stage එකේදී AKS platform එකට OpenTelemetry Collector install කරනවා.

මෙම stage එකේදී full application tracing තවම enable කරන්නේ නැහැ.

මුලින් telemetry pipeline foundation එක හදනවා.

## OpenTelemetry කියන්නේ මොකක්ද?

OpenTelemetry කියන්නේ application telemetry collect කරන්න තියෙන open standard framework එකක්.

Telemetry කියන්නේ application එක run වෙද්දී එන signals.

Main signals:

- metrics
- logs
- traces

## Metrics, logs, traces වෙනස

### Metrics

Metrics කියන්නේ numeric measurements.

Examples:

- request count
- error count
- latency
- CPU usage
- memory usage

### Logs

Logs කියන්නේ application එක run වෙද්දී print වෙන events/messages.

Examples:

- user login failed
- database connection failed
- order created
- exception stack trace

### Traces

Traces කියන්නේ request එකක් service එකකින් service එකකට යන journey එක.

Microservices app එකක request එකක් මෙහෙම යන්න පුළුවන්:

frontend
→ product service
→ order service
→ database
→ queue

Trace එකෙන් request එක slow වුණේ කොතනද, fail වුණේ කොතනද කියලා බලන්න පුළුවන්.

## OpenTelemetry Collector කියන්නේ මොකක්ද?

OpenTelemetry Collector කියන්නේ telemetry receive, process, and export කරන middle layer එකක්.

සරලව:

Application telemetry යවනවා
→ Collector receive කරනවා
→ Collector process කරනවා
→ backend tools වලට export කරනවා

Backends examples:

- Prometheus
- Grafana Tempo
- Jaeger
- Loki
- Azure Monitor
- Datadog

මෙම stage එකේදී Collector debug exporter සහ Prometheus exporter use කරනවා.

## ඇයි Collector එකක් ඕන?

App එකෙන් directly හැම monitoring backend එකකටම data යවන එක maintain කරන්න අමාරුයි.

Collector එකක් තිබ්බාම:

- app telemetry එක standard endpoint එකකට යවනවා
- backend change කළත් app code ලොකු විදිහට change කරන්න ඕන නැහැ
- batching, filtering, processing කරන්න පුළුවන්
- metrics/logs/traces central pipeline එකකට ගන්න පුළුවන්

## Architecture flow

මෙම stage එකේ flow එක:

Application / future capstone services
→ OTLP gRPC or HTTP
→ OpenTelemetry Collector
→ debug exporter / Prometheus exporter
→ Prometheus / future tracing backend

Current Collector endpoints:

- OTLP gRPC: 4317
- OTLP HTTP: 4318
- internal metrics: 8888
- Prometheus exporter: 8889

## Prometheus සමඟ connection එක

Collector expose කරන metrics Prometheus scrape කරන්න ServiceMonitor එකක් create කරනවා.

Flow:

OpenTelemetry Collector metrics
→ ServiceMonitor
→ Prometheus
→ Grafana dashboards

## AIOps සමඟ connection එක

AIOps වලට root cause analyse කරන්න evidence ඕන.

OpenTelemetry future app telemetry වලින් මේවා දෙන්න පුළුවන්:

- request latency
- error rate
- failed service calls
- dependency latency
- trace path
- which service failed

Prometheus metrics + OpenTelemetry traces එකට combine කළාම AIOps analysis strong වෙනවා.

## Commands used in this stage

Helm repo add කිරීම:

    helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
    helm repo update

Collector install කිරීම:

    helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
      --namespace observability \
      --create-namespace \
      --values platform/opentelemetry/opentelemetry-collector-values.yaml \
      --wait \
      --timeout 10m

Verify කිරීම:

    kubectl get pods -n observability
    kubectl get svc -n observability
    kubectl logs -n observability deploy/otel-collector-opentelemetry-collector --tail=80

ServiceMonitor verify කිරීම:

    kubectl get servicemonitor -n observability

## Expected result

observability namespace එකේ OpenTelemetry Collector pod එක Running විය යුතුයි.

Collector services expose විය යුතුයි:

- 4317 OTLP gRPC
- 4318 OTLP HTTP
- 8888 internal metrics
- 8889 Prometheus exporter

ServiceMonitor එක create වී තිබිය යුතුයි.

## Troubleshooting

### Collector pod Pending නම්

Node capacity බලන්න:

    kubectl get nodes
    kubectl describe pod -n observability <pod-name>

### Collector CrashLoopBackOff නම්

Logs බලන්න:

    kubectl logs -n observability deploy/otel-collector-opentelemetry-collector --tail=100

Usually config syntax issue එකක් විය හැක.

### Prometheus scrape නොකරන්නේ නම්

ServiceMonitor label check කරන්න.

මෙම project එකේ kube-prometheus-stack release name එක:

    monitoring

ServiceMonitor label:

    release: monitoring

## Production meaning

Monitoring කියන්නේ current state බලන එක.

Observability කියන්නේ system එක ඇතුළේ මොකක්ද වෙන්නේ කියලා understand කරන්න පුළුවන් ability එක.

Prometheus metrics වලින් symptoms බලනවා.

OpenTelemetry traces/logs වලින් root cause හොයනවා.

AIOps layer එක මේ evidence use කරලා incident analysis කරනවා.

## මේ stage එකෙන් මතක තියාගන්න ඕන දේ

OpenTelemetry Collector කියන්නේ app telemetry pipeline එකේ central point එක.

මෙම stage එකෙන් future capstone app telemetry collect කරන්න foundation එක ready වෙනවා.
