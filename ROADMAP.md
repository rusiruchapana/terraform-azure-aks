# Terraform Azure AKS Learning Roadmap

This roadmap defines the current learning flow, planned continuation, final projects, and the AI-assisted learning track for this project.

The goal is to build a practical, step-by-step AKS learning path from beginner Kubernetes concepts to production-style platform delivery, DevSecOps, observability, final projects, and AI-assisted operations.

## Guiding principles

- Keep labs hands-on and beginner friendly.
- Keep English and Sinhala guides aligned.
- Use `README.md` as the English source of truth.
- Keep `README.si.md` in the same heading order, same command flow, and same file path flow.
- Do not include personal laptop paths in lab guides.
- Do not assume a shared `~/projects` directory.
- Use lab-specific workspaces where temporary app repositories are needed.
- Separate learning-mode labs from production-mode recommendations.
- Explain why each tool or pattern is used.

## Current practitioner flow

Practitioner labs focus on CI/CD tools, DevSecOps basics, secrets, monitoring, and application telemetry.

Current practitioner sequence:

1. GitHub Actions to AKS
2. GitHub Actions DevSecOps Checks
3. GitLab CI/CD to AKS
4. GitLab CI/CD DevSecOps Checks
5. Azure DevOps to AKS
6. Azure DevOps DevSecOps Checks
7. Jenkins to AKS
8. Jenkins DevSecOps Checks
9. Key Vault and Workload Identity
10. Monitoring Basics
11. OpenTelemetry App

## Current professional flow

Professional labs focus on production delivery patterns, GitOps, environment promotion, deployment strategies, troubleshooting, and security hardening.

Current professional sequence:

1. Argo CD GitOps
2. Flux GitOps
3. Dev to QA to Prod promotion
4. Blue/green deployment
5. Canary deployment
6. Incident troubleshooting
7. Security hardening

## Planned professional continuation

After the current professional flow is complete, this project continues into stack-specific production deployment patterns and deeper DevSecOps quality gates.

Planned continuation labs:

- Node.js production deployment
- Python FastAPI production deployment
- .NET production deployment
- SonarQube or SonarCloud quality gates
- Dependency scanning
- Secrets scanning
- Infrastructure-as-Code security scanning
- Kubernetes policy validation
- SBOM generation
- Image signing
- Full quality gate pipeline

## Stack-specific professional labs

The goal of stack-specific labs is to show that the AKS delivery pattern is consistent, while each application stack has different build, test, and quality steps.

### Node.js

Topics:

- npm install or npm ci
- Unit tests
- Linting
- Dependency scanning
- Docker build
- Image scanning
- AKS deployment

### Python FastAPI

Topics:

- pip or requirements.txt
- pytest
- Linting
- Dependency scanning
- Docker build
- Image scanning
- AKS deployment

### .NET

Topics:

- dotnet restore
- dotnet build
- dotnet test
- Package vulnerability checks
- Docker multi-stage build
- Image scanning
- AKS deployment

## Final projects

Final projects will be created after the current practitioner, professional, and stack-specific continuation paths are complete.

The final projects should be full end-to-end secure AKS delivery projects with best practices, security hardening, CI/CD, DevSecOps, observability, and operational documentation.

Planned final projects:

1. Final Project A - Secure end-to-end Node.js AKS delivery
2. Final Project B - Secure end-to-end Python AKS delivery
3. Final Project C - Secure end-to-end .NET AKS delivery
4. Optional Final Project D - Multi-language microservices capstone

## Final project architecture principles

Final projects should teach production-style separation of concerns:

- Terraform builds and maintains platform infrastructure.
- Application CI/CD builds, scans, and deploys application releases.
- GitOps may be used to manage desired Kubernetes state.
- Progressive delivery can be used for safer releases.

Recommended separation:

```text
platform-infra-repo
  Terraform
  remote state
  plan/apply pipeline
  approvals

application-repo
  application code
  Dockerfiles
  tests
  scans
  Helm or Kubernetes manifests
  app CI/CD pipeline

gitops-config-repo
  optional desired state repository
  environment overlays
  Argo CD or Flux sync
Deployment strategies for final projects

Final projects should include or explain:

Rolling deployment
Blue/green deployment
Canary deployment
Rollback strategy
Environment promotion
Manual approvals for protected environments
AI track

The AI track is tracked separately and will be added after the core platform, practitioner, professional, and final project paths are established.

The purpose of the AI track is to show how AI can assist DevOps and platform engineering workflows without replacing engineering judgment.

Planned AI labs:

AI-assisted DevOps documentation
AI-assisted Terraform review
AI-assisted Kubernetes troubleshooting
AI-assisted CI/CD failure analysis
AI-assisted security finding explanation
RAG chatbot for platform documentation
AI incident assistant using logs and alerts
AI guardrails, privacy, and safe usage
DevSecOps maturity path

The project will evolve DevSecOps coverage in stages.

Practitioner level
Basic Trivy config scanning
Basic Trivy image scanning
Scan-only pipelines
Learning mode with non-failing scans
Professional level
Code quality checks
Dependency scanning
Secrets scanning
IaC scanning
Kubernetes policy checks
SBOM generation
Image signing
Strict quality gates
Documented exception process
Final project level
Full integrated quality gate pipeline
Environment-specific controls
Security hardening
Observability
Operational runbooks
Production-style approval flow
Documentation quality rules

All lab guides must follow these rules:

README.md is the English source of truth.
README.si.md follows the same headings.
README.si.md follows the same command blocks.
README.si.md follows the same cleanup flow.
No personal laptop paths are allowed.
No shared ~/projects assumption is allowed.
Use lab-specific workspace variables when temporary repositories are needed.
Deployment labs must explain required variables or link to the shared variables guide.
Scan-only DevSecOps labs must clearly state that deployment credentials are not required.
