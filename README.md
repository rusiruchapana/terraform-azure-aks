# AKS DevOps Practice Platform

A reusable Azure AKS platform and learning project for practicing real-world DevOps, DevSecOps, GitOps, observability, platform engineering, and AIOps workflows.

This project is designed for:

- Beginners learning AKS, Kubernetes, Terraform, and cloud DevOps
- Practitioners building CI/CD, DevSecOps, secrets, monitoring, and telemetry workflows
- Professionals practicing GitOps, release promotion, incident response, security hardening, platform CI, and production-style delivery
- Learners building a portfolio-ready AKS platform engineering capstone project


## Platform Architecture

<p align="center">
  <img src="images/terraform_aks_platform_architecture_diagram.png" alt="terraform-azure-aks Platform Architecture" width="100%">
</p>

## Project areas

This repository contains two main learning areas:

- Hands-on labs
- Enterprise AKS capstone project

## Documentation

Official documentation:

- English: [docs/en](docs/en/README.md)
- සිංහල: [docs/si](docs/si/README.md)

The capstone stage guides are currently written in Sinhala-first format for practical step-by-step learning.

## Hands-on labs

The hands-on labs are organized by learning level:

- Beginner labs: AKS and Kubernetes basics
- Practitioner labs: CI/CD, DevSecOps, secrets, monitoring, and telemetry
- Professional labs: GitOps, release strategies, incident troubleshooting, and security hardening
- AIOps labs: AI-assisted incident analysis and remediation concepts

Start here:

- [Labs index](labs/README.md)
- [AI Ops labs](labs/aiops/README.md)
- [Lab capability requirements](labs/LAB_REQUIREMENTS.md)

This platform is modular. You can provision a minimal AKS cluster for your own testing, or enable additional capabilities for the labs you want to complete.

## Enterprise AKS capstone

The capstone project is the main end-to-end platform engineering project in this repository.

Start here:

- [Capstone index](capstone/README.md)

The capstone covers:

- Terraform-based AKS platform provisioning
- Remote Terraform state backend
- Azure Container Registry integration
- Argo CD GitOps foundation
- Gateway API and NGINX Gateway Fabric
- Prometheus, Grafana, and Alertmanager monitoring
- OpenTelemetry observability
- Dev / QA / Prod GitOps environments
- GitHub Actions CI/CD
- DevSecOps quality gates
- GitOps manifest validation
- End-to-end Dev release verification
- Dev to QA to Prod promotion
- Terraform platform CI with TFLint and Checkov
- AIOps PR remediation workflow
- AIOps alert detection and dashboard visibility
- Load testing and observability verification

## Capstone repository model

The capstone uses three repositories.

### Platform repository

Repository:

    terraform-azure-aks

Purpose:

    Terraform platform infrastructure
    AKS platform setup
    platform CI
    capstone guides
    local UI helper scripts

### Application repository

Repository:

    aks-capstone-store-app

Purpose:

    application source code
    GitHub Actions application CI
    Dev image build and scan
    ACR push
    Dev GitOps update
    Dev release verification

### GitOps repository

Repository:

    aks-capstone-gitops

Purpose:

    Kubernetes manifests
    Kustomize overlays
    Argo CD applications
    Dev / QA / Prod desired state
    GitOps validation pipeline
    promotion workflow
    AIOps monitoring and dashboard manifests

## Current platform capabilities

- Terraform-based AKS platform
- Remote Terraform backend support
- VNet and AKS subnet
- AKS system and user node pools
- Azure Container Registry
- Gateway API with NGINX Gateway Fabric
- Shared platform Gateway
- Prometheus, Grafana, and Alertmanager
- kube-state-metrics and node-exporter
- OpenTelemetry Collector
- Argo CD GitOps
- Dev / QA / Prod application environments
- GitHub Actions CI/CD
- Gitleaks secret scanning
- Trivy source and image scanning
- Kustomize overlays
- kubeconform manifest validation
- TFLint and Checkov platform CI
- AIOps PR remediation
- AIOps alert visibility
- AIOps Incident Dashboard UI
- Docker-based k6 load testing

## UI access model

The project keeps operational UIs separated.

### Monitoring UI

Used for:

    metrics
    alerts
    pod and node health
    resource usage
    observability dashboards

Examples:

    Grafana
    Prometheus
    Alertmanager

### Argo CD UI

Used for:

    GitOps sync status
    health status
    Git revision
    manifest diff
    sync history

### AIOps UI

Used for:

    active incident visibility
    alert evidence
    root cause context
    remediation guidance
    recovery status

Local UI helper scripts:

    scripts/local-ui/start-local-uis.sh
    scripts/local-ui/status-local-uis.sh
    scripts/local-ui/stop-local-uis.sh

Local UI URLs:

    AIOps Dashboard: http://localhost:8088
    Grafana:         http://localhost:3000
    Prometheus:      http://localhost:9090
    Alertmanager:    http://localhost:9093

## Main workflows

### Platform repository workflow

Workflow:

    Terraform Platform CI

Purpose:

    Terraform formatting
    Terraform init and validate
    TFLint validation
    Checkov IaC scan
    platform CI summary

### Application repository workflows

Main workflows:

    Build store-front and deploy Dev via GitOps
    Verify Dev release end-to-end

Legacy workflow:

    Legacy - Build store-front image to ACR

### GitOps repository workflows

Main workflows:

    Validate GitOps manifests
    Promote store-front image

Purpose:

    YAML validation
    Kustomize render
    kubeconform validation
    Dev / QA / Prod manifest safety
    image promotion

## Monitoring and load testing

The capstone includes a monitoring and observability verification flow.

It verifies:

    Grafana dashboards are accessible
    Prometheus metrics are queryable
    Alertmanager shows alerts
    AIOps Dashboard reflects Prometheus alert state
    Docker-based k6 can generate controlled load
    store-front remains healthy during load
    CPU, memory, and network metrics are visible

The load test uses Docker-based k6, so local k6 installation is not required.

## Cost and safety notes

This project can create Azure resources that cost money.

Important safety points:

    Keep budget alerts enabled.
    Avoid unnecessary public LoadBalancer services.
    Prefer ClusterIP for internal services.
    Stop local UI port-forwards when not needed.
    Clean up resources when the lab or project is finished.
    Keep Terraform state safe.
    Do not commit secrets, tokens, personal paths, private emails, or live environment-specific IP addresses.

## Roadmap

The full learning and project roadmap is tracked here:

- [ROADMAP.md](ROADMAP.md)

## License and usage

This repository is publicly visible for educational, portfolio, and reference purposes.

Copyright (c) 2026 Andrew Ferdinandus. All rights reserved.

You may view this repository and fork it on GitHub for personal learning and reference.

You may not copy, redistribute, re-upload, publish, sublicense, sell, or use this project or substantial parts of it in another repository, course, product, or commercial work without written permission from the author.

Forks should preserve attribution to the original repository and author.

For usage restrictions, see [NOTICE.md](NOTICE.md).
