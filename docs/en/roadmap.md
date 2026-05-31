# Roadmap

This roadmap explains the current project status and planned future work.

The goal of this project is to build a reusable AKS DevOps Practice Platform for learners, practitioners, and professionals.


## Lab order source of truth

The current hands-on lab order is maintained in:

    ../../labs/README.md

This roadmap describes project phases and direction. Do not duplicate the full lab sequence here unless necessary.

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
- qa and prod environment templates
- backend.tf.example pattern
- terraform.tfvars.example pattern
- local Terraform files ignored

Purpose:

This phase creates the foundation Azure infrastructure and AKS platform.

## Phase 2: Gateway, secrets, and monitoring

Status: Complete enough for learning platform

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
- Monitoring values committed under platform-addons
- Safe port-forward access model documented

Future improvements:

- Move Gateway API manifests into platform-addons
- Add optional TLS and hostname examples
- Add secure Grafana exposure lab
- Add application telemetry examples
- Move platform add-ons into GitOps-managed configuration

## Phase 3: CI/CD labs

Status: Structure and docs ready, implementation pending

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
- Build and push image to ACR
- Deploy to AKS
- Deploy using external registry
- Rollout verification
- Basic rollback example

Purpose:

This phase helps users practice real CI/CD workflows on AKS.

## Phase 4: GitOps and promotion

Status: Structure and docs ready, implementation pending

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
- Deploy app from Git
- Argo CD app-of-apps example
- Flux Kustomization example
- dev to qa to prod promotion
- Pull request-based promotion
- Drift detection
- Git-based rollback
- GitOps-managed platform add-ons

Purpose:

This phase teaches Git as the source of truth for Kubernetes deployments and environment promotion.

## Phase 5: AI-assisted DevOps labs

Status: Future

Planned ideas:

- AI-assisted Terraform review
- AI-assisted Kubernetes manifest review
- AI-assisted CI/CD pipeline generation
- AI-assisted troubleshooting
- AI-assisted incident summary
- AI-assisted documentation generation
- Prompt templates for DevOps engineers
- Safe AI usage guidelines for infrastructure work

Purpose:

This phase explores how AI can support DevOps engineers without replacing engineering judgment.

## Documentation status

Completed:

- Root README
- English and Sinhala documentation structure
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

- Add diagrams
- Add screenshots
- Add step-by-step labs
- Add more real-world examples
- Add FAQ
- Add contribution guide
- Add security hardening guide

## Learning tracks

The project supports three learning levels.

Beginner:

- Understand AKS basics
- Deploy public images
- Use Gateway API
- Access Grafana safely
- Learn Terraform workflow
- Troubleshoot common issues

Practitioner:

- Build and deploy applications
- Use CI/CD pipelines
- Use Key Vault and Workload Identity
- Use monitoring and alerts
- Practice registry workflows
- Practice environment promotion

Professional:

- Design platform patterns
- Use GitOps
- Implement promotion workflows
- Use least privilege identity
- Add observability
- Practice incident response
- Improve security and reliability

## Design principles

This project follows these principles:

- Keep the Terraform core platform focused on Azure infrastructure
- Keep platform add-ons optional
- Keep examples beginner-friendly
- Allow users to bring their own applications
- Support both ACR and external registries
- Prefer secure defaults
- Avoid exposing monitoring tools publicly by default
- Use English and Sinhala as official maintained docs
- Welcome community translations
- Keep the platform reusable and extensible

## Current project state

The project currently has a strong foundation.

The platform is ready for:

- Learning AKS
- Practicing Terraform
- Practicing Gateway API
- Practicing Key Vault and Workload Identity
- Practicing monitoring and observability
- Building CI/CD labs
- Building GitOps labs

The next major work is to add actual lab implementations and pipeline examples.
