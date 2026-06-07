# Stage 22 - Load Testing and Observability Verification

මෙම stage එකේදී Capstone Store application එකට controlled load test එකක් run කරලා, Grafana සහ Prometheus මගින් platform behavior observe කරනවා.

මෙහි අරමුණ application එකට traffic යද්දී Kubernetes metrics, pod health, network traffic, CPU, memory, සහ deployment stability බලන්න පුළුවන්ද කියලා verify කිරීමයි.

## මේ stage එකේදී කරන දේ

මෙම stage එකේදී:

1. store-front application URL එක verify කරනවා.
2. Docker-based k6 load test එකක් run කරනවා.
3. Grafana dashboards වලින් pod / namespace metrics බලනවා.
4. Prometheus queries වලින් CPU, memory, network metrics verify කරනවා.
5. Load test එකෙන් පස්සේ pod health සහ deployment health verify කරනවා.
6. Application එක load යටතේ stable ද කියලා confirm කරනවා.

## Architecture flow

    User / k6 load generator
      ↓
    Gateway public endpoint
      ↓
    Gateway API / NGINX Gateway Fabric
      ↓
    HTTPRoute
      ↓
    store-front Service
      ↓
    store-front Pod
      ↓
    Metrics collected by kubelet / cAdvisor / kube-state-metrics
      ↓
    Prometheus
      ↓
    Grafana dashboards

## ඇයි මේ stage එක වැදගත්ද?

Application එක deploy වුණා කියලා platform එක production-style ready කියන්න බැහැ.

Load test එකෙන් අපි verify කරන්නේ:

    application එක traffic handle කරනවද
    HTTP 200 response ලැබෙනවද
    response time acceptable ද
    pod restart වෙනවද
    memory / CPU abnormal වැඩි වෙනවද
    network traffic Grafana වල පේනවද
    Prometheus metrics query කරන්න පුළුවන්ද

## Tools used

මෙම stage එකේ tools:

| Tool | Purpose |
|---|---|
| k6 | Load test run කිරීම |
| Docker | Local k6 install නැතුව k6 run කිරීම |
| Grafana | Metrics dashboards බලන්න |
| Prometheus | Metrics query කිරීම |
| Kubernetes | Pod / deployment health verify කිරීම |
| Gateway API | Application external traffic path verify කිරීම |

## Why Docker k6?

Local machine එකේ k6 install නැතිනම් Docker image එකෙන් k6 run කරන්න පුළුවන්.

මෙහි වාසිය:

    local install අවශ්‍ය නැහැ
    repeatable test එකක් run කරන්න පුළුවන්
    test script එක simple JavaScript file එකක් ලෙස තබන්න පුළුවන්

## Prerequisites

මෙම stage එකට පෙර අවශ්‍ය දේවල්:

    AKS cluster running
    capstone-store-dev Synced / Healthy
    store-front pod Running
    Gateway API working
    Monitoring stack running
    Local UI helper scripts working
    Docker installed locally

Docker verify කරන්න:

    docker --version

## Local UI access

Platform repository එකෙන් local UIs start කරන්න:

    ./scripts/local-ui/start-local-uis.sh

Useful URLs:

    AIOps Dashboard: http://localhost:8088
    Grafana:         http://localhost:3000
    Prometheus:      http://localhost:9090
    Alertmanager:    http://localhost:9093

Grafana login:

    Username: admin
    Password: use the monitoring-grafana secret value

Password get කරන්න:

    kubectl get secret monitoring-grafana -n monitoring \
      -o jsonpath="{.data.admin-password}" | base64 --decode
    echo

## Verify Grafana dashboards

Grafana open කරන්න:

    http://localhost:3000

Useful dashboards:

    Kubernetes / Compute Resources / Namespace (Pods)
    Kubernetes / Compute Resources / Pod
    Kubernetes / Networking / Namespace (Pods)
    Kubernetes / Networking / Pod
    Kubernetes / Compute Resources / Node (Pods)

Recommended filters:

    Namespace: capstone-dev
    Pod: store-front
    Workload: store-front

Recommended time range:

    Last 15 minutes

Recommended refresh:

    5s or 10s

## Verify store-front application URL

GitOps repository එකේ application Gateway URL set කරන්න.

    GATEWAY_IP=$(kubectl get gateway -A -o jsonpath='{.items[0].status.addresses[0].value}')

    export TARGET_URL="http://${GATEWAY_IP}"

    echo "$TARGET_URL"

HTTP response verify කරන්න:

    curl -I "$TARGET_URL"

Expected:

    HTTP/1.1 200 OK

Note:

    Public IP එක documentation එකට commit කරන්න එපා. Local testing සඳහා variable එකක් ලෙස පමණක් use කරන්න.

## Create k6 load test script

Temporary file එකක් ලෙස k6 script එක create කරන්න:

    cat > /tmp/capstone-store-load-test.js <<'EOF_K6'
    import http from 'k6/http';
    import { check, sleep } from 'k6';

    export const options = {
      vus: 10,
      duration: '2m',
      thresholds: {
        http_req_failed: ['rate<0.05'],
        http_req_duration: ['p(95)<2000'],
      },
    };

    export default function () {
      const res = http.get(__ENV.TARGET_URL);

      check(res, {
        'status is 200': (r) => r.status === 200,
      });

      sleep(1);
    }
    EOF_K6

මෙම test එකේ meaning:

    10 virtual users
    2 minutes duration
    HTTP failure rate 5% ට අඩු විය යුතුයි
    p95 response time 2 seconds ට අඩු විය යුතුයි
    Every response HTTP 200 ද කියලා check කරනවා

## Run Docker k6 load test

Docker image එකෙන් k6 run කරන්න:

    docker run --rm -i \
      -e TARGET_URL="$TARGET_URL" \
      grafana/k6 run - < /tmp/capstone-store-load-test.js

Test එක run වෙන අතර Grafana වල metrics observe කරන්න.

## What to observe in Grafana

Grafana වල මෙම metrics බලන්න:

    store-front pod CPU usage
    store-front pod memory usage
    namespace CPU and memory
    network receive bytes
    network transmit bytes
    pod restarts
    node resource usage

Useful dashboard:

    Kubernetes / Compute Resources / Namespace (Pods)

Filter:

    Namespace: capstone-dev

තව useful dashboard:

    Kubernetes / Compute Resources / Pod

Filter:

    Namespace: capstone-dev
    Pod: store-front

## Expected k6 result

Successful test එකකදී expected results:

    HTTP checks 100% pass
    HTTP failed rate 0% හෝ threshold එකට අඩු
    p95 response time threshold එකට අඩු
    Application HTTP 200 return කරනවා
    Test complete වෙනවා

Example verified result:

    Total requests: 1140
    HTTP checks succeeded: 100%
    HTTP failed rate: 0.00%
    Average response time: about 53 ms
    p95 response time: about 59 ms
    Max response time: about 101 ms
    Thresholds passed

## Verify Kubernetes health after test

Load test එකෙන් පස්සේ store-front pod health check කරන්න:

    kubectl get pods -n capstone-dev | grep store-front

Expected:

    store-front pod 1/1 Running
    restarts 0

Deployment health check කරන්න:

    kubectl get deployment store-front -n capstone-dev

Expected:

    READY 1/1
    AVAILABLE 1

Recent events බලන්න:

    kubectl get events -n capstone-dev --sort-by='.lastTimestamp' | tail -30

Expected:

    no CrashLoopBackOff
    no OOMKilled
    no unhealthy events

## Prometheus CPU query

store-front CPU usage query කරන්න:

    curl -sG "http://localhost:9090/api/v1/query" \
      --data-urlencode 'query=sum(rate(container_cpu_usage_seconds_total{namespace="capstone-dev",pod=~"store-front.*",container!="",image!=""}[2m]))' \
      | python3 -m json.tool

Result එකේ value එක CPU usage rate එක පෙන්වනවා.

## Prometheus memory query

store-front memory usage query කරන්න:

    curl -sG "http://localhost:9090/api/v1/query" \
      --data-urlencode 'query=sum(container_memory_working_set_bytes{namespace="capstone-dev",pod=~"store-front.*",container!="",image!=""})' \
      | python3 -m json.tool

Result එක bytes වලින් memory working set එක පෙන්වනවා.

## Prometheus network receive query

store-front network receive rate query කරන්න:

    curl -sG "http://localhost:9090/api/v1/query" \
      --data-urlencode 'query=sum(rate(container_network_receive_bytes_total{namespace="capstone-dev",pod=~"store-front.*"}[2m]))' \
      | python3 -m json.tool

## Prometheus network transmit query

store-front network transmit rate query කරන්න:

    curl -sG "http://localhost:9090/api/v1/query" \
      --data-urlencode 'query=sum(rate(container_network_transmit_bytes_total{namespace="capstone-dev",pod=~"store-front.*"}[2m]))' \
      | python3 -m json.tool

## Verified Prometheus metrics example

Verified test එකේදී Prometheus queries successful වුණා.

Example values:

    CPU rate:
    0.0001015 cores approximately

    Memory:
    3674112 bytes approximately

    Network receive:
    314 bytes/sec approximately

    Network transmit:
    307 bytes/sec approximately

මෙම exact values environment එක, time, traffic, and scrape timing අනුව වෙනස් විය හැක.

## What this proves

මෙම stage එකෙන් prove කළේ:

    Gateway URL traffic receive කරනවා
    k6 load test successful වෙනවා
    Application HTTP 200 return කරනවා
    Grafana metrics visible වෙනවා
    Prometheus metrics queryable වෙනවා
    store-front pod stable වෙනවා
    deployment healthy වෙනවා
    no restarts / no unhealthy events

## Troubleshooting

### k6 command not found

Local k6 install නැත්නම් Docker k6 use කරන්න:

    docker run --rm -i \
      -e TARGET_URL="$TARGET_URL" \
      grafana/k6 run - < /tmp/capstone-store-load-test.js

### Docker image pull slow නම්

First run එකේදී Docker image pull වෙන නිසා ටිකක් time ගන්න පුළුවන්.

    grafana/k6:latest

### TARGET_URL empty නම්

Gateway IP variable එක නැවත set කරන්න:

    GATEWAY_IP=$(kubectl get gateway -A -o jsonpath='{.items[0].status.addresses[0].value}')
    export TARGET_URL="http://${GATEWAY_IP}"
    echo "$TARGET_URL"

### curl 200 නොඑන්නේ නම්

Gateway සහ HTTPRoute check කරන්න:

    kubectl get gateway -A
    kubectl get httproute -A

store-front Service සහ Pod check කරන්න:

    kubectl get svc store-front -n capstone-dev
    kubectl get pods -n capstone-dev | grep store-front

### Grafana metrics නොපේනවා නම්

Prometheus targets check කරන්න:

    http://localhost:9090

Prometheus UI එකේ:

    Status
    Targets

Monitoring pods check කරන්න:

    kubectl get pods -n monitoring

### Prometheus query zsh error දුන්නොත්

URL encoded query එක direct paste කරනවාට වඩා curl -G සහ --data-urlencode use කරන්න.

## Cleanup

Temporary k6 script එක delete කරන්න:

    rm -f /tmp/capstone-store-load-test.js

Local UI port-forwards stop කරන්න:

    ./scripts/local-ui/stop-local-uis.sh

## What you completed

මෙම stage එකෙන් ඔබ complete කළේ:

    Docker k6 load test run කිරීම
    Gateway URL load test කිරීම
    Grafana dashboards වල metrics observe කිරීම
    Prometheus metrics query කිරීම
    store-front pod health verify කිරීම
    deployment health verify කිරීම
    post-load stability confirm කිරීම
