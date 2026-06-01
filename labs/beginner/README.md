# Beginner Labs

These labs are designed for users who are new to AKS and Kubernetes platform usage.

The goal is to learn basic Kubernetes concepts with small, focused labs.

Each lab is written to be usable on its own.

You can complete them in order for a smooth learning path, but the individual lab guides include their own requirements, files, verification steps, troubleshooting, and cleanup.

## Learning path

    Lab 01
      |
      v
    Lab 02
      |
      v
    Lab 03
      |
      v
    Lab 04
      |
      v
    Lab 05

## Lab 01 - Deploy a public Docker Hub image

Folder:

    01-public-nginx

Goal:

Deploy a public NGINX image from Docker Hub to AKS and access it locally.

What you learn:

- Kubernetes Namespace
- Deployment
- Service
- Public container image
- Pod verification
- Service verification
- `kubectl port-forward`

Access method:

    kubectl port-forward

## Lab 02 - Expose NGINX with Gateway API

Folder:

    02-nginx-gateway

Goal:

Expose NGINX through an existing shared platform Gateway using Gateway API.

What you learn:

- Gateway API basics
- HTTPRoute
- Shared platform Gateway
- External access through Gateway IP
- Service backend routing
- Gateway and HTTPRoute troubleshooting

Shared Gateway expected by the lab:

    platform-gateway/public-gateway

## Lab 03 - Deploy an image from a container registry

Folder:

    03-registry-image

Goal:

Deploy a container image from a public registry, Azure Container Registry, or a private external registry.

What you learn:

- Container image references
- Image tags
- Public registry image pulls
- ACR image pull flow
- Private registry image pull flow
- `imagePullSecret` basics
- `ImagePullBackOff` troubleshooting

Supported paths:

- Public image: use Docker Hub, GHCR, GitLab Container Registry, Quay, or another public registry
- ACR image: use Azure Container Registry and `AcrPull`
- Private external registry: use `imagePullSecret`

## Lab 04 - Persistent Storage with PVC

Folder:

    04-persistent-storage-pvc

Goal:

Attach persistent storage to a Kubernetes workload and test what happens when the pod is recreated.

What you learn:

- PersistentVolumeClaim
- StorageClass
- Dynamic provisioning
- volumeMount
- initContainer
- Data persistence basics
- Pod lifecycle vs storage lifecycle
- PVC cleanup safety

## Lab 05 - Basic Kubernetes Troubleshooting

Folder:

    05-basic-troubleshooting

Goal:

Practice common beginner troubleshooting scenarios with intentionally broken manifests.

What you learn:

- `kubectl get`
- `kubectl describe`
- `kubectl logs`
- `kubectl get endpoints`
- `kubectl get pods --show-labels`
- `ImagePullBackOff`
- Service selector mismatch
- Wrong Service `targetPort`
- Troubleshooting flow: observe, inspect, identify, fix, verify

## Common requirements

Most beginner labs require:

- kubectl
- Access to an AKS cluster
- A terminal
- A web browser for local or Gateway access tests

Some labs have additional requirements:

- Lab 02 requires Gateway API and an existing shared Gateway
- Lab 03 requires Azure CLI only if you test the ACR option
- Lab 04 requires a default StorageClass or a usable StorageClass

Read each lab README before running commands.

## Important note

These labs are beginner-friendly starter examples.

You are not limited to the provided examples.

After completing the labs, try replacing the sample app with:

- Your own application
- Your own Dockerfile
- Your own container image
- Your own Kubernetes manifests
- Your own registry
- Your own deployment workflow

This platform is app-agnostic and registry-agnostic.
