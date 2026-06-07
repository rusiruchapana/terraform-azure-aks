# Stage 23 - Final Demo and Run Order

මෙම stage එකේදී capstone project එක demo කරන හරි order එක document කරනවා.

මෙහි අරමුණ වන්නේ project එක බලන කෙනෙකුට architecture, repositories, workflows, GitOps, monitoring, AIOps, and load testing flow එක පැහැදිලිව follow කරන්න පුළුවන් guide එකක් ලබාදීමයි.

## මේ stage එකේදී කරන දේ

මෙම stage එකේදී:

1. repositories තුනේ role එක explain කරනවා.
2. platform CI workflow එක show කරන order එක define කරනවා.
3. application CI/CD flow එක show කරන order එක define කරනවා.
4. GitOps validation and promotion workflow explain කරනවා.
5. Argo CD applications verify කරනවා.
6. monitoring UIs open කරනවා.
7. AIOps alert detection and dashboard visibility demo කරනවා.
8. load testing and observability proof explain කරනවා.
9. final health checks run කරනවා.

## Demo goal

මෙම demo එකෙන් prove කරන්නේ:

    Terraform platform code maintain වෙනවා.
    Application CI build/scan/push/deploy flow එක තියෙනවා.
    GitOps repository desired state manage කරනවා.
    Argo CD apps Synced / Healthy වෙනවා.
    Dev / QA / Prod environments තියෙනවා.
    Monitoring stack working.
    AIOps alert detection working.
    AIOps Dashboard active incident visibility working.
    Load test run කරලා observability metrics බලන්න පුළුවන්.
    Application load පසුත් stable.

## Repository overview

මෙම capstone project එක repositories තුනකින් explain කරන්න.

## 1. Platform repository

Repository:

    terraform-azure-aks

මෙම repo එකේ තියෙන්නේ:

    Terraform platform infrastructure
    AKS platform setup
    platform CI
    local UI helper scripts
    capstone guides

Demo කරන දේවල්:

    root README.md
    capstone/README.md
    Terraform Platform CI
    local UI helper scripts
    capstone stage guides

## 2. Application repository

Repository:

    aks-capstone-store-app

මෙම repo එකේ තියෙන්නේ:

    application source code
    GitHub Actions application CI
    store-front image build
    security scans
    ACR push
    Dev GitOps update
    Dev release verification

Demo කරන workflows:

    Build store-front and deploy Dev via GitOps
    Verify Dev release end-to-end

Legacy workflow එක earlier-stage reference එකක් ලෙස පමණක් explain කරන්න:

    Legacy - Build store-front image to ACR

## 3. GitOps repository

Repository:

    aks-capstone-gitops

මෙම repo එකේ තියෙන්නේ:

    Kubernetes manifests
    Kustomize overlays
    Argo CD applications
    Dev / QA / Prod desired state
    GitOps validation workflow
    promotion workflow
    AIOps monitoring and dashboard manifests

Demo කරන workflows:

    Validate GitOps manifests
    Promote store-front image

## Recommended demo order

Project එක demo කරන විට හොඳ order එක:

1. Project overview
2. Repository model
3. Platform CI
4. Application CI/CD
5. GitOps validation
6. Dev / QA / Prod promotion
7. Argo CD application health
8. Monitoring UIs
9. AIOps alert visibility
10. Load testing and observability
11. Final health check

## Step 1 - Show project overview

Platform repository එකෙන් පටන් ගන්න:

    README.md
    ROADMAP.md
    capstone/README.md

Explain කරන්න:

    project purpose
    learning tracks
    capstone stage list
    repository separation
    current capabilities

## Step 2 - Show platform CI

GitHub Actions වල platform repository workflow එක show කරන්න:

    Terraform Platform CI

Explain කරන්න:

    Terraform format check
    Terraform init and validate
    TFLint
    Checkov scan
    platform CI summary

මෙම workflow එකෙන් prove කරන දේ:

    platform code quality gate එකක් තියෙනවා
    Terraform code validate වෙනවා
    IaC security scan run වෙනවා
    apply/destroy automatically කරන්නේ නැහැ

## Step 3 - Show application CI/CD

Application repository එක open කරන්න:

    aks-capstone-store-app

Main workflow:

    Build store-front and deploy Dev via GitOps

Explain කරන්න:

    release input validate කරනවා
    secret scan run කරනවා
    source security scan run කරනවා
    image local build කරනවා
    image security scan කරනවා
    image ACR එකට push කරනවා
    GitOps Dev overlay update කරනවා
    Argo CD Dev deployment trigger වෙනවා

Second workflow:

    Verify Dev release end-to-end

Explain කරන්න:

    ACR image exists ද බලනවා
    GitOps desired state correct ද බලනවා
    GitOps validation pass ද බලනවා
    Argo CD app Synced / Healthy ද බලනවා
    AKS deployment expected image use කරනවද බලනවා
    Gateway HTTP 200 verify කරනවා

## Step 4 - Show GitOps validation

GitOps repository එක open කරන්න:

    aks-capstone-gitops

Main workflow:

    Validate GitOps manifests

Explain කරන්න:

    YAML syntax validation
    Kustomize render
    kubeconform Kubernetes validation
    summary job

මෙම workflow එකෙන් prove කරන දේ:

    invalid YAML main branch එකට silently යන්නේ නැහැ
    rendered Kubernetes manifests validate වෙනවා
    Dev / QA / Prod / AIOps manifests safety check වෙනවා

## Step 5 - Show promotion workflow

GitOps repository workflow:

    Promote store-front image

Explain කරන්න:

    same image tag QA වලට promote කරනවා
    same image tag Prod වලට promote කරනවා
    build once, promote same image pattern එක follow කරනවා
    target environment overlay update වෙනවා
    GitOps validation run වෙනවා
    Argo CD sync වෙනවා

## Step 6 - Verify Argo CD applications

Run කරන්න:

    kubectl get applications -n argocd

Expected applications:

    capstone-namespaces
    capstone-store-dev
    capstone-store-qa
    capstone-store-prod
    capstone-aiops-demo
    capstone-aiops-dashboard
    capstone-aiops-monitoring

Expected state:

    Synced
    Healthy

Explain කරන්න:

    Argo CD GitOps desired state cluster එකට apply කරනවා.
    Synced කියන්නේ Git state සහ live state match වෙනවා.
    Healthy කියන්නේ resources runtime health OK කියලා.

## Step 7 - Start local UIs

Platform repository එකෙන් run කරන්න:

    ./scripts/local-ui/start-local-uis.sh

Status බලන්න:

    ./scripts/local-ui/status-local-uis.sh

Open URLs:

    AIOps Dashboard: http://localhost:8088
    Grafana:         http://localhost:3000
    Prometheus:      http://localhost:9090
    Alertmanager:    http://localhost:9093

Explain කරන්න:

    public exposure දීමක් නැහැ
    localhost port-forward only
    demo/testing සඳහා safe access method එකක්

## Step 8 - Show Monitoring UI

Grafana open කරන්න:

    http://localhost:3000

Useful dashboards:

    Kubernetes / Compute Resources / Namespace (Pods)
    Kubernetes / Compute Resources / Pod
    Kubernetes / Networking / Namespace (Pods)
    Kubernetes / Networking / Pod
    Kubernetes / Compute Resources / Node (Pods)

Filters:

    Namespace: capstone-dev
    Pod: store-front

Explain කරන්න:

    CPU metrics
    memory metrics
    network receive/transmit
    pod-level visibility
    namespace-level visibility

Prometheus open කරන්න:

    http://localhost:9090

Useful queries:

    up

    kube_pod_status_phase

    sum(rate(container_cpu_usage_seconds_total{namespace="capstone-dev",pod=~"store-front.*",container!="",image!=""}[2m]))

    sum(container_memory_working_set_bytes{namespace="capstone-dev",pod=~"store-front.*",container!="",image!=""})

Alertmanager open කරන්න:

    http://localhost:9093

Explain කරන්න:

    active alerts
    alert routing visibility
    incident signal layer

## Step 9 - Show AIOps alert detection

AIOps demo alert name:

    AIOpsDemoServiceHasNoEndpoints

Explain කරන්න:

    aiops-demo Service එක තියෙනවා.
    නමුත් ready EndpointSlice endpoint එකක් නැති නම් Prometheus alert fire වෙනවා.
    Alertmanager alert පෙන්වනවා.
    AIOps Dashboard active incident පෙන්වනවා.

Verify Prometheus alert API:

    curl -s "http://localhost:9090/api/v1/alerts"

AIOps Dashboard:

    http://localhost:8088

Expected normal state:

    Current AIOps Status:
    No Active Incident

Test incident state:

    Current AIOps Status:
    Active Incident Detected

## Step 10 - Show load testing proof

Docker verify කරන්න:

    docker --version

Target URL set කරන්න:

    GATEWAY_IP=$(kubectl get gateway -A -o jsonpath='{.items[0].status.addresses[0].value}')
    export TARGET_URL="http://${GATEWAY_IP}"
    curl -I "$TARGET_URL"

Expected:

    HTTP/1.1 200 OK

Load test script:

    /tmp/capstone-store-load-test.js

Docker k6 run:

    docker run --rm -i \
      -e TARGET_URL="$TARGET_URL" \
      grafana/k6 run - < /tmp/capstone-store-load-test.js

Explain verified result:

    10 virtual users
    2 minutes
    1140 requests
    100% HTTP 200 checks
    0% failed requests
    p95 around 59 ms
    thresholds passed

## Step 11 - Show post-load health

Run කරන්න:

    kubectl get pods -n capstone-dev | grep store-front

Expected:

    store-front pod 1/1 Running
    restarts 0

Deployment check:

    kubectl get deployment store-front -n capstone-dev

Expected:

    READY 1/1
    AVAILABLE 1

Events check:

    kubectl get events -n capstone-dev --sort-by='.lastTimestamp' | tail -30

Expected:

    no unhealthy events

## Step 12 - Show Prometheus post-load metrics

CPU query:

    curl -sG "http://localhost:9090/api/v1/query" \
      --data-urlencode 'query=sum(rate(container_cpu_usage_seconds_total{namespace="capstone-dev",pod=~"store-front.*",container!="",image!=""}[2m]))' \
      | python3 -m json.tool

Memory query:

    curl -sG "http://localhost:9090/api/v1/query" \
      --data-urlencode 'query=sum(container_memory_working_set_bytes{namespace="capstone-dev",pod=~"store-front.*",container!="",image!=""})' \
      | python3 -m json.tool

Network receive query:

    curl -sG "http://localhost:9090/api/v1/query" \
      --data-urlencode 'query=sum(rate(container_network_receive_bytes_total{namespace="capstone-dev",pod=~"store-front.*"}[2m]))' \
      | python3 -m json.tool

Network transmit query:

    curl -sG "http://localhost:9090/api/v1/query" \
      --data-urlencode 'query=sum(rate(container_network_transmit_bytes_total{namespace="capstone-dev",pod=~"store-front.*"}[2m]))' \
      | python3 -m json.tool

Explain කරන්න:

    Prometheus metrics queryable.
    Grafana dashboards visible.
    Application stable.
    Load test passed.

## Final demo message

Demo එක අවසානයේ explain කරන්න:

    This project demonstrates a production-style AKS platform workflow:
    Terraform provisions the platform.
    GitHub Actions builds and verifies application releases.
    GitOps manages Kubernetes desired state.
    Argo CD applies and tracks cluster state.
    DevSecOps gates validate source, image, and manifests.
    Prometheus and Grafana provide observability.
    Alertmanager provides alert visibility.
    AIOps Dashboard shows incident state.
    k6 verifies application behavior under load.

## Final health check

Platform repository:

    git status

GitOps repository:

    git status
    gh run list --workflow="validate-gitops-manifests.yml" --limit 5
    kubectl get applications -n argocd

Application repository:

    git status
    gh workflow list

Expected:

    repositories clean
    latest workflows successful
    Argo CD apps Synced / Healthy
    main workflows active

## Cleanup after demo

Stop local UI port-forwards:

    ./scripts/local-ui/stop-local-uis.sh

Remove temporary k6 file if needed:

    rm -f /tmp/capstone-store-load-test.js

Do not delete Azure resources unless you are intentionally ending the lab or project.

## What you completed

මෙම stage එකෙන් ඔබ complete කළේ:

    final demo order define කිරීම
    repository responsibilities explain කිරීම
    workflow demo order explain කිරීම
    Argo CD verification flow explain කිරීම
    monitoring UI demo flow explain කිරීම
    AIOps alert visibility demo flow explain කිරීම
    load testing proof explain කිරීම
    final health check commands document කිරීම
