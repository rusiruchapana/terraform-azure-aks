# Stage 00 - Project Overview and Architecture

## මේ stage එකේදී මොකක්ද වෙන්නේ?

මෙම stage එකේදී අපි capstone project එකේ full picture එක තේරුම් ගන්නවා.

මෙය AKS cluster එකක් create කරන lab එකක් විතරක් නෙවෙයි. මේ project එක production-style platform engineering project එකක්.

සරලව කිව්වොත්:

Terraform වලින් Azure platform එක provision කරනවා.

GitHub Actions වලින් CI/CD සහ quality checks run කරනවා.

Argo CD වලින් GitOps deployment කරනවා.

Gateway API සහ NGINX Gateway Fabric වලින් traffic manage කරනවා.

Prometheus, Grafana, OpenTelemetry වලින් monitoring සහ observability setup කරනවා.

SonarCloud, Trivy වගේ tools වලින් DevSecOps quality gates add කරනවා.

AIOps controller එකෙන් incidents analyse කරලා GitHub PR remediation flow එකක් build කරනවා.

## ඇයි මේ project එක වැදගත්?

Real company එකක cloud platform එකක් කියන්නේ app එකක් run කරන server එකක් විතරක් නෙවෙයි.

Platform එකට මේවා ඕන:

- repeatable infrastructure
- secure secrets management
- controlled deployments
- monitoring dashboards
- alerts
- incident response
- rollback/recovery process
- security and quality checks
- clear environment promotion

මේ capstone එකෙන් ඒ සියල්ල step by step build කරනවා.

## Main architecture flow

User request එක application එකට එන්නේ මෙහෙමයි:

Internet
→ Azure Load Balancer
→ NGINX Gateway Fabric
→ Gateway API HTTPRoute
→ Kubernetes Service
→ Application Pods

Deployment flow එක මෙහෙමයි:

Developer code push කරනවා
→ GitHub Actions build/test/scan කරනවා
→ Docker image ACR එකට push කරනවා
→ GitOps repo update වෙනවා
→ Argo CD cluster එක sync කරනවා

Incident recovery flow එක මෙහෙමයි:

Incident එකක් වෙනවා
→ monitoring/AIOps evidence collect කරනවා
→ Azure OpenAI root cause analysis කරනවා
→ GitHub remediation PR එකක් create වෙනවා
→ human review කරලා merge කරනවා
→ Argo CD fixed Git state එක cluster එකට apply කරනවා

## Repo separation

මේ project එක repos 3කින් manage කරනවා.

### terraform-azure-aks

මෙය platform repo එක.

මෙහි තියෙන්නේ:

- Terraform infrastructure
- AKS platform setup
- capstone guides
- shared platform installation steps

### aks-capstone-store-app

මෙය application source code repo එක.

මෙහි තියෙන්නේ:

- sample app source code
- Dockerfiles
- app tests
- GitHub Actions app CI
- SonarCloud scan
- Trivy scan
- image build and push steps

### aks-capstone-gitops

මෙය GitOps repo එක.

මෙහි තියෙන්නේ:

- Kubernetes manifests
- dev / qa / prod overlays
- Argo CD applications
- Gateway routes
- app deployment desired state

## Sample application

මෙම capstone එකේ sample app එක Azure-Samples/aks-store-demo project එකෙන් inspired/adapted වෙනවා.

ඒක AKS සඳහා හදපු microservices demo app එකක්. මේ app එකෙන් store front, product service, order service, RabbitMQ, MongoDB වගේ real-world style components practise කරන්න පුළුවන්.

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
- AIOps controller

## මේ stage එකෙන් මතක තියාගන්න ඕන දේ

මේ project එක app deployment එකක් විතරක් නෙවෙයි.

මේක cloud platform එකක් build කරන project එකක්.

Main idea එක:

Infrastructure as Code
→ GitOps
→ DevSecOps
→ Observability
→ AIOps
→ Safe recovery
