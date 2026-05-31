# GitOps Applications

This folder contains desired state for applications deployed through GitOps.

## Purpose

Use this folder to store Kubernetes application configuration that Argo CD or Flux can sync to AKS.

## Environment folders

Planned environment folders:

    dev/
    qa/
    prod/

## What can each environment contain?

Each environment can contain:

- Deployment manifests
- Service manifests
- HTTPRoute manifests
- ConfigMaps
- Helm values
- Kustomize overlays
- Environment-specific image tags

## Example structure

    apps/
      dev/
        my-app/
      qa/
        my-app/
      prod/
        my-app/

## Learning approach

Start with dev first.

After you understand the flow, create qa and prod versions.

## Promotion idea

A simple promotion flow:

    dev -> qa -> prod

Promotion can mean:

- Copying a tested manifest
- Updating an image tag
- Updating a Helm values file
- Updating a Kustomize overlay
- Opening a pull request

## Important note

Do not commit plain-text secrets here.

Use a secrets integration such as:

- Azure Key Vault with Workload Identity
- External Secrets Operator
- Secrets Store CSI Driver
- Sealed Secrets
- SOPS
