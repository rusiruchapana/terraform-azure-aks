# ACR and Image Registries

This document explains how container image registries are used in this AKS DevOps Practice Platform.

## What is a container registry?

A container registry stores container images.

Kubernetes pulls images from a registry and runs them as pods.

Common registries:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- Quay
- GitLab Container Registry
- Other private registries

## Registry design in this platform

This platform is registry-agnostic.

That means users can choose:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- GitLab Container Registry
- Quay
- Another public or private registry

Azure Container Registry is optional.

## Azure Container Registry

Azure Container Registry is a private container registry service in Azure.

It is useful when:

- You want images close to AKS
- You want Azure-native authentication
- You want private image storage
- You want to practice enterprise-style image workflows

## Enable ACR

In terraform.tfvars:

    enable_acr = true

When enabled, Terraform creates:

- Azure Container Registry
- AcrPull role assignment for AKS

## Disable ACR

In terraform.tfvars:

    enable_acr = false

When disabled, Terraform does not create ACR.

You can still deploy public images from registries such as:

- Docker Hub
- GHCR
- Quay

## ACR settings

Common ACR variables:

    enable_acr
    acr_name
    acr_sku
    acr_admin_enabled

Example:

    enable_acr        = true
    acr_name          = "replacewithuniqueacr001"
    acr_sku           = "Basic"
    acr_admin_enabled = false

## ACR name must be globally unique

ACR names must be globally unique across Azure.

Use lowercase letters and numbers.

Example:

    acraksdev001andrew

Do not use uppercase letters or special characters.

## ACR SKU

Common SKU options:

- Basic
- Standard
- Premium

For learning, Basic is usually enough.

Example:

    acr_sku = "Basic"

Production-style environments may use Standard or Premium depending on requirements.

## ACR admin user

Recommended:

    acr_admin_enabled = false

Why?

The admin user uses username/password authentication.

For AKS, the better pattern is managed identity with AcrPull.

## AcrPull role assignment

If ACR is enabled, AKS needs permission to pull images from ACR.

Terraform creates an AcrPull role assignment.

High-level flow:

    AKS kubelet identity
              |
              v
    AcrPull role on ACR
              |
              v
    Pull private images from ACR

This avoids storing ACR username/password in Kubernetes secrets.

## Push images to ACR

Login to ACR:

    az acr login --name <acr-name>

Build an image:

    docker build -t <acr-login-server>/my-app:v1 .

Push the image:

    docker push <acr-login-server>/my-app:v1

Example login server:

    acraksdev001andrew.azurecr.io

## Deploy ACR image to AKS

Example image reference:

    acraksdev001andrew.azurecr.io/my-app:v1

Kubernetes Deployment example:

    image: acraksdev001andrew.azurecr.io/my-app:v1

If AcrPull is configured correctly, no imagePullSecret is required for ACR.

## Use Docker Hub public images

You can deploy public images from Docker Hub.

Example:

    image: nginx:latest

This does not require ACR.

## Use GitHub Container Registry

Public GHCR image example:

    image: ghcr.io/example-org/example-app:v1

Private GHCR images require imagePullSecret.

## Use GitLab Container Registry

GitLab Container Registry can also be used.

Public images may work without a secret.

Private GitLab registry images require imagePullSecret.

## Use private external registries

For private registries outside ACR, create a Kubernetes imagePullSecret.

Example:

    kubectl create secret docker-registry my-registry-secret \
      --docker-server=<registry-server> \
      --docker-username=<username> \
      --docker-password=<password> \
      --docker-email=<email> \
      -n <namespace>

Then reference it in the Deployment:

    imagePullSecrets:
      - name: my-registry-secret

## ACR vs external registries

Use ACR when:

- You want Azure-native integration
- You want managed identity-based image pulls
- You want private images near AKS
- You want to practice Azure enterprise patterns

Use external registries when:

- Your organization already uses Docker Hub, GHCR, GitLab, or another registry
- You want registry-agnostic labs
- You want to practice imagePullSecret workflows

## Recommended learning path

Beginner:

1. Deploy public image from Docker Hub
2. Enable ACR
3. Build and push image to ACR
4. Deploy ACR image to AKS

Practitioner:

1. Deploy from private external registry
2. Use imagePullSecret
3. Troubleshoot ImagePullBackOff
4. Compare ACR vs external registry flows

Professional:

1. Automate image build and push in CI/CD
2. Use immutable image tags
3. Promote images across dev, qa, and prod
4. Add image scanning and policy checks

## Common errors

### ImagePullBackOff

This means Kubernetes cannot pull the image.

Check:

    kubectl describe pod <pod-name> -n <namespace>

Common causes:

- Wrong image name
- Wrong image tag
- Private registry without credentials
- AcrPull role missing
- Registry unavailable
- Docker Hub rate limits

### ACR access denied

Possible causes:

- AKS kubelet identity does not have AcrPull
- Wrong ACR login server
- Image does not exist
- Wrong tag

Check ACR image list:

    az acr repository list --name <acr-name> --output table

Check tags:

    az acr repository show-tags --name <acr-name> --repository <repository-name> --output table

## Best practices

- Use unique image tags instead of latest for real environments
- Keep acr_admin_enabled false
- Use AcrPull for AKS to ACR access
- Use imagePullSecret only for external private registries
- Use dev, qa, and prod image promotion patterns
- Scan images before production deployment
