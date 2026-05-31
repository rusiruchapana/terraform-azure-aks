# GitOps

This folder contains GitOps desired-state examples and environment promotion structures.

GitOps means Git is used as the source of truth for Kubernetes workloads and platform configuration.

## Important distinction

This folder is for GitOps desired state examples.

For installing GitOps tools such as Argo CD or Flux, see:

    platform-addons/gitops/

## Supported GitOps tools

Planned tools:

- Argo CD
- Flux

## Folder structure

    gitops/
      argocd/
      flux/
      apps/
        dev/
        qa/
        prod/
      platform-addons/

## What belongs here?

Use this folder for Kubernetes desired state such as:

- Application manifests
- Services
- HTTPRoutes
- Helm values
- Kustomize overlays
- Environment-specific app configuration
- GitOps-managed platform add-on manifests

## What does not belong here?

Do not put Terraform infrastructure code here.

Do not put local secrets here.

Do not put plain-text production secrets in Git.

## Learning flow

Recommended learning flow:

1. Create the AKS platform with Terraform
2. Verify Gateway, secrets, and monitoring
3. Install Argo CD or Flux as an optional add-on
4. Put an application manifest under gitops/apps/dev
5. Connect the GitOps tool to this repository
6. Let GitOps sync the app to AKS
7. Promote the app from dev to qa to prod

## Environment promotion

A common promotion model:

    dev
     |
     v
    qa
     |
     v
    prod

Promotion can be done by:

- Updating image tags
- Updating Helm values
- Updating Kustomize overlays
- Opening pull requests
- Using approval gates

## Customization

The provided structure is a learning starter.

You can replace the sample apps and manifests with your own application, your own release process, and your own GitOps structure.
