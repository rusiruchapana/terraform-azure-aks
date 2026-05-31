# Labs

This folder contains hands-on labs for the AKS DevOps Practice Platform.

The labs are organized by learning level:

- Beginner
- Practitioner
- Professional

This file is the source of truth for the current lab order.

If the lab flow changes in the future, update this file first.

For the wider project roadmap, planned professional continuation, final projects, and AI track, see:

    ../ROADMAP.md

## Learning path

Recommended order:

    Beginner Labs
          |
          v
    Practitioner Labs
          |
          v
    Professional Labs

## Beginner Labs

Beginner labs focus on Kubernetes and AKS basics.

Current beginner flow:

1. Deploy Public NGINX Image
2. Expose NGINX with Gateway API
3. Deploy Image from a Container Registry
4. Persistent Storage with PVC
5. Basic Kubernetes Troubleshooting

Folders:

    beginner/01-public-nginx
    beginner/02-nginx-gateway
    beginner/03-registry-image
    beginner/04-persistent-storage-pvc
    beginner/05-basic-troubleshooting

## Practitioner Labs

Practitioner labs focus on real DevOps workflows.

Current practitioner flow:

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

Planned folders:

    practitioner/01-github-actions-to-aks
    practitioner/02-github-actions-devsecops
    practitioner/03-gitlab-ci-to-aks
    practitioner/04-gitlab-ci-devsecops
    practitioner/05-azure-devops-to-aks
    practitioner/06-azure-devops-devsecops
    practitioner/07-jenkins-to-aks
    practitioner/08-jenkins-devsecops
    practitioner/09-key-vault-workload-identity
    practitioner/10-monitoring-basics
    practitioner/11-opentelemetry-app

## Professional Labs

Professional labs focus on production-style platform engineering patterns.

Current professional flow:

1. Argo CD GitOps
2. Flux GitOps
3. dev to qa to prod promotion
4. Blue/green deployment
5. Canary deployment
6. Incident troubleshooting
7. Security hardening

Planned folders:

    professional/01-argocd-gitops
    professional/02-flux-gitops
    professional/03-dev-qa-prod-promotion
    professional/04-blue-green-deployment
    professional/05-canary-deployment
    professional/06-incident-troubleshooting
    professional/07-security-hardening

## Planned continuation

The current Beginner, Practitioner, and Professional flows are the active learning paths.

After the current Professional flow is complete, this project continues with stack-specific professional labs, deeper DevSecOps quality gates, and secure end-to-end final projects.

Planned continuation includes:

- Stack-specific professional labs for Node.js, Python FastAPI, and .NET
- SonarQube or SonarCloud quality gates
- Dependency scanning
- Secrets scanning
- SBOM generation
- Image signing
- Secure end-to-end final projects by application stack
- Optional multi-language microservices capstone

The AI-assisted DevOps and troubleshooting track is tracked separately in the project roadmap.

For the full project direction, see:

    ../ROADMAP.md

## Learning-first approach

These labs are learning examples.

The early labs are not strict production templates. They are designed to teach concepts step by step.

As the learning path progresses, the labs move toward production-style patterns, DevSecOps quality gates, secure delivery, observability, and final end-to-end projects.

After completing a lab, replace the sample app, registry, image, manifests, and workflow with your own application and release process.

This platform is app-agnostic and registry-agnostic.
