# Practitioner Lab 11 - OpenTelemetry App

මෙම lab එකෙන් OpenTelemetry telemetry dedicated OpenTelemetry Collector එකකට යවලා, එයින් ලැබෙන metrics Prometheus සහ Grafana වලින් visualize කරන විදිය ඉගෙන ගන්නවා.

Default path එක `telemetrygen` කියන public OpenTelemetry telemetry generator image එක use කරනවා. ඒ නිසා custom container image එකක් build/push කරන්න අවශ්‍ය නැහැ.

Flow එක:

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

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- OpenTelemetry එක AKS monitoring stack එකකට fit වෙන විදිය
- Lab එකකට dedicated OpenTelemetry Collector එකක් deploy කරන විදිය
- OTLP telemetry gRPC හරහා receive කරන විදිය
- Prometheus scrape කරන්න collector metrics expose කරන විදිය
- Prometheus Operator සඳහා ServiceMonitor එකක් create කරන විදිය
- telemetrygen use කරලා test traces සහ metrics generate කරන විදිය
- Collector logs වල telemetry verify කරන විදිය
- Prometheus වල OpenTelemetry metrics query කරන විදිය
- Grafana වල OpenTelemetry metrics visualize කරන විදිය
- Lab resources safely clean up කරන විදිය

## Architecture

මෙම lab එක dedicated namespace එකක් use කරනවා:

    practitioner-otel

Lab resources:

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

Existing monitoring stack එක තියෙන්නේ:

    monitoring

Prometheus සහ Grafana දෙන්නේ kube-prometheus-stack එකෙන්.

මෙම lab එක monitoring namespace එකේ shared OpenTelemetry Collector එක modify කරන්නේ නැහැ.

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- Azure CLI
- kubectl
- Existing AKS cluster
- Existing kube-prometheus-stack
- Prometheus Operator CRDs
- Grafana access
- telemetrygen image pull කරන්න AKS nodes වලට internet access

Kubernetes access check කරන්න:

    kubectl get nodes

Monitoring stack check කරන්න:

    kubectl get pods -n monitoring
    helm list -n monitoring

Prometheus Operator CRDs check කරන්න:

    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

## Lab files

මෙම lab එකේ files:

    app/
      Custom image path එකකට optional FastAPI app files

    manifests/
      Lab collector, ServiceMonitor, telemetry generator සඳහා Kubernetes manifests

    scripts/
      අවශ්‍ය නම් පස්සේ helper scripts add කරන්න පුළුවන්

Files:

    manifests/namespace.yaml
    manifests/otel-collector.yaml
    manifests/servicemonitor.yaml
    manifests/telemetrygen.yaml
    app/Dockerfile
    app/main.py
    app/requirements.txt

## Set lab variables

ඔයාගේ environment එකට values set කරන්න:

    NAMESPACE="practitioner-otel"
    MONITORING_NAMESPACE="monitoring"

## Verify existing monitoring

Prometheus, Grafana, existing monitoring components check කරන්න:

    kubectl get pods -n "$MONITORING_NAMESPACE"
    kubectl get svc -n "$MONITORING_NAMESPACE"
    helm list -n "$MONITORING_NAMESPACE"

ServiceMonitor support check කරන්න:

    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

ServiceMonitor CRD missing නම්, Practitioner Lab 10 complete කරලා kube-prometheus-stack install කරන්න.

## Create the lab namespace

Namespace එක apply කරන්න:

    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/namespace.yaml

Verify කරන්න:

    kubectl get ns "$NAMESPACE"

## Deploy the dedicated OpenTelemetry Collector

Collector manifest එක apply කරන්න:

    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/otel-collector.yaml

Verify කරන්න:

    kubectl get pods -n "$NAMESPACE"
    kubectl get svc -n "$NAMESPACE"

Collector Running වෙනකම් wait කරන්න:

    kubectl rollout status deployment/otel-lab-collector -n "$NAMESPACE"

Collector එක listen කරන්නේ:

    4317 for OTLP gRPC
    4318 for OTLP HTTP
    8889 for Prometheus metrics scraping

## Create the ServiceMonitor

ServiceMonitor එක apply කරන්න:

    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/servicemonitor.yaml

Verify කරන්න:

    kubectl get servicemonitor -n "$NAMESPACE"

ServiceMonitor එක Prometheus ට මෙය scrape කරන්න ඉඩ දෙනවා:

    http://otel-lab-collector.practitioner-otel.svc.cluster.local:8889/metrics

## Verify the Prometheus target

Prometheus port-forward කරන්න:

    kubectl port-forward \
      --namespace monitoring \
      svc/kube-prometheus-stack-prometheus \
      9090:9090

Prometheus open කරන්න:

    http://localhost:9090/targets

Search කරන්න:

    otel-lab-collector

Expected result:

    serviceMonitor/practitioner-otel/otel-lab-collector/0
    1 / 1 up

Port-forward stop කරන්න:

    Ctrl+C

## Generate OpenTelemetry telemetry

Telemetry generator jobs apply කරන්න:

    kubectl delete job telemetrygen-traces telemetrygen-metrics -n "$NAMESPACE" --ignore-not-found
    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/telemetrygen.yaml

Jobs සහ pods check කරන්න:

    kubectl get jobs -n "$NAMESPACE"
    kubectl get pods -n "$NAMESPACE"

telemetrygen logs check කරන්න:

    kubectl logs job/telemetrygen-traces -n "$NAMESPACE"
    kubectl logs job/telemetrygen-metrics -n "$NAMESPACE"

Logs වල telemetrygen connect වුණේ මේ endpoint එකට කියලා පේන්න ඕන:

    otel-lab-collector.practitioner-otel.svc.cluster.local:4317

## Verify collector logs

Lab collector logs check කරන්න:

    kubectl logs deployment/otel-lab-collector -n "$NAMESPACE" --tail=120

Expected log signals:

    Traces
    Metrics
    otelcol.signal

Metrics වලදී collector එක generated metrics සහ data points receive කරලා තියෙනවා කියලා පේන්න ඕන.

## Query metrics in Prometheus

Prometheus port-forward කරන්න:

    kubectl port-forward \
      --namespace monitoring \
      svc/kube-prometheus-stack-prometheus \
      9090:9090

Prometheus open කරන්න:

    http://localhost:9090

Query කරන්න:

    gen

මෙවගේ metric එකක් පේන්න ඕන:

    gen{job="otel-lab-collector", namespace="practitioner-otel", exported_job="practitioner-otel-telemetrygen"}

මෙයත් query කරන්න පුළුවන්:

    {job="otel-lab-collector"}

Port-forward stop කරන්න:

    Ctrl+C

## Visualize metrics in Grafana

Grafana port-forward කරන්න:

    kubectl port-forward \
      --namespace monitoring \
      svc/kube-prometheus-stack-grafana \
      3000:80

Grafana admin password එක ගන්න:

    kubectl get secret \
      --namespace monitoring \
      kube-prometheus-stack-grafana \
      -o jsonpath="{.data.admin-password}" | base64 --decode; echo

Grafana open කරන්න:

    http://localhost:3000

Login:

    Username: admin
    Password: secret command එකෙන් ගත්ත password එක use කරන්න

Grafana password නොඅහා open වෙලා edit options disabled නම්, sign out වෙලා `admin` user එකෙන් නැවත login වෙන්න. Incognito/private browser window එකක් use කළත් හරි.

Grafana වල:

    Explore
      |
      v
    Prometheus datasource select කරන්න
      |
      v
    මේ query එක run කරන්න:

    gen{job="otel-lab-collector"}

Dashboard panel එකක් create කරන්න:

    Query: gen{job="otel-lab-collector"}
    Panel title: OpenTelemetry Generated Metric

මෙයත් use කරන්න පුළුවන්:

    sum(gen{job="otel-lab-collector"})

Port-forward stop කරන්න:

    Ctrl+C

## Optional: custom application image path

මෙම lab එකේ simple FastAPI app එකක් තියෙනවා:

    app/

ඔයාගේ environment එක image push allow කරනවා නම්, ඒක build/push කරන්න පුළුවන්.

Example variables:

    ACR_NAME="<your-acr-name>"
    ACR_LOGIN_SERVER="<your-acr-login-server>"
    IMAGE_NAME="practitioner-otel-app"
    IMAGE_TAG="v1"
    IMAGE="$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"

ACR login කරන්න:

    az acr login --name "$ACR_NAME"

Apple Silicon Mac එකකින් AKS Linux nodes සඳහා build/push කරන්න:

    docker buildx build \
      --platform linux/amd64 \
      -t "$IMAGE" \
      labs/practitioner/11-opentelemetry-app/app \
      --push

Docker push timeout වෙනවා නම්, ACR network access check කරන්න:

    curl -I https://$ACR_LOGIN_SERVER/v2/

ඔයාගේ subscription එකේ Azure ACR Tasks disabled නම්, `az acr build` fail වෙන්න පුළුවන්. එහෙම නම් default telemetrygen path එකෙන් continue කරන්න.

## Troubleshooting

Lab namespace resources check කරන්න:

    kubectl get all -n "$NAMESPACE"

Collector logs check කරන්න:

    kubectl logs deployment/otel-lab-collector -n "$NAMESPACE" --tail=120

ServiceMonitor check කරන්න:

    kubectl get servicemonitor -n "$NAMESPACE"
    kubectl describe servicemonitor otel-lab-collector -n "$NAMESPACE"

Prometheus targets check කරන්න:

    kubectl port-forward \
      --namespace monitoring \
      svc/kube-prometheus-stack-prometheus \
      9090:9090

ඊට පස්සේ open කරන්න:

    http://localhost:9090/targets

Target එක down නම් මේවා check කරන්න:

- Service labels
- ServiceMonitor selector labels
- Service port name
- Collector pod readiness
- Collector metrics port

telemetrygen image pull errors ආවොත්, image tag එක මෙතන check කරන්න:

    manifests/telemetrygen.yaml

මෙම lab එක use කරන්නේ:

    ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.152.0

## Cleanup

Telemetry generator jobs delete කරන්න:

    kubectl delete job telemetrygen-traces telemetrygen-metrics -n "$NAMESPACE" --ignore-not-found

Lab namespace එක සහ lab resources සියල්ල delete කරන්න:

    kubectl delete namespace "$NAMESPACE" --ignore-not-found

මෙයින් remove වෙනවා:

- Dedicated lab OpenTelemetry Collector
- ServiceMonitor
- telemetrygen jobs
- Optional lab app resources

මෙයින් remove වෙන්නේ නැහැ:

- kube-prometheus-stack
- Prometheus
- Grafana
- shared monitoring namespace
- monitoring namespace එකේ shared OpenTelemetry Collector

පස්සේ observability හෝ troubleshooting labs continue කරනවා නම් monitoring stack එක keep කරන්න.

## What you completed

ඔයා complete කළා:

- Dedicated OpenTelemetry Collector deployment
- OTLP receiver setup
- Prometheus exporter setup
- ServiceMonitor integration
- telemetrygen මගින් telemetry generation
- Collector log verification
- Prometheus query verification
- Grafana visualization

මෙයින් current Practitioner lab flow එක complete වෙනවා.
