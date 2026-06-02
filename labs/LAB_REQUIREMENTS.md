# Lab Requirements

This project supports both minimal AKS installs and optional platform capabilities.

Not every lab is expected to run on a minimal cluster.

Some labs require optional capabilities such as Gateway API, Argo CD, Flux, Azure Container Registry, Key Vault, Workload Identity, monitoring, or OpenTelemetry.

## Before provisioning

Before you run Terraform, decide what you want to do with the cluster.

You can use this repository in two ways:

1. Build your own AKS platform and enable only the capabilities you want.
2. Follow the hands-on labs in this repository.

If you want to follow the labs, review the capability requirements first. Some labs need capabilities that may not exist in a minimal install.

## Capability types

### Provision-time capabilities

These capabilities are controlled by Terraform variables in environment tfvars files.

Examples:

    enable_acr
    enable_keyvault
    aks_oidc_issuer_enabled
    aks_workload_identity_enabled
    enable_workload_identity_keyvault_access
    enable_nat_gateway

These should be decided before provisioning or before updating the Terraform deployment.

### Post-cluster add-ons

These capabilities are installed after the AKS cluster exists.

Examples:

- Argo CD
- Flux
- Gateway API and shared Gateway
- Monitoring stack
- OpenTelemetry Collector

These are usually installed through platform add-on steps or lab setup steps.

## Install styles

### Minimal AKS install

A minimal install is useful for learning core Kubernetes and AKS basics.

It supports labs that only need:

- AKS cluster access
- kubectl
- basic Kubernetes resources

### Custom platform install

A custom install lets you enable only the capabilities you want to test.

For example:

- Enable ACR if you want private image registry labs
- Enable Key Vault and Workload Identity if you want secrets labs
- Install Argo CD if you want Argo CD GitOps labs
- Install Gateway API if you want Gateway and canary routing labs

### Full learning platform install

A full learning platform enables most capabilities needed for the full lab path and final capstone.

This usually includes:

- AKS
- ACR
- Key Vault
- OIDC issuer
- Workload Identity
- Argo CD
- Gateway API and shared Gateway
- Monitoring and telemetry

## Capability checks

### AKS access

    kubectl get nodes
    kubectl config current-context

### Azure Container Registry

If ACR was enabled through Terraform, check Terraform outputs or Azure:

    az acr list --query "[].{name:name, loginServer:loginServer}" -o table

### Key Vault

    az keyvault list --query "[].{name:name, resourceGroup:resourceGroup}" -o table

### AKS OIDC and Workload Identity

    az aks show \
      --resource-group <resource-group-name> \
      --name <aks-cluster-name> \
      --query "{oidcIssuerProfile:oidcIssuerProfile, workloadIdentityProfile:securityProfile.workloadIdentity}" \
      -o yaml

### Argo CD

    kubectl get ns argocd
    kubectl get pods -n argocd
    kubectl get crd applications.argoproj.io

### Flux

    kubectl get ns flux-system
    flux check

### Gateway API

    kubectl get gateway -A
    kubectl get gateway public-gateway -n platform-gateway

Expected for the shared platform Gateway:

    PROGRAMMED=True

### Monitoring

    kubectl get pods -A | grep -Ei 'prometheus|grafana|monitor|metrics'

### OpenTelemetry

    kubectl get pods -A | grep -Ei 'otel|opentelemetry'

## Lab capability matrix

| Lab group | Lab | Required capability |
|---|---|---|
| Beginner | Lab 01 - Public NGINX | AKS only |
| Beginner | Lab 02 - NGINX Gateway | Gateway API and shared Gateway |
| Beginner | Lab 03 - Registry image | AKS and registry access; ACR if using private ACR |
| Beginner | Lab 04 - Persistent Storage PVC | AKS storage class |
| Beginner | Lab 05 - Basic Troubleshooting | AKS only |
| Practitioner | Labs 01, 03, 05, 07 - CI/CD to AKS | AKS plus selected CI/CD platform |
| Practitioner | Labs 02, 04, 06, 08 - DevSecOps | AKS plus selected CI/CD platform and scan tools |
| Practitioner | Lab 09 - Key Vault Workload Identity | Key Vault, OIDC issuer, Workload Identity |
| Practitioner | Lab 10 - Monitoring Basics | Monitoring capability |
| Practitioner | Lab 11 - OpenTelemetry App | OpenTelemetry and monitoring capability |
| Professional | Lab 01 - Argo CD GitOps | Argo CD |
| Professional | Lab 02 - Flux GitOps | Flux |
| Professional | Lab 03 - dev to qa to prod promotion | Argo CD |
| Professional | Lab 04 - Blue/Green Deployment | Argo CD |
| Professional | Lab 05 - Canary Deployment | Argo CD, Gateway API, shared Gateway |
| Professional | Lab 06 - Incident Troubleshooting | To be confirmed by lab design |
| Professional | Lab 07 - Security Hardening | To be confirmed by lab design |
| Final Capstone | Production-style platform scenario | Expected to require GitOps, Gateway, registry, Key Vault, Workload Identity, monitoring, and security controls |

## How to use this matrix

Before provisioning:

1. Decide whether you want a minimal install, custom install, or full learning platform.
2. Review the labs you want to complete.
3. Enable Terraform-controlled capabilities in `terraform.tfvars`.
4. Plan post-cluster add-ons such as Argo CD, Flux, Gateway API, and monitoring.

Before starting a lab:

1. Check the required capability.
2. Run the capability check commands.
3. If the capability is missing, install or enable it first.
4. If you are using a minimal cluster, skip advanced capability labs and return later.

This is intentional.

The platform is modular, and advanced labs unlock as you enable more platform capabilities.
