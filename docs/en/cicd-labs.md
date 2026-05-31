# CI/CD Labs

This document explains the CI/CD learning path for the AKS DevOps Practice Platform.


## Current lab order

The current hands-on lab order is maintained in:

    ../../labs/README.md

This document explains CI/CD concepts and learning goals. The exact lab sequence should be updated in the labs index first.

## Lab order source of truth

The current hands-on lab order is maintained in:

    ../../labs/README.md

This document explains CI/CD concepts and learning goals. The exact lab sequence should be updated in the labs index first.

## Purpose

The CI/CD labs are designed to help users understand how applications are built, pushed to a container registry, and deployed to AKS.

These labs are learning-first examples.

They are intentionally simple so beginners can understand the full workflow.

## Learning-first examples

The labs in this repository are starter examples.

They are designed to help beginners understand how DevOps workflows work on AKS.

You are not limited to the provided examples.

After completing a lab, try replacing the sample app with:

- Your own application
- Your own Dockerfile
- Your own container registry
- Your own Kubernetes manifests
- Your own deployment strategy

This platform is:

- App-agnostic
- Registry-agnostic
- CI/CD tool-agnostic

## Supported CI/CD tools

This project plans examples for:

- GitHub Actions
- GitLab CI/CD
- Azure DevOps
- Jenkins

Example folders:

    examples/cicd/github-actions
    examples/cicd/gitlab-ci
    examples/cicd/azure-devops
    examples/cicd/jenkins

## Common CI/CD flow

Most CI/CD pipelines follow the same basic flow:

    Source code
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
        |
        v
    Verify rollout

## Common pipeline stages

A typical pipeline includes:

1. Checkout source code
2. Set up runtime or build tools
3. Build application
4. Run tests
5. Build Docker image
6. Login to container registry
7. Push image
8. Authenticate to Azure or Kubernetes
9. Deploy manifests or run Helm upgrade
10. Verify rollout

## Registry options

You can use different registries:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- GitLab Container Registry
- Quay
- Any private registry with imagePullSecret

## ACR-based pipeline

If ACR is enabled:

    enable_acr = true

The pipeline can:

1. Build image
2. Push image to ACR
3. Deploy image to AKS

AKS can pull from ACR if AcrPull permission is configured.

## External registry pipeline

If you use Docker Hub, GHCR, GitLab Container Registry, or another registry:

- Public images may not need a secret
- Private images need imagePullSecret
- The pipeline should push the image to your chosen registry
- Kubernetes manifests should reference that image

## Deployment methods

CI/CD pipelines can deploy to AKS using different methods.

Common options:

- kubectl apply
- kubectl set image
- Helm upgrade
- Kustomize
- GitOps handoff

For beginner labs, kubectl apply is easiest.

For practitioner and professional labs, Helm, Kustomize, or GitOps handoff may be better.

## Direct CI/CD deployment

Direct deployment means the pipeline updates the cluster.

Example flow:

    CI/CD pipeline
        |
        v
    kubectl apply
        |
        v
    AKS

This is simple and good for learning.

## GitOps handoff

GitOps handoff means the pipeline updates Git, not the cluster directly.

Example flow:

    CI/CD pipeline
        |
        v
    Build and push image
        |
        v
    Update manifest in Git
        |
        v
    Argo CD or Flux syncs to AKS

This pattern is useful for professional workflows.

## Environment promotion

The repository includes environment templates:

- dev
- qa
- prod

A common promotion flow:

    dev
     |
     v
    qa
     |
     v
    prod

For learning, start with dev only.

Later, practice promoting image tags or manifests from dev to qa and prod.

## Beginner lab ideas

Beginner labs should focus on understanding the basics:

1. Deploy a public Docker Hub image
2. Build a simple Docker image
3. Push image to ACR
4. Deploy image to AKS
5. Expose app through Gateway API
6. Verify rollout
7. Troubleshoot ImagePullBackOff

## Practitioner lab ideas

Practitioner labs should focus on real CI/CD workflows:

1. GitHub Actions pipeline to AKS
2. GitLab CI/CD pipeline to AKS
3. Azure DevOps pipeline to AKS
4. Jenkins pipeline to AKS
5. Build and push to ACR
6. Build and push to GHCR or Docker Hub
7. Use Kubernetes manifests with variable image tags
8. Add rollout verification

## Professional lab ideas

Professional labs can include:

1. Multi-environment promotion
2. Pull request-based deployment
3. Approval gates
4. Image scanning
5. Policy checks
6. Helm-based deployments
7. GitOps handoff
8. Rollback workflows
9. Blue/green deployment
10. Canary deployment

## Secrets in CI/CD

Do not hardcode credentials in pipeline files.

Use the secret store provided by your CI/CD tool.

Examples:

- GitHub Actions Secrets
- GitLab CI/CD Variables
- Azure DevOps Variable Groups
- Jenkins Credentials

Common secrets:

- Azure credentials
- Registry username/password
- Kubernetes config
- Service principal values

For Azure-native workflows, prefer federated identity or workload identity where possible.

## Recommended first CI/CD lab

Start with the simplest path:

1. Use a sample app
2. Build Docker image
3. Push image to ACR
4. Deploy to AKS using kubectl
5. Verify with kubectl rollout status
6. Access through Gateway API

After that, replace the sample app with your own application.

## Important note

These labs are not strict production templates.

They are learning labs.

Use them to understand the flow:

    source code -> container image -> registry -> AKS deployment

After you understand the flow, customize the pipeline for your own application and organization.
