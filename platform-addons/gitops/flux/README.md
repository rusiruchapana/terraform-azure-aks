# Flux Add-on

Flux can be installed later as an optional GitOps lab.

This project keeps Flux outside the core Terraform platform so users can choose between Argo CD, Flux, or no GitOps tool.

## Why Flux is optional

The core Terraform platform creates the Azure infrastructure and AKS cluster.

Flux is a platform add-on that runs on top of AKS.

Not every learner or project needs Flux from the beginning.

## Recommended learning approach

1. Create the AKS platform with Terraform
2. Verify the cluster is healthy
3. Learn basic Kubernetes deployments first
4. Install Flux as an optional GitOps lab
5. Connect Flux to this Git repository
6. Deploy an application from Git
7. Practice dev to qa to prod promotion

## Safe access

Flux does not require a public dashboard by default.

Keep GitOps control internal and Git-driven.

## Future lab topics

Planned Flux labs:

- Install Flux
- Bootstrap Flux with this repository
- Deploy an app from Git
- Use Kustomize overlays
- Use HelmRelease resources
- Practice drift detection
- Practice image update automation
- Practice environment promotion
