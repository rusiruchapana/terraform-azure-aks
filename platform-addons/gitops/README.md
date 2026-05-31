# GitOps Platform Add-ons

This folder contains optional GitOps tool installation notes and configuration.

## Purpose

Argo CD and Flux are optional platform add-ons.

They are not installed by the core Terraform platform.

## Why optional?

The core Terraform platform creates:

- Azure infrastructure
- AKS cluster
- ACR
- Key Vault
- Managed identities
- Role assignments

GitOps tools run on top of AKS.

Not every learner or project needs GitOps from the beginning.

## Available options

- Argo CD
- Flux

## Folder structure

    platform-addons/gitops/
      argocd/
      flux/

## Recommended learning approach

1. Create the AKS platform with Terraform
2. Verify nodes, Gateway, Key Vault, and monitoring
3. Learn basic Kubernetes deployments
4. Choose Argo CD or Flux
5. Install the GitOps tool as an optional lab
6. Connect the tool to this repository
7. Deploy from gitops/apps/dev
8. Practice dev to qa to prod promotion

## Safe access

Keep GitOps dashboards internal by default.

Use port-forward for learning access.

Do not expose GitOps dashboards publicly without:

- HTTPS
- Authentication
- Access controls
- SSO or OAuth
- Network restrictions
