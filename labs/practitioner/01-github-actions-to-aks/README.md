# Practitioner Lab 01 - GitHub Actions to AKS

This lab shows how to use GitHub Actions to build a container image, push it to a registry, and deploy it to AKS.

## What you will learn

- Create a simple containerized app
- Build a Docker image in GitHub Actions
- Push the image to a container registry
- Authenticate to Azure from GitHub Actions
- Connect to AKS
- Deploy Kubernetes manifests
- Verify rollout

## Learning-first example

This lab is a starter example.

You are encouraged to replace the sample app with your own application, Dockerfile, registry, and Kubernetes manifests.

## Authentication note

This lab starts with Azure service principal secret authentication because it is easier for beginners to understand.

For production-style workflows, prefer GitHub OIDC federation instead of long-lived client secrets.

## Supported registry paths

You can adapt this lab for:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- GitLab Container Registry
- Other private registries

## Folder structure

    app/
      sample static web app and Dockerfile

    k8s/
      Kubernetes manifests

    github-actions/
      GitHub Actions workflow template

## Copy workflow into GitHub Actions path

GitHub Actions workflows must live under:

    .github/workflows/

This lab stores the workflow template here:

    labs/practitioner/01-github-actions-to-aks/github-actions/build-deploy-aks.yaml

Copy it to:

    .github/workflows/build-deploy-aks.yaml

## Pipeline jobs

GitHub Actions uses jobs instead of the word stages.

This lab separates the workflow into four jobs:

    validate
      |
      v
    build-and-push
      |
      v
    deploy
      |
      v
    verify

Why separate jobs?

- Easier to understand the CI/CD flow
- Easier to see where a pipeline failed
- Closer to real-world pipeline design
- Better for learning than putting everything into one job

## Prepare Azure CI/CD variables

This lab deploys to AKS and pushes an image to a registry.

Before running the workflow, prepare the required Azure and registry values using the shared guide:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

## Required GitHub secrets

For this learning setup, configure these GitHub repository secrets:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

For ACR, REGISTRY_LOGIN_SERVER looks like:

    myacr.azurecr.io

For Docker Hub, it may look like:

    docker.io

For GHCR, it may look like:

    ghcr.io

## Image tag

The workflow builds the image and tags it with the GitHub commit SHA.

Example:

    myacr.azurecr.io/practitioner-github-actions:<commit-sha>

## Deployment method

The workflow:

1. Builds and pushes the image
2. Gets AKS credentials
3. Applies the namespace
4. Replaces IMAGE_PLACEHOLDER with the new image tag
5. Applies the Deployment
6. Applies the Service
7. Verifies rollout

## Local manifest test

Before running CI/CD, you can test the Kubernetes manifests locally by replacing IMAGE_PLACEHOLDER with a public image.

Example:

    sed "s|IMAGE_PLACEHOLDER|nginx:1.27-alpine|g" \
      terraform-azure-aks/labs/practitioner/01-github-actions-to-aks/k8s/deployment.yaml \
      | kubectl apply -f -

Full local test:

    kubectl apply -f terraform-azure-aks/labs/practitioner/01-github-actions-to-aks/k8s/namespace.yaml

    sed "s|IMAGE_PLACEHOLDER|nginx:1.27-alpine|g" \
      terraform-azure-aks/labs/practitioner/01-github-actions-to-aks/k8s/deployment.yaml \
      | kubectl apply -f -

    kubectl apply -f terraform-azure-aks/labs/practitioner/01-github-actions-to-aks/k8s/service.yaml

Verify:

    kubectl get pods -n practitioner-github-actions
    kubectl rollout status deployment/github-actions-demo -n practitioner-github-actions

Access locally:

    kubectl port-forward svc/github-actions-demo -n practitioner-github-actions 8084:80

Open:

    http://localhost:8084

## Cleanup

Delete the namespace:

    kubectl delete namespace practitioner-github-actions

## Important note

This lab is intentionally simple.

Use it to understand the CI/CD flow first.

After that, improve it for your own application and security requirements.
