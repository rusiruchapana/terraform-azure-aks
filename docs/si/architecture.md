# Architecture එක

මෙම document එකෙන් AKS DevOps Practice Platform එකේ high-level architecture එක පැහැදිලි කරනවා.

මෙම project එකේ goal එක තමයි DevOps, CI/CD, GitOps, monitoring, secrets, සහ platform engineering practice සඳහා reusable AKS platform එකක් ලබාදීම.

## High-level architecture

    User / Learner / Engineer
              |
              v
    Git repository
              |
              v
    Terraform environment
              |
              v
    Azure infrastructure
              |
              v
    AKS platform
              |
              v
    Platform add-ons
              |
              v
    Application labs සහ CI/CD/GitOps workflows

## Main components

මෙම platform එක layers 4කින් සමන්විතයි:

1. Terraform infrastructure layer
2. AKS platform layer
3. Platform add-ons layer
4. Labs සහ application delivery layer

## 1. Terraform infrastructure layer

Azure infrastructure create කරන්න Terraform use කරනවා.

Terraform-managed resources:

- Resource Group
- Virtual Network
- AKS subnet
- NAT Gateway
- AKS cluster
- System node pool
- User node pool
- Managed identities
- Optional Azure Container Registry
- Optional Azure Key Vault
- Azure role assignments
- AKS OIDC issuer සහ Workload Identity settings

Terraform code එක reusable modules විදියට organize කරලා තියෙනවා.

    modules/
    environments/
      dev/
      qa/
      prod/

## 2. AKS platform layer

මෙම project එක Kubernetes platform එක ලෙස AKS use කරනවා.

Cluster එකේ node pools දෙකක් තියෙනවා:

- System node pool
- User node pool

System node pool එක Kubernetes සහ platform components සඳහා.

User node pool එක application workloads සඳහා.

Applications සාමාන්‍යයෙන් user node pool එකේ run වෙන්න ඕන.

## 3. Network architecture

AKS සඳහා Virtual Network එකක් සහ subnet එකක් use කරනවා.

AKS subnet එකට NAT Gateway attach කරලා තියෙනවා.

ඒකෙන් cluster nodes වල outbound internet traffic stable public IP එකකින් යනවා.

High-level network flow:

    AKS nodes
        |
        v
    AKS subnet
        |
        v
    NAT Gateway
        |
        v
    Internet

Inbound application traffic Gateway API සහ NGINX Gateway Fabric මගින් handle කරනවා.

## 4. Container registry architecture

මෙම platform එකට optional Azure Container Registry create කරන්න පුළුවන්.

ACR enable නම්:

    enable_acr = true

Terraform create කරන දේවල්:

- Azure Container Registry
- AKS සඳහා AcrPull role assignment

ACR disable නම්:

    enable_acr = false

Cluster එකට තවම public images pull කරන්න පුළුවන්:

- Docker Hub
- GitHub Container Registry
- Quay
- වෙනත් public registries

Private external registries සඳහා Kubernetes imagePullSecret අවශ්‍යයි.

## 5. Gateway architecture

මෙම platform එක Gateway API සහ NGINX Gateway Fabric use කරනවා.

Platform එකේ තියෙන්නේ:

- Gateway API CRDs
- NGINX Gateway Fabric controller
- nginx කියන GatewayClass
- public-gateway කියන shared Gateway
- platform-gateway namespace එක

Application teams එක් app එකකට එක LoadBalancer එකක් create කරන්න ඕන නැහැ.

ඒ වෙනුවට apps shared Gateway එකට HTTPRoute resources attach කරනවා.

Traffic flow:

    Internet
        |
        v
    Azure Load Balancer
        |
        v
    NGINX Gateway Fabric
        |
        v
    Gateway API public-gateway
        |
        v
    HTTPRoute
        |
        v
    Kubernetes Service
        |
        v
    Application Pods

Shared Gateway:

    platform-gateway/public-gateway

## 6. Secrets සහ identity architecture

මෙම platform එක Azure Key Vault සහ AKS Workload Identity use කරනවා.

Recommended pattern:

    Kubernetes ServiceAccount
              |
              v
    AKS Workload Identity
              |
              v
    Azure User Assigned Managed Identity
              |
              v
    Azure Key Vault RBAC
              |
              v
    Key Vault Secret

Key Vault access Azure RBAC මගින් control වෙනවා.

Important roles:

- Key Vault Secrets Officer: humans/operators secrets create/update කරන්න
- Key Vault Secrets User: applications secrets read කරන්න

Core platform එක Workload Identity enable කරනවා. හැබැයි app-specific identities සහ federated credentials application/lab level එකෙන් create කරන එක හොඳයි.

## 7. Monitoring සහ observability architecture

මෙම platform එක monitoring සහ observability foundation එකක් include කරනවා.

Installed components:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter
- OpenTelemetry Collector

Cluster monitoring:

    Kubernetes nodes සහ pods
              |
              v
    Prometheus
              |
              v
    Grafana dashboards

Application telemetry:

    Application
        |
        v
    OpenTelemetry SDK
        |
        v
    OpenTelemetry Collector
        |
        v
    Observability backend

Cluster එක ඇතුළේ current Collector endpoints:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317
    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318

Grafana සහ Prometheus public expose කරලා නැහැ.

Local access සඳහා port-forward use කරන්න.

## 8. Environment architecture

Repository එකේ environment templates තුනක් තියෙනවා:

- dev
- qa
- prod

Purpose:

- dev: low-cost learning සහ experimentation
- qa: staging සහ testing
- prod: production-style reference configuration

Each environment එකේ තියෙනවා:

- main.tf
- variables.tf
- outputs.tf
- providers.tf
- backend.tf.example
- terraform.tfvars.example

Real local files commit කරන්න එපා:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- .terraform/

## 9. CI/CD සහ GitOps architecture

මෙම platform එක CI/CD සහ GitOps learning paths දෙකම support කරනවා.

CI/CD flow:

    Developer push
        |
        v
    CI/CD pipeline
        |
        v
    Build container image
        |
        v
    Push image to registry
        |
        v
    Deploy to AKS

Planned CI/CD examples:

- GitHub Actions
- GitLab CI/CD
- Azure DevOps
- Jenkins

GitOps flow:

    Git repository
        |
        v
    Argo CD හෝ Flux
        |
        v
    AKS cluster desired state

GitOps examples තියෙන්නේ:

    gitops/
    gitops/

## 10. Terraform manage කරන දේවල් vs add-ons manage කරන දේවල්

Terraform Azure infrastructure manage කරනවා.

Terraform manage කරන දේවල්:

- Resource Group
- Network
- NAT Gateway
- AKS
- ACR
- Key Vault
- Managed identities
- Azure role assignments

Helm හෝ Kubernetes manifests platform add-ons manage කරනවා.

Add-ons:

- Gateway API
- NGINX Gateway Fabric
- Prometheus සහ Grafana
- OpenTelemetry Collector

Future GitOps labs වලදී මේ add-ons GitOps-managed configuration එකකට move කරන්න පුළුවන්.

## 11. Design goals

මෙම platform එක design කරලා තියෙන්නේ:

- Beginner-friendly වෙන්න
- Real DevOps practice සඳහා useful වෙන්න
- Projects අතර reusable වෙන්න
- App-agnostic වෙන්න
- Registry-agnostic වෙන්න
- CI/CD සහ GitOps labs සඳහා suitable වෙන්න
- Professional platform engineering patterns සඳහා extendable වෙන්න

## 12. Important design decisions

මෙම platform එකේ important decisions:

- ACR optional
- Docker Hub සහ වෙනත් public registries support
- legacy ingress-nginx default නොකර Gateway API use කිරීම
- Grafana සහ Prometheus default ClusterIP
- Key Vault RBAC mode
- Secure app identity සඳහා Workload Identity enabled
- Demo app identity resources core platform එකේ permanent තියාගෙන නැහැ
- dev, qa, prod separate environment templates
