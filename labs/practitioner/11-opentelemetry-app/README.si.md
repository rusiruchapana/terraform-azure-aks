# Practitioner Lab 11 - OpenTelemetry App

මෙම lab එකෙන් OpenTelemetry telemetry dedicated OpenTelemetry Collector එකකට යවලා, resulting metrics Prometheus සහ Grafana වලින් visualize කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone AKS observability lab එකක්.

Default path එක `telemetrygen` කියන public OpenTelemetry telemetry generator image එක use කරනවා.

ඒ නිසා custom container image එකක් build/push කරන්න අවශ්‍ය නැහැ.

මෙම lab එක use කරන්නේ:

- AKS
- Existing Prometheus Operator හෝ kube-prometheus-stack
- මෙම lab එකට dedicated OpenTelemetry Collector එකක්
- Prometheus scraping සඳහා ServiceMonitor එකක්
- Traces සහ metrics generate කරන්න `telemetrygen` jobs
- Metric queries සඳහා Prometheus
- Visualization සඳහා Grafana

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `practitioner-otel` කියන Kubernetes namespace එකක්
- `otel-lab-collector` කියන dedicated OpenTelemetry Collector deployment එකක්
- `4317` සහ `4318` ports වල OTLP traffic receive කරන collector service එකක්
- `8889` port එකේ collector metrics endpoint එකක්
- Prometheus collector එක scrape කරන්න ඉඩ දෙන ServiceMonitor එකක්
- Traces සහ metrics සඳහා telemetry generator jobs
- Prometheus තුළ OpenTelemetry-generated metrics
- OpenTelemetry metrics සඳහා basic Grafana query හෝ panel එකක්

මෙම lab එක shared OpenTelemetry Collector එකක් modify කරන්නේ නැහැ.

මෙම lab එක default ලෙස custom application image එකක් අවශ්‍ය කරන්නේ නැහැ.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- OpenTelemetry එක AKS monitoring stack එකකට fit වෙන විදිය
- Lab එකක් සඳහා dedicated OpenTelemetry Collector එකක් deploy කරන විදිය
- OTLP telemetry gRPC සහ HTTP හරහා receive කරන විදිය
- Prometheus scrape කරන්න collector metrics expose කරන විදිය
- Prometheus Operator සඳහා ServiceMonitor create කරන විදිය
- telemetrygen use කරලා test traces සහ metrics generate කරන විදිය
- Collector logs තුළ telemetry verify කරන විදිය
- Prometheus තුළ OpenTelemetry metrics query කරන විදිය
- Grafana තුළ OpenTelemetry metrics visualize කරන විදිය
- Lab resources safely clean up කරන විදිය

## Lab architecture

Default flow එක:

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

Existing monitoring stack එක සාමාන්‍යයෙන් තියෙන්නේ:

    monitoring

Prometheus සහ Grafana බොහෝ විට kube-prometheus-stack එකෙන් provide වෙනවා.

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- kubectl
- Helm
- Terminal එකක්
- Web browser එකක්
- Existing AKS cluster access
- Existing Prometheus Operator හෝ kube-prometheus-stack
- ServiceMonitor CRD installed වීම
- Grafana access
- telemetrygen image pull කරන්න AKS nodes වලට internet access

Optional custom app image path එකට අවශ්‍යයි:

- Docker
- Azure CLI
- Azure Container Registry හෝ වෙනත් container registry එකක්

මෙම lab එකට default ලෙස අවශ්‍ය නැහැ:

- Azure Container Registry
- Docker Desktop
- CI/CD platform
- Custom image build හෝ push

## Install required local tools

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

### Azure CLI for optional custom image path

Azure CLI අවශ්‍ය වෙන්නේ Azure Container Registry සමඟ optional custom image path එක use කරනවා නම් පමණයි.

Azure CLI install කරන්න:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Azure CLI verify කරන්න:

    az version

### Docker for optional custom image path

Docker අවශ්‍ය වෙන්නේ optional FastAPI app image එක build/push කරනවා නම් පමණයි.

Docker verify කරන්න:

    docker version

## Check local tools and cluster access

Continue කරන්න කලින් verify කරන්න:

    kubectl version --client
    helm version
    kubectl get nodes

Lab variables set කරන්න:

    NAMESPACE="practitioner-otel"
    MONITORING_NAMESPACE="monitoring"
    PROMETHEUS_RELEASE="kube-prometheus-stack"

Verify කරන්න:

    echo "$NAMESPACE"
    echo "$MONITORING_NAMESPACE"
    echo "$PROMETHEUS_RELEASE"

## Files in this lab

මෙම lab එකේ files:

    app/
      Custom image path එකකට optional FastAPI app files

    manifests/
      Lab collector, ServiceMonitor, සහ telemetry generator සඳහා Kubernetes manifests

Files:

    manifests/namespace.yaml
    manifests/otel-collector.yaml
    manifests/servicemonitor.yaml
    manifests/telemetrygen.yaml
    app/Dockerfile
    app/main.py
    app/requirements.txt

Default lab path එක manifests සහ public telemetrygen image එක පමණක් use කරනවා.

app folder එක optional.

## Verify existing monitoring

Prometheus, Grafana, සහ existing monitoring components check කරන්න:

    kubectl get pods -n "$MONITORING_NAMESPACE"
    kubectl get svc -n "$MONITORING_NAMESPACE"
    helm list -n "$MONITORING_NAMESPACE"

ServiceMonitor support check කරන්න:

    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

Expected:

    ServiceMonitor CRD exists

ServiceMonitor CRD missing නම්, continue කරන්න කලින් Prometheus Operator හෝ kube-prometheus-stack install කරන්න.

kube-prometheus-stack සඳහා:

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    kubectl create namespace "$MONITORING_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    helm upgrade --install "$PROMETHEUS_RELEASE" prometheus-community/kube-prometheus-stack \
      --namespace "$MONITORING_NAMESPACE"

Installation එකෙන් පස්සේ verify කරන්න:

    kubectl get pods -n "$MONITORING_NAMESPACE"
    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

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

    kubectl rollout status deployment/otel-lab-collector -n "$NAMESPACE" --timeout=180s

Collector listen කරන ports:

    4317 for OTLP gRPC
    4318 for OTLP HTTP
    8889 for Prometheus metrics scraping

## Create the ServiceMonitor

ServiceMonitor එක apply කරන්න:

    kubectl apply -f labs/practitioner/11-opentelemetry-app/manifests/servicemonitor.yaml

Verify කරන්න:

    kubectl get servicemonitor -n "$NAMESPACE"
    kubectl describe servicemonitor otel-lab-collector -n "$NAMESPACE"

ServiceMonitor එක Prometheus scrape කරන්න ඉඩ දෙන endpoint එක:

    http://otel-lab-collector.practitioner-otel.svc.cluster.local:8889/metrics

## Verify the Prometheus target

Prometheus port-forward කරන්න:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-prometheus \
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

Logs වල telemetrygen මේ endpoint එකට connect වුණා කියලා පේන්න ඕන:

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
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-prometheus \
      9090:9090

Prometheus open කරන්න:

    http://localhost:9090

Query කරන්න:

    gen

මේ වගේ metric එකක් පේන්න ඕන:

    gen{job="otel-lab-collector", namespace="practitioner-otel", exported_job="practitioner-otel-telemetrygen"}

මෙයත් query කරන්න පුළුවන්:

    {job="otel-lab-collector"}

Port-forward stop කරන්න:

    Ctrl+C

## Visualize metrics in Grafana

Grafana port-forward කරන්න:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-grafana \
      3000:80

Grafana admin password එක ගන්න:

    kubectl get secret \
      --namespace "$MONITORING_NAMESPACE" \
      ${PROMETHEUS_RELEASE}-grafana \
      -o jsonpath="{.data.admin-password}" | base64 --decode; echo

Grafana open කරන්න:

    http://localhost:3000

Login:

    Username: admin
    Password: secret command එකෙන් ලැබුණු password එක use කරන්න

Grafana password ask නොකර open වෙනවා සහ edit options disabled නම්, sign out වෙලා නැවත `admin` ලෙස login වෙන්න.

Incognito හෝ private browser window එකක් use කරන්නත් පුළුවන්.

Grafana තුළ:

    Explore
      |
      v
    Select Prometheus datasource
      |
      v
    Run this query:

    gen{job="otel-lab-collector"}

Dashboard panel එකක් create කරන්න:

    Query: gen{job="otel-lab-collector"}
    Panel title: OpenTelemetry Generated Metric

මෙයත් use කරන්න පුළුවන්:

    sum(gen{job="otel-lab-collector"})

Port-forward stop කරන්න:

    Ctrl+C

## Optional: custom application image path

Default lab path එක telemetrygen use කරනවා, ඒ නිසා custom image අවශ්‍ය නැහැ.

මෙම optional path එක simple FastAPI app එක use කරනවා:

    app/

ඔයාගේ environment එක container registry එකකට image push කරන්න allow කරනවා නම් විතරක් මේ optional path එක use කරන්න.

Example variables:

    ACR_NAME="<your-acr-name>"
    ACR_LOGIN_SERVER="<your-acr-login-server>"
    IMAGE_NAME="practitioner-otel-app"
    IMAGE_TAG="v1"
    IMAGE="$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"

ACR values හොයාගන්න:

    az acr list --query "[].{name:name, resourceGroup:resourceGroup, loginServer:loginServer}" -o table

ACR login කරන්න:

    az acr login --name "$ACR_NAME"

Apple Silicon Mac එකකින් AKS Linux nodes සඳහා build සහ push කරන්න:

    docker buildx build \
      --platform linux/amd64 \
      -t "$IMAGE" \
      labs/practitioner/11-opentelemetry-app/app \
      --push

Docker push timeout වුණොත්, ACR network access check කරන්න:

    curl -I https://$ACR_LOGIN_SERVER/v2/

ඔයාගේ subscription එකේ Azure ACR Tasks disabled නම්, `az acr build` fail වෙන්න පුළුවන්.

එහෙම නම් default telemetrygen path එකෙන් continue කරන්න.

## Troubleshooting

### Check lab namespace resources

Lab resources සියල්ල check කරන්න:

    kubectl get all -n "$NAMESPACE"

### Collector logs do not show telemetry

Collector logs check කරන්න:

    kubectl logs deployment/otel-lab-collector -n "$NAMESPACE" --tail=120

telemetrygen jobs check කරන්න:

    kubectl get jobs -n "$NAMESPACE"
    kubectl logs job/telemetrygen-traces -n "$NAMESPACE"
    kubectl logs job/telemetrygen-metrics -n "$NAMESPACE"

### ServiceMonitor target does not appear

ServiceMonitor check කරන්න:

    kubectl get servicemonitor -n "$NAMESPACE"
    kubectl describe servicemonitor otel-lab-collector -n "$NAMESPACE"

Prometheus targets check කරන්න:

    kubectl port-forward \
      --namespace "$MONITORING_NAMESPACE" \
      svc/${PROMETHEUS_RELEASE}-prometheus \
      9090:9090

ඊට පස්සේ open කරන්න:

    http://localhost:9090/targets

Look for:

    otel-lab-collector

### ServiceMonitor CRD is missing

CRDs check කරන්න:

    kubectl get crd | grep -E 'servicemonitors|podmonitors|prometheusrules'

Missing නම්, Prometheus Operator හෝ kube-prometheus-stack install කරන්න.

### telemetrygen image pull fails

telemetrygen image pull errors ආවොත්, image tag එක මෙතන check කරන්න:

    labs/practitioner/11-opentelemetry-app/manifests/telemetrygen.yaml

Current image එක:

    ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.152.0

AKS nodes වලට GitHub Container Registry එකෙන් images pull කරන්න පුළුවන්දත් check කරන්න.

### Grafana service name is different

මෙම service එක නැත්නම්:

    svc/${PROMETHEUS_RELEASE}-grafana

Services list කරන්න:

    kubectl get svc -n "$MONITORING_NAMESPACE"

ඔයාගේ cluster එකේ තියෙන Grafana service name එක use කරන්න.

### Prometheus service name is different

මෙම service එක නැත්නම්:

    svc/${PROMETHEUS_RELEASE}-prometheus

Services list කරන්න:

    kubectl get svc -n "$MONITORING_NAMESPACE"

ඔයාගේ cluster එකේ තියෙන Prometheus service name එක use කරන්න.

## Cleanup

Telemetry generator jobs delete කරන්න:

    kubectl delete job telemetrygen-traces telemetrygen-metrics -n "$NAMESPACE" --ignore-not-found

Lab namespace එක සහ lab resources සියල්ල delete කරන්න:

    kubectl delete namespace "$NAMESPACE" --ignore-not-found

මෙයින් remove වෙන දේවල්:

- Dedicated lab OpenTelemetry Collector
- Lab ServiceMonitor
- telemetrygen jobs
- `practitioner-otel` namespace එකේ optional lab resources

මෙම lab එකෙන් create නොකළ shared monitoring resources delete කරන්න එපා.

Delete කරන්න එපා:

- kube-prometheus-stack
- Prometheus Operator CRDs
- shared monitoring namespace
- මෙම lab namespace එකෙන් පිටත shared OpenTelemetry Collector

## Security cleanup

Optional custom image path එක use කළා නම්, තව අවශ්‍ය නැති image tags remove කරන්න.

Registry credentials හෝ local environment secrets commit කරන්න එපා.

Production සඳහා prefer කරන්න:

- Least privilege access
- Environment හෝ workload boundary අනුව separate collectors
- Controlled telemetry retention
- Secure OTLP endpoints
- Collectors සඳහා resource limits
- Service team එක own කරන dashboards සහ alerts

## Important note

මෙය learning lab එකක්.

මෙම lab එක OpenTelemetry source එකකින් collector එකකට telemetry යන විදියත්, එතැනින් Prometheus සහ Grafana වලට metrics යන විදියත් demonstrate කරනවා.

Production සඳහා OpenTelemetry architecture එක ownership, scaling, security, retention, සහ alerting requirements අනුව design කරන්න.
