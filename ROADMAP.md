# Terraform Azure AKS Learning Roadmap

This roadmap defines the learning flow for this AKS DevOps Practice Platform.

The goal of this project is to build a practical path from Kubernetes and AKS fundamentals to production-style platform engineering, DevSecOps, GitOps, observability, incident response, AIOps visibility, and final capstone delivery.

## Guiding principles

- Keep labs hands-on and practical.
- Explain why each tool or pattern is used.
- Keep beginner, practitioner, professional, and capstone learning levels clear.
- Keep public documentation learner-facing.
- Avoid personal laptop paths, private emails, secrets, tokens, and live environment-specific IP addresses.
- Use variables and placeholders where environment-specific values are needed.
- Separate learning-mode examples from production recommendations.
- Prefer safe, low-cost defaults where possible.
- Use GitOps for desired Kubernetes state where appropriate.
- Use monitoring, alerts, and verification instead of assuming deployments are healthy.

## Learning tracks

The project is organized into these learning tracks:

1. Beginner AKS and Kubernetes basics
2. Practitioner CI/CD, DevSecOps, secrets, monitoring, and telemetry
3. Professional GitOps, release strategies, troubleshooting, and security hardening
4. AIOps-assisted incident analysis and remediation concepts
5. Enterprise AKS capstone project

## Beginner track

The beginner track focuses on understanding AKS and Kubernetes basics.

Topics include:

- AKS cluster access
- kubectl basics
- namespaces
- pods
- deployments
- services
- basic troubleshooting
- safe cleanup

## Practitioner track

Practitioner labs focus on CI/CD tools, DevSecOps basics, secrets, monitoring, and application telemetry.

Current practitioner sequence:

1. GitHub Actions to AKS
2. GitHub Actions DevSecOps checks
3. GitLab CI/CD to AKS
4. GitLab CI/CD DevSecOps checks
5. Azure DevOps to AKS
6. Azure DevOps DevSecOps checks
7. Jenkins to AKS
8. Jenkins DevSecOps checks
9. Key Vault and Workload Identity
10. Monitoring basics
11. OpenTelemetry application telemetry

## Professional track

Professional labs focus on production-style delivery patterns.

Current professional sequence:

1. Argo CD GitOps
2. Flux GitOps
3. Dev to QA to Prod promotion
4. Blue/green deployment
5. Canary deployment
6. Incident troubleshooting
7. Security hardening

## AIOps learning track

The AIOps learning track focuses on AI-assisted and monitoring-assisted operations.

Current focus areas:

- incident evidence collection
- root cause explanation
- safe remediation recommendations
- GitHub PR remediation
- human approval before applying fixes
- GitOps validation before recovery
- Prometheus alert detection
- Alertmanager visibility
- AIOps dashboard visibility

The AIOps approach in this project does not replace engineering judgment. It supports evidence-based troubleshooting and safer remediation workflows.

## Enterprise AKS capstone project

The Enterprise AKS capstone is the main end-to-end project in this repository.

Start here:

    capstone/README.md

The capstone uses three repositories:

    terraform-azure-aks
    aks-capstone-store-app
    aks-capstone-gitops

## Capstone stage roadmap

Completed capstone stages:

| Stage | Area |
|---|---|
| 00 | Project overview |
| 01 | Terraform platform provisioning |
| 02 | Kubernetes access and verification |
| 03 | Argo CD GitOps foundation |
| 04 | Gateway API and NGINX Gateway Fabric |
| 05 | Monitoring, alerting, and notifications |
| 06 | OpenTelemetry observability |
| 07 | Capstone Store Dev GitOps deployment |
| 08 | Dev app expansion, capacity planning, cost guardrails, and Terraform import |
| 09 | Dev app supporting components |
| 10 | ACR image build and GitOps deploy |
| 11 | GitHub Actions ACR build foundation |
| 12 | CI updates GitOps and deploys Dev |
| 13 | App DevSecOps CI gates |
| 14 | GitOps manifest validation pipeline |
| 15 | End-to-end Dev release verification |
| 16 | Dev to QA to Prod promotion workflow |
| 17 | Pipeline visibility and release flow |
| 18 | Terraform platform CI and pipeline visibility |
| 19 | AIOps PR remediation |
| 20 | AIOps Incident Dashboard UI |
| 21 | AIOps alert detection and dashboard visibility |
| 22 | Load testing and observability verification |

## Capstone capabilities

The capstone currently demonstrates:

- Terraform-based AKS platform provisioning
- remote Terraform state backend
- Azure Container Registry integration
- AKS node pool management
- Argo CD GitOps
- Gateway API and NGINX Gateway Fabric
- Prometheus, Grafana, and Alertmanager
- OpenTelemetry observability foundation
- Dev, QA, and Prod GitOps environments
- GitHub Actions CI/CD
- Gitleaks secret scanning
- Trivy source and image scanning
- GitOps manifest validation with Kustomize and kubeconform
- Dev release verification
- Dev to QA to Prod image promotion
- Terraform platform CI with TFLint and Checkov
- AIOps PR remediation workflow
- Prometheus-based AIOps alert detection
- AIOps Dashboard active incident visibility
- Docker-based k6 load testing
- Grafana and Prometheus observability verification

## Platform architecture principles

The project follows these architecture principles:

- Terraform manages platform infrastructure.
- Application CI builds and scans container images.
- GitOps manages Kubernetes desired state.
- Argo CD applies environment manifests.
- DevSecOps gates run before deployment or promotion.
- Monitoring verifies runtime health.
- Alerts detect operational issues.
- AIOps workflows use evidence and human-approved PR remediation.
- Load testing verifies application and platform behavior under traffic.

## Repository separation

The capstone uses repository separation to model real-world responsibilities.

Platform repository:

    terraform-azure-aks

Purpose:

    platform infrastructure
    Terraform modules and root configurations
    platform CI
    capstone documentation
    local UI helper scripts

Application repository:

    aks-capstone-store-app

Purpose:

    application source code
    application CI
    image build and scan
    ACR push
    Dev GitOps update
    Dev release verification

GitOps repository:

    aks-capstone-gitops

Purpose:

    Kubernetes manifests
    Kustomize overlays
    Argo CD applications
    Dev, QA, and Prod desired state
    GitOps validation
    promotion workflow
    AIOps monitoring and dashboard manifests

## DevSecOps maturity path

The DevSecOps path evolves in stages.

Practitioner level:

- basic source scanning
- basic image scanning
- learning-mode scan results
- simple pipeline quality checks

Professional level:

- strict CI gates
- secrets scanning
- dependency scanning
- container image scanning
- GitOps validation
- Kubernetes manifest validation
- IaC scanning
- documented exception handling

Capstone level:

- integrated app CI quality gates
- GitOps validation pipeline
- Terraform platform CI
- promotion workflow
- end-to-end release verification
- observability verification
- incident visibility and remediation workflow

## Observability maturity path

The observability path evolves in stages.

Foundation:

- Prometheus installed
- Grafana installed
- Alertmanager installed
- kube-state-metrics installed
- node-exporter installed

Platform verification:

- dashboards accessible
- Prometheus metrics queryable
- Alertmanager alerts visible
- Kubernetes pod, deployment, node, and network metrics visible

Operational verification:

- AIOps alert detection
- AIOps Dashboard active incident visibility
- load testing with k6
- Grafana metrics during load
- Prometheus query verification after load
- Kubernetes health check after load

## Recommended future improvements

Future improvements may include:

- DNS and HTTPS/TLS for the Gateway
- production-style certificate management
- stronger environment protection rules
- notification integration for alerts
- improved application-level HTTP metrics
- gateway-level request and latency dashboards
- authenticated UI access
- architecture diagrams
- final public demo guide
- cost and cleanup guide
- public release readiness checklist

## Documentation quality rules

Public documentation should follow these rules:

- Use learner-facing language.
- Avoid private discussion notes.
- Avoid personal local paths.
- Avoid private emails.
- Avoid live environment-specific IP addresses.
- Avoid secrets or tokens.
- Use placeholders and variables for environment-specific values.
- Keep commands copy/paste friendly.
- Explain what each stage proves.
- Include verification steps.
- Include cleanup steps where needed.
