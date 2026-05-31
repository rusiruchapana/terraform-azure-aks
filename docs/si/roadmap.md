# Roadmap

මෙම roadmap එකෙන් project එකේ current status සහ future work පැහැදිලි කරනවා.

මෙම project එකේ goal එක learners, practitioners, සහ professionals සඳහා reusable AKS DevOps Practice Platform එකක් build කිරීම.


## Lab order source of truth

Current hands-on lab order එක maintain කරන්නේ මෙතන:

    ../../labs/README.md

මෙම roadmap එක project phases සහ direction පැහැදිලි කරනවා. Full lab sequence එක අවශ්‍ය නැත්නම් මෙතන duplicate කරන්න එපා.

## Phase 1: Core AKS platform

Status: Complete

Completed:

- Terraform module structure
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
- AKS OIDC issuer
- AKS Workload Identity support
- dev environment
- qa සහ prod environment templates
- backend.tf.example pattern
- terraform.tfvars.example pattern
- local Terraform files ignored

Purpose:

මේ phase එකෙන් foundation Azure infrastructure සහ AKS platform එක create කරනවා.

## Phase 2: Gateway, secrets, and monitoring

Status: Learning platform එකට complete enough

Completed:

- Gateway API CRDs installed
- NGINX Gateway Fabric installed
- GatewayClass nginx verified
- Shared platform Gateway created
- Key Vault RBAC design tested
- Workload Identity test completed
- Demo workload identity resources cleaned up
- kube-prometheus-stack installed
- Grafana installed
- Prometheus installed
- Alertmanager installed
- OpenTelemetry Collector installed
- Monitoring values platform-addons යටතේ committed
- Safe port-forward access model documented

Future improvements:

- Gateway API manifests platform-addons වලට move කිරීම
- Optional TLS සහ hostname examples add කිරීම
- Secure Grafana exposure lab add කිරීම
- Application telemetry examples add කිරීම
- Platform add-ons GitOps-managed configuration එකකට move කිරීම

## Phase 3: CI/CD labs

Status: Structure සහ docs ready, implementation pending

Completed:

- CI/CD examples folder structure
- GitHub Actions folder
- GitLab CI/CD folder
- Azure DevOps folder
- Jenkins folder
- CI/CD docs
- Learning-first lab philosophy documented

Planned:

- GitHub Actions pipeline example
- GitLab CI/CD pipeline example
- Azure DevOps pipeline example
- Jenkins pipeline example
- Image build සහ ACR push
- AKS deploy
- External registry deploy
- Rollout verification
- Basic rollback example

Purpose:

මෙම phase එකෙන් usersලාට AKS මත real CI/CD workflows practice කරන්න උදව් කරනවා.

## Phase 4: GitOps and promotion

Status: Structure සහ docs ready, implementation pending

Completed:

- GitOps folder structure
- Argo CD examples folder
- Flux examples folder
- dev / qa / prod desired-state folders
- GitOps platform-addons folder
- platform-addons/gitops structure
- Argo CD optional values file
- Flux add-on notes
- GitOps docs
- GitOps README cleanup

Planned:

- Argo CD install lab
- Flux install lab
- Git වලින් app deploy කිරීම
- Argo CD app-of-apps example
- Flux Kustomization example
- dev to qa to prod promotion
- Pull request-based promotion
- Drift detection
- Git-based rollback
- GitOps-managed platform add-ons

Purpose:

මෙම phase එකෙන් Kubernetes deployments සහ environment promotion සඳහා Git source of truth ලෙස use කරන ආකාරය ඉගෙන ගන්න පුළුවන්.

## Phase 5: AI-assisted DevOps labs

Status: Future

Planned ideas:

- AI-assisted Terraform review
- AI-assisted Kubernetes manifest review
- AI-assisted CI/CD pipeline generation
- AI-assisted troubleshooting
- AI-assisted incident summary
- AI-assisted documentation generation
- DevOps engineers සඳහා prompt templates
- Infrastructure work සඳහා safe AI usage guidelines

Purpose:

මෙම phase එකෙන් AI මගින් DevOps engineersලාට support කරන්න පුළුවන් ආකාරය explore කරනවා. Engineering judgment replace කිරීමක් නෙවෙයි.

## Documentation status

Completed:

- Root README
- English සහ Sinhala documentation structure
- te reo Māori welcome page
- Community translation guide
- Quick Start
- Configuration Guide
- Prerequisites
- Architecture
- Terraform Backend
- AKS Platform
- ACR and Image Registries
- Gateway API
- Key Vault and Workload Identity
- Monitoring and Observability
- CI/CD Labs
- GitOps Labs
- Troubleshooting
- Known Issues
- Roadmap

Future documentation improvements:

- Diagrams add කිරීම
- Screenshots add කිරීම
- Step-by-step labs add කිරීම
- More real-world examples add කිරීම
- FAQ add කිරීම
- Contribution guide add කිරීම
- Security hardening guide add කිරීම

## Learning tracks

Project එක learning levels තුනක් support කරනවා.

Beginner:

- AKS basics තේරුම් ගන්න
- Public images deploy කරන්න
- Gateway API use කරන්න
- Grafana safely access කරන්න
- Terraform workflow ඉගෙන ගන්න
- Common issues troubleshoot කරන්න

Practitioner:

- Applications build සහ deploy කරන්න
- CI/CD pipelines use කරන්න
- Key Vault සහ Workload Identity use කරන්න
- Monitoring සහ alerts use කරන්න
- Registry workflows practice කරන්න
- Environment promotion practice කරන්න

Professional:

- Platform patterns design කරන්න
- GitOps use කරන්න
- Promotion workflows implement කරන්න
- Least privilege identity use කරන්න
- Observability add කරන්න
- Incident response practice කරන්න
- Security සහ reliability improve කරන්න

## Design principles

මෙම project එක follow කරන principles:

- Terraform core platform එක Azure infrastructure සඳහා focused තියාගන්න
- Platform add-ons optional තියාගන්න
- Examples beginner-friendly තියාගන්න
- Usersලාට තමන්ගේම applications use කරන්න ඉඩ දෙන්න
- ACR සහ external registries දෙකම support කරන්න
- Secure defaults prefer කරන්න
- Monitoring tools default public expose නොකරන්න
- English සහ Sinhala official maintained docs ලෙස තියාගන්න
- Community translations welcome කරන්න
- Platform එක reusable සහ extensible තියාගන්න

## Current project state

Project එකට දැන් strong foundation එකක් තියෙනවා.

Platform එක ready:

- AKS ඉගෙන ගන්න
- Terraform practice කරන්න
- Gateway API practice කරන්න
- Key Vault සහ Workload Identity practice කරන්න
- Monitoring සහ observability practice කරන්න
- CI/CD labs build කරන්න
- GitOps labs build කරන්න

Next major work එක actual lab implementations සහ pipeline examples add කිරීම.
