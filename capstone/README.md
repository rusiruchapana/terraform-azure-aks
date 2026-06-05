# Enterprise AKS DevOps / DevSecOps / Platform Engineering Capstone

මෙම capstone project එකේදී Azure AKS මත production-style platform එකක් build කරනවා.

මෙය app එකක් deploy කරන simple lab එකක් නෙවෙයි. මේ project එකෙන් platform engineering, DevSecOps, GitOps, observability, secure secrets management, load testing, incident simulation, සහ AIOps remediation එකට connect වෙන end-to-end workflow එකක් build කරනවා.

## Tool stack

- Terraform
- Azure AKS
- Azure Container Registry
- Azure Key Vault
- Workload Identity
- GitHub Actions
- Argo CD
- Gateway API
- NGINX Gateway Fabric
- Prometheus
- Grafana
- OpenTelemetry
- SonarCloud
- Trivy
- k6
- Azure OpenAI
- AIOps GitHub PR remediation

## Repo model

මෙම capstone එක repos කිහිපයකින් manage කරනවා.

### Platform repo

`terraform-azure-aks`

මෙම repo එකේ Terraform infrastructure, shared platform setup, සහ capstone guides තියෙනවා.

### Application repo

`aks-capstone-store-app`

මෙම repo එකේ sample application source code තියෙනවා. App එක Azure-Samples/aks-store-demo sample එකෙන් inspired/adapted වෙනවා.

### GitOps repo

`aks-capstone-gitops`

මෙම repo එකේ Kubernetes manifests, environment overlays, සහ Argo CD applications තියෙනවා.

## Capstone stages

1. Project Overview and Architecture
2. Terraform Platform Provisioning
3. Kubernetes Access and Verification
4. Argo CD GitOps Foundation
5. Gateway API and NGINX Gateway Fabric
6. Monitoring with Prometheus and Grafana
7. OpenTelemetry Observability
8. Capstone Store Application Setup
9. DevSecOps CI Pipeline
10. GitOps Dev QA Prod Promotion
11. Key Vault and Workload Identity
12. k6 Load Testing
13. Incident Simulation
14. AIOps Incident Analysis
15. AIOps GitHub PR Remediation
16. Final Demo and Cleanup
