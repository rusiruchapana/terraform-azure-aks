# Enterprise AKS DevOps / DevSecOps / Platform Engineering Capstone

මෙම capstone project එකේදී Azure AKS මත production-style platform engineering, GitOps, DevSecOps, monitoring, release promotion, and AIOps remediation workflow එකක් build කරනවා.

මෙය app එකක් deploy කරන simple lab එකක් නෙවෙයි. මෙහි goal එක තමයි real-world platform engineering project එකක වගේ infrastructure, application delivery, GitOps, security checks, environment promotion, incident remediation, and UI visibility එකක් step by step build කිරීම.

## Current official project story

මෙම capstone එකේ official story එක:

1. Terraform මගින් AKS platform එක provision කිරීම
2. Argo CD මගින් GitOps foundation එක build කිරීම
3. Gateway API / NGINX Gateway Fabric setup කිරීම
4. Monitoring and observability setup කිරීම
5. Capstone Store app එක Dev environment එකට deploy කිරීම
6. App image ACR එකෙන් build/deploy කිරීම
7. GitHub Actions CI pipeline මගින් image build, scan, push, and GitOps update කිරීම
8. GitOps validation pipeline එකෙන් Kubernetes manifests validate කිරීම
9. Dev release end-to-end verify කිරීම
10. Dev → QA → Prod promotion workflow build කිරීම
11. Terraform platform CI and security gates add කිරීම
12. Pipeline visibility improve කිරීම
13. AIOps PR remediation workflow prove කිරීම
14. AIOps Incident Dashboard UI add කිරීම

## Important note about AIOps

මෙම project එකේ official AIOps scope එක දැනට:

    Evidence collection
    Root cause explanation
    GitHub PR remediation
    Human review and merge
    GitOps validation
    Argo CD recovery
    AIOps incident dashboard visibility

AIOps detector / automatic incident detection CronJob එක මෙම documentation story එකට දැනට include කරන්නේ නැහැ. එය future design එකක් ලෙස later redesign කළ හැක.

## Tool stack

- Terraform
- Azure AKS
- Azure Container Registry
- GitHub Actions
- Argo CD
- Gateway API
- NGINX Gateway Fabric
- Prometheus
- Grafana
- Alertmanager
- OpenTelemetry Collector
- Trivy
- Gitleaks
- Checkov
- TFLint
- kubeconform
- Kustomize
- AIOps PR remediation
- AIOps Incident Dashboard

## Repository model

මෙම capstone project එක repositories තුනකින් manage කරනවා.

### 1. Platform repository

Repository:

    terraform-azure-aks

Purpose:

    Terraform platform infrastructure
    AKS platform setup
    platform CI
    capstone Sinhala guides
    local UI helper scripts

### 2. Application repository

Repository:

    aks-capstone-store-app

Purpose:

    application source code
    GitHub Actions app CI
    Dev image build and scan
    ACR push
    Dev GitOps update
    Dev release verification

### 3. GitOps repository

Repository:

    aks-capstone-gitops

Purpose:

    Kubernetes manifests
    Kustomize overlays
    Argo CD applications
    Dev / QA / Prod desired state
    GitOps validation pipeline
    promotion workflow
    AIOps demo and dashboard manifests

## Environment model

The capstone application uses three environments:

    Dev
    QA
    Prod

Each environment is managed through GitOps overlays.

Main namespaces:

    capstone-dev
    capstone-qa
    capstone-prod
    capstone-aiops-demo
    capstone-aiops

## UI separation

මෙම capstone එකේ UI layers වෙනම තබාගන්නවා.

### Monitoring UI

Purpose:

    metrics
    alerts
    pod/node health
    observability dashboards

Examples:

    Grafana
    Prometheus
    Alertmanager

### Argo CD UI

Purpose:

    GitOps application sync status
    health status
    Git revision
    manifest diff
    sync history

### AIOps UI

Purpose:

    incident summary
    evidence
    root cause
    PR remediation action
    recovery status

AIOps Dashboard local URL:

    http://localhost:8088

Local UI helper scripts:

    scripts/local-ui/start-local-uis.sh
    scripts/local-ui/status-local-uis.sh
    scripts/local-ui/stop-local-uis.sh

## Capstone stage guide index

| Stage | Guide |
|---|---|
| 00 | [Project Overview](00-project-overview/README.si.md) |
| 01 | [Terraform Platform Provisioning](01-terraform-platform-provisioning/README.si.md) |
| 02 | [Kubernetes Access and Verification](02-kubernetes-access-and-verification/README.si.md) |
| 03 | [Argo CD GitOps Foundation](03-argocd-gitops-foundation/README.si.md) |
| 04 | [Gateway API and NGINX Gateway Fabric](04-gateway-api-nginx-gateway-fabric/README.si.md) |
| 05 | [Monitoring, Alerting, and Notifications](05-monitoring-alerting-notifications/README.si.md) |
| 06 | [OpenTelemetry Observability](06-opentelemetry-observability/README.si.md) |
| 07 | [Capstone Store Dev GitOps Deployment](07-capstone-store-dev-gitops-deployment/README.si.md) |
| 08 | [Dev App Expansion, Capacity Planning, Cost Guardrails, and Terraform Import](08-expand-dev-app-capacity-and-cost-guardrails/README.si.md) |
| 09 | [Dev App Supporting Components](09-add-dev-app-supporting-components/README.si.md) |
| 10 | [ACR Image Build and GitOps Deploy](10-acr-image-build-and-gitops-deploy/README.si.md) |
| 11 | [GitHub Actions ACR Build Foundation](11-github-actions-acr-build-foundation/README.si.md) |
| 12 | [CI Updates GitOps and Deploys Dev](12-ci-updates-gitops-and-deploys-dev/README.si.md) |
| 13 | [App DevSecOps CI Gates](13-app-devsecops-ci-gates/README.si.md) |
| 14 | [GitOps Manifest Validation Pipeline](14-gitops-manifest-validation-pipeline/README.si.md) |
| 15 | [End-to-End Dev Release Verification](15-end-to-end-dev-release-verification/README.si.md) |
| 16 | [Dev to QA to Prod Promotion Workflow](16-dev-qa-prod-promotion-workflow/README.si.md) |
| 17 | [Pipeline Visibility and Release Flow](17-pipeline-visibility-and-release-flow/README.si.md) |
| 18 | [Terraform Platform CI and Pipeline Visibility](18-terraform-platform-ci-and-pipeline-visibility/README.si.md) |
| 19 | [AIOps PR Remediation](19-aiops-pr-remediation/README.si.md) |
| 20 | [AIOps Incident Dashboard UI](20-aiops-incident-dashboard-ui/README.si.md) |

## Main workflows

### Platform repository workflows

Repository:

    terraform-azure-aks

Main workflow:

    Terraform Platform CI

Purpose:

    Terraform formatting
    Terraform init/validate
    TFLint
    Checkov IaC scan
    platform CI summary

### Application repository workflows

Repository:

    aks-capstone-store-app

Main workflows:

    Build store-front and deploy Dev via GitOps
    Verify Dev release end-to-end

Legacy workflow:

    Legacy - Build store-front image to ACR

The legacy workflow is kept for earlier-stage reference only. The main Dev workflow is the GitOps-based workflow.

### GitOps repository workflows

Repository:

    aks-capstone-gitops

Main workflows:

    Validate GitOps manifests
    Promote store-front image

Purpose:

    YAML validation
    Kustomize render
    kubeconform validation
    Dev / QA / Prod promotion

## Current stable checkpoint

At the current checkpoint:

    capstone-store-dev Synced / Healthy
    capstone-store-qa Synced / Healthy
    capstone-store-prod Synced / Healthy
    capstone-aiops-demo Synced / Healthy
    capstone-aiops-dashboard Synced / Healthy

AIOps Dashboard:

    http://localhost:8088

## Recommended demo flow

A good demo order:

1. Show platform repository structure
2. Show Terraform Platform CI
3. Show application CI workflow
4. Show GitOps validation workflow
5. Show Dev release verification workflow
6. Show QA/Prod promotion workflow
7. Show Argo CD applications
8. Show Monitoring UI
9. Show AIOps Dashboard UI
10. Explain AIOps PR remediation flow

## Cost and safety notes

This project can create Azure resources that cost money.

Important safety points:

    Keep budget alerts enabled.
    Avoid unnecessary public LoadBalancer services.
    Prefer ClusterIP for internal services.
    Stop local UI port-forwards when not needed.
    Clean up resources when the lab/project is finished.
    Keep Terraform state safe.
    Do not commit secrets, tokens, private IP-specific notes, or personal local paths.

## Next documentation tasks

Recommended next cleanup tasks:

    Update root README.md
    Update ROADMAP.md
    Add final workflow run order
    Add final cost and cleanup guide
    Add architecture diagrams
    Add final demo guide
