# Beginner Labs

These labs are designed for users who are new to AKS, Kubernetes, and Terraform-based platform usage.

The goal is to learn step by step.

Start from Lab 01 and continue in order.

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

Deploy a public NGINX image from Docker Hub to AKS.

What you learn:

- Kubernetes Namespace
- Deployment
- Service
- Public container image
- Pod verification
- Service verification
- kubectl port-forward

This lab does not use Gateway API yet.

Access method:

    kubectl port-forward

## Lab 02 - Expose the app using Gateway API

Folder:

    02-nginx-gateway

Goal:

Expose an application through the shared platform Gateway using Gateway API.

What you learn:

- Gateway API
- HTTPRoute
- Shared platform Gateway
- External access through Gateway IP
- Service backend routing

Shared Gateway:

    platform-gateway/public-gateway

This lab builds on the concepts from Lab 01.

## Lab 03 - Deploy an image from a container registry

Folder:

    03-registry-image

Goal:

Deploy a container image from ACR or another container registry.

What you learn:

- Container image references
- Image tags
- ACR image pull flow
- External registry image pull flow
- Public registry vs private registry
- imagePullSecret basics
- ImagePullBackOff troubleshooting basics

Supported paths:

- ACR enabled: use Azure Container Registry and AcrPull
- ACR disabled: use Docker Hub, GHCR, GitLab Container Registry, or another registry
- Private external registry: use imagePullSecret

## Lab 04 - Use persistent storage with PVCs

Folder:

    04-persistent-storage-pvc

Goal:

Attach persistent storage to a Kubernetes workload.

What you learn:

- PersistentVolumeClaim
- StorageClass
- volumeMount
- Data persistence basics
- Pod restart behavior

## Lab 05 - Basic Kubernetes troubleshooting

Folder:

    05-basic-troubleshooting

Goal:

Practice common beginner troubleshooting scenarios.

What you learn:

- kubectl get
- kubectl describe
- kubectl logs
- ImagePullBackOff
- CrashLoopBackOff
- Service selector mismatch
- Wrong container port
- HTTPRoute backend issues

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
