# Architecture

This document explains the high-level architecture of the AKS DevOps Practice Platform.

The goal of this project is to provide a reusable AKS platform that can be used for DevOps, CI/CD, GitOps, monitoring, secrets, and platform engineering practice.

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
    Application labs and CI/CD/GitOps workflows

## Main components

The platform has four main layers:

1. Terraform infrastructure layer
2. AKS platform layer
3. Platform add-ons layer
4. Labs and application delivery layer

## 1. Terraform infrastructure layer

Terraform is used to create the Azure infrastructure.

Terraform-managed resources include:

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
- AKS OIDC issuer and Workload Identity settings

The Terraform code is organized into reusable modules.

    modules/
    environments/
      dev/
      qa/
      prod/

## 2. AKS platform layer

AKS is the Kubernetes platform used by this project.

The cluster uses separate node pools:

- System node pool
- User node pool

The system node pool is intended for Kubernetes and platform components.

The user node pool is intended for application workloads.

Applications should normally run on the user node pool.

## 3. Network architecture

The platform uses a Virtual Network and subnet for AKS.

A NAT Gateway is attached to the AKS subnet for outbound internet traffic.

This gives cluster nodes a stable outbound public IP.

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

Inbound application traffic is handled separately by Gateway API and NGINX Gateway Fabric.

## 4. Container registry architecture

The platform can optionally create Azure Container Registry.

If ACR is enabled:

    enable_acr = true

Terraform creates:

- Azure Container Registry
- AcrPull role assignment for AKS

If ACR is disabled:

    enable_acr = false

The cluster can still pull public images from:

- Docker Hub
- GitHub Container Registry
- Quay
- Other public registries

Private external registries require Kubernetes imagePullSecret.

## 5. Gateway architecture

This platform uses Gateway API with NGINX Gateway Fabric.

The platform creates or uses:

- Gateway API CRDs
- NGINX Gateway Fabric controller
- GatewayClass named nginx
- Shared Gateway named public-gateway
- Namespace named platform-gateway

Application teams should not create one LoadBalancer per app.

Instead, apps attach HTTPRoute resources to the shared Gateway.

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

## 6. Secrets and identity architecture

The platform uses Azure Key Vault and AKS Workload Identity.

The recommended pattern is:

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

Key Vault access uses Azure RBAC.

Important roles:

- Key Vault Secrets Officer: humans/operators can create or update secrets
- Key Vault Secrets User: applications can read secrets

The core platform enables Workload Identity, but app-specific identities and federated credentials should be created per application or lab.

## 7. Monitoring and observability architecture

The platform includes a monitoring and observability foundation.

Installed components:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter
- OpenTelemetry Collector

Cluster monitoring:

    Kubernetes nodes and pods
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

Current Collector endpoints inside the cluster:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317
    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318

Grafana and Prometheus are not exposed publicly by default.

Use port-forward for local access.

## 8. Environment architecture

The repository includes three environment templates:

- dev
- qa
- prod

Purpose:

- dev: low-cost learning and experimentation
- qa: staging and testing
- prod: production-style reference configuration

Each environment has:

- main.tf
- variables.tf
- outputs.tf
- providers.tf
- backend.tf.example
- terraform.tfvars.example

Real local files should not be committed:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- .terraform/

## 9. CI/CD and GitOps architecture

This platform supports both CI/CD and GitOps learning paths.

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

Supported CI/CD examples planned:

- GitHub Actions
- GitLab CI/CD
- Azure DevOps
- Jenkins

GitOps flow:

    Git repository
        |
        v
    Argo CD or Flux
        |
        v
    AKS cluster desired state

GitOps examples are organized under:

    gitops/
    examples/gitops/

## 10. What Terraform manages vs what add-ons manage

Terraform manages Azure infrastructure.

Terraform manages:

- Resource Group
- Network
- NAT Gateway
- AKS
- ACR
- Key Vault
- Managed identities
- Azure role assignments

Helm or Kubernetes manifests manage platform add-ons.

Add-ons include:

- Gateway API
- NGINX Gateway Fabric
- Prometheus and Grafana
- OpenTelemetry Collector

Future GitOps labs can move these add-ons into GitOps-managed configuration.

## 11. Design goals

This platform is designed to be:

- Beginner-friendly
- Useful for real DevOps practice
- Reusable across projects
- App-agnostic
- Registry-agnostic
- Suitable for CI/CD and GitOps labs
- Extendable for professional platform engineering patterns

## 12. Important design decisions

Important decisions in this platform:

- ACR is optional
- Docker Hub and other public registries are supported
- Gateway API is used instead of defaulting to legacy ingress-nginx
- Grafana and Prometheus are ClusterIP by default
- Key Vault uses RBAC mode
- Workload Identity is enabled for secure app identity
- Demo app identity resources are not kept permanently in the core platform
- dev, qa, and prod are separate environment templates
