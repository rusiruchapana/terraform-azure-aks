# GitOps Examples

This folder contains GitOps examples for deploying applications and platform resources to AKS.

## Supported GitOps tools

Planned examples:

- Argo CD
- Flux

## GitOps flow

    Git repository
        |
        v
    Argo CD or Flux
        |
        v
    AKS cluster

## Learning purpose

Use these examples to practice:

- Git as the source of truth
- Application desired state
- Environment folders
- dev to qa to prod promotion
- Drift detection
- Rollback using Git
- GitOps controller sync behavior

## Important note

These examples are learning starters.

You can replace the sample app and manifests with your own application, Helm chart, Kustomize overlays, and release process.
