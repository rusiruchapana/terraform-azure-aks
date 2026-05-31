# GitOps Labs

This document explains the GitOps learning path for the AKS DevOps Practice Platform.

## Purpose

GitOps helps users understand how Kubernetes deployments can be managed from Git.

In GitOps, Git becomes the source of truth for the desired state of the cluster.

## What is GitOps?

GitOps is a deployment model where Kubernetes manifests, Helm values, or Kustomize overlays are stored in Git.

A GitOps controller watches the Git repository and syncs the cluster to match Git.

High-level flow:

    Git repository
        |
        v
    Argo CD or Flux
        |
        v
    AKS cluster

## Supported GitOps tools

This project plans examples for:

- Argo CD
- Flux

Folders:

    gitops/argocd
    gitops/flux
    examples/gitops/argocd
    examples/gitops/flux

## CI/CD vs GitOps

CI/CD direct deployment:

    Pipeline
        |
        v
    kubectl apply
        |
        v
    AKS

GitOps deployment:

    Pipeline or developer
        |
        v
    Update Git
        |
        v
    Argo CD or Flux
        |
        v
    AKS

In CI/CD direct deployment, the pipeline changes the cluster.

In GitOps, the pipeline changes Git, and the GitOps controller changes the cluster.

## Why GitOps?

GitOps is useful because:

- Git stores the desired state
- Changes are reviewable through pull requests
- Rollback can be done using Git history
- Drift can be detected
- Cluster changes become auditable
- dev, qa, and prod promotion becomes clearer

## Learning-first examples

The GitOps examples in this repository are starter examples.

They are designed to help beginners understand the GitOps workflow.

You are not limited to the provided sample app.

After completing a lab, try replacing the sample app with:

- Your own application
- Your own image
- Your own Kubernetes manifests
- Your own Helm chart
- Your own Kustomize overlays
- Your own promotion strategy

This platform is app-agnostic and GitOps-tool friendly.

## Repository GitOps structure

The repository includes:

    gitops/
      argocd/
      flux/
      apps/
        dev/
        qa/
        prod/
      platform-addons/

Purpose:

- argocd: Argo CD bootstrap and app-of-apps examples
- flux: Flux bootstrap and Kustomization examples
- apps: desired state for applications
- platform-addons: desired state for platform add-ons

## Application desired state

Application manifests can be organized by environment.

Example:

    gitops/apps/dev
    gitops/apps/qa
    gitops/apps/prod

Each environment can contain:

- Deployment manifests
- Service manifests
- HTTPRoute manifests
- Helm values
- Kustomize overlays

## Platform add-ons desired state

Platform add-ons can also be managed through GitOps later.

Examples:

- Gateway API resources
- Monitoring resources
- Secrets integrations
- External Secrets Operator
- CSI Driver configuration

Current platform add-ons were installed manually for learning.

Future labs can move them into GitOps-managed configuration.

## dev to qa to prod promotion

A common GitOps promotion flow:

    dev
     |
     v
    qa
     |
     v
    prod

Promotion can be done by:

- Updating image tags
- Copying manifests between environment folders
- Using Kustomize overlays
- Updating Helm values
- Opening pull requests
- Applying approval gates

## Image promotion

A common pattern is to keep the same image digest or tag and promote it across environments.

Example:

    dev  -> my-app:v1.0.0
    qa   -> my-app:v1.0.0
    prod -> my-app:v1.0.0

For production-style workflows, immutable image tags or image digests are recommended.

## Argo CD learning path

Beginner Argo CD labs can include:

1. Install Argo CD
2. Access Argo CD UI locally
3. Connect the Git repository
4. Deploy one app from Git
5. Update the manifest in Git
6. Watch Argo CD sync the change
7. Roll back using Git

Practitioner Argo CD labs can include:

1. App-of-apps pattern
2. Multiple environments
3. Helm-based app deployment
4. Kustomize overlays
5. Sync policies
6. Health checks
7. Drift detection

Professional Argo CD labs can include:

1. PR-based promotion
2. Approval gates
3. Multi-cluster patterns
4. RBAC
5. SSO
6. Notifications
7. Progressive delivery integration

## Flux learning path

Beginner Flux labs can include:

1. Install Flux
2. Bootstrap Flux with the Git repository
3. Deploy one app from Git
4. Update the manifest in Git
5. Watch Flux reconcile the change
6. Roll back using Git

Practitioner Flux labs can include:

1. Kustomization resources
2. HelmRelease resources
3. Multiple environments
4. Image automation
5. Source controllers
6. Reconciliation troubleshooting

Professional Flux labs can include:

1. Promotion workflows
2. Image update automation
3. Policy integration
4. Multi-cluster GitOps
5. Secret management integration
6. Progressive delivery integration

## Direct deployment vs GitOps handoff

CI/CD can still be used with GitOps.

A common professional pattern:

    CI/CD pipeline
        |
        v
    Build and push image
        |
        v
    Update image tag in Git
        |
        v
    Argo CD or Flux syncs AKS

The pipeline builds artifacts.

GitOps deploys artifacts.

## Secrets and GitOps

Do not commit plain-text secrets to Git.

For secrets, use one of these patterns:

- External Secrets Operator
- Secrets Store CSI Driver
- Sealed Secrets
- SOPS
- Azure Key Vault integration

Secrets labs will be handled separately.

## Beginner GitOps lab idea

A simple first lab:

1. Deploy a sample app manifest from Git
2. Create a Service
3. Create an HTTPRoute
4. Sync with Argo CD or Flux
5. Change image tag in Git
6. Verify rollout
7. Roll back using Git

## Practitioner GitOps lab idea

A practitioner lab can include:

1. dev and qa folders
2. Different image tags per environment
3. Pull request-based promotion
4. Argo CD or Flux sync verification
5. Drift detection and correction

## Professional GitOps lab idea

A professional lab can include:

1. dev, qa, and prod overlays
2. Approval process for prod
3. Immutable image promotion
4. Policy checks
5. Progressive delivery
6. Observability checks
7. Rollback strategy

## Important note

The GitOps labs are learning examples.

They are not strict production templates.

Use them to understand the flow:

    Git desired state -> GitOps controller -> AKS

After you understand the flow, customize the structure for your own application, team, and release process.
