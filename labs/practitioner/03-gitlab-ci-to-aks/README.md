# Practitioner Lab 03 - GitLab CI/CD to AKS

This lab shows how to use GitLab CI/CD to build a container image, push it to a registry, and deploy it to AKS.

## What you will learn

- GitLab CI/CD pipeline structure
- GitLab pipeline stages
- Docker build in GitLab CI/CD
- Registry login and image push
- Azure login from GitLab CI/CD
- AKS deployment from GitLab CI/CD
- Rollout verification

## Lab repository

Use a GitLab project for this lab.

Example project:

    aks-gitlab-cicd-lab

## What this lab requires

- GitLab account
- Private GitLab project
- GitLab CI/CD enabled
- AKS cluster
- Container registry such as ACR
- GitLab CI/CD variables

## Prepare Azure CI/CD variables

This lab deploys to AKS and pushes an image to a registry.

Before running the pipeline, prepare the required Azure and registry values using the shared guide:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

## Required GitLab CI/CD variables

Add these variables in:

    GitLab project -> Settings -> CI/CD -> Variables

Variables:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

For this platform example:

    AZURE_RESOURCE_GROUP = rg-aks-dev-001
    AKS_CLUSTER_NAME = aks-dev-001
    REGISTRY_LOGIN_SERVER = acraksdev001andrew.azurecr.io

For ACR, you can use:

    REGISTRY_USERNAME = AZURE_CLIENT_ID
    REGISTRY_PASSWORD = AZURE_CLIENT_SECRET

The service principal should have:

- Permission to get AKS credentials
- AcrPush permission on ACR

## GitLab variable settings

For secret values, use:

    Masked: yes

For this learning lab, use:

    Protected: no

Use Protected variables only when your branch is protected.

## Folder structure

    app/
      sample web app and Dockerfile

    k8s/
      Kubernetes manifests

    .gitlab-ci.yml
      GitLab pipeline

## Copy files into your GitLab project

From this lab folder, copy these into the root of your GitLab project:

    app/
    k8s/
    gitlab-ci/.gitlab-ci.yml

In the GitLab project root, the file should be named:

    .gitlab-ci.yml

Expected GitLab project structure:

    app/
      Dockerfile
      index.html

    k8s/
      namespace.yaml
      deployment.yaml
      service.yaml

    .gitlab-ci.yml

## Pipeline stages

The GitLab pipeline uses these stages:

    validate
      |
      v
    build_push
      |
      v
    deploy
      |
      v
    verify

## How it works

The pipeline:

1. Validates required files
2. Builds a Docker image
3. Pushes the image to the registry
4. Logs in to Azure
5. Gets AKS credentials
6. Applies Kubernetes manifests
7. Verifies rollout

## Verify from local machine

After the pipeline succeeds:

    kubectl get pods -n practitioner-gitlab-ci
    kubectl get svc -n practitioner-gitlab-ci

Access locally:

    kubectl port-forward svc/gitlab-ci-demo -n practitioner-gitlab-ci 8085:80

Open:

    http://localhost:8085

## Cleanup

Delete the namespace:

    kubectl delete namespace practitioner-gitlab-ci

## Important note

This lab is intentionally simple.

Use it to understand the GitLab CI/CD flow first.

After that, improve it for your own application, registry, security model, and deployment strategy.
