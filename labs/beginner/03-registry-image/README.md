# Beginner Lab 03 - Deploy Image from a Container Registry

This lab shows how to deploy a container image from a container registry to AKS.

This lab is registry-agnostic.

You can use:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- GitLab Container Registry
- Quay
- Another private registry

## What you will learn

- How Kubernetes references container images
- How to deploy an image from a registry
- Difference between public and private registries
- How ACR works with AKS AcrPull permission
- When imagePullSecret is required
- How to troubleshoot ImagePullBackOff

## Registry options

### Option A - ACR enabled

Use this path if your platform has ACR enabled.

Example image:

    myacr.azurecr.io/demo-web:v1

If AcrPull is configured correctly, AKS can pull from ACR without imagePullSecret.

### Option B - Public external registry

Use this path if you want to use a public image from Docker Hub, GHCR, GitLab, Quay, or another registry.

Examples:

    nginx:1.27-alpine
    docker.io/library/nginx:1.27-alpine
    ghcr.io/example-org/example-app:v1

Public images usually do not need imagePullSecret.

### Option C - Private external registry

Use this path if your image is in a private registry outside ACR.

Private registries usually need imagePullSecret.

Example:

    kubectl create secret docker-registry registry-secret \
      --docker-server=<registry-server> \
      --docker-username=<username> \
      --docker-password=<password> \
      --docker-email=<email> \
      -n beginner-registry

Then add this to the Deployment:

    imagePullSecrets:
      - name: registry-secret

## Before you deploy

Open this file:

    manifests/deployment.yaml

Replace the image value:

    image: nginx:1.27-alpine

With your own registry image if needed.

Examples:

    image: myacr.azurecr.io/demo-web:v1
    image: docker.io/myuser/demo-web:v1
    image: ghcr.io/myorg/demo-web:v1

For the first test, you can keep the public NGINX image.

## Deploy the lab

From the repository root, apply the namespace first:

    kubectl apply -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/namespace.yaml

Then apply the app resources:

    kubectl apply -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/deployment.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/service.yaml

## Verify resources

Check pods:

    kubectl get pods -n beginner-registry

Check service:

    kubectl get svc -n beginner-registry

Check rollout:

    kubectl rollout status deployment/registry-demo -n beginner-registry

## Access the app locally

Use port-forward:

    kubectl port-forward svc/registry-demo -n beginner-registry 8081:80

Open in browser:

    http://localhost:8081

If you kept the default NGINX image, you should see the NGINX welcome page.

## Troubleshooting

### ImagePullBackOff

Check the pod:

    kubectl get pods -n beginner-registry
    kubectl describe pod -n beginner-registry <pod-name>

Common causes:

- Image name is wrong
- Image tag is wrong
- Registry requires authentication
- imagePullSecret is missing
- ACR AcrPull permission is missing
- Image does not exist in the registry

### ACR image cannot be pulled

Check:

- ACR name is correct
- Image exists in ACR
- Image tag is correct
- AKS kubelet identity has AcrPull on the ACR

Useful commands:

    az acr repository list --name <acr-name> --output table
    az acr repository show-tags --name <acr-name> --repository <repository-name> --output table

### Private external image cannot be pulled

Check:

- imagePullSecret exists in the same namespace
- Deployment references the imagePullSecret
- Registry username/password/token is correct
- Registry server name is correct

Check secret:

    kubectl get secret -n beginner-registry

## Cleanup

Delete the lab resources:

    kubectl delete -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/service.yaml
    kubectl delete -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/deployment.yaml
    kubectl delete -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/namespace.yaml

This removes only the lab resources.
