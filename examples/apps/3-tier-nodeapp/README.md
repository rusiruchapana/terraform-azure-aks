# 3-Tier Node.js Sample App

This folder references a real-world sample application that can be used with this AKS DevOps Practice Platform.

Sample app repository:

    https://github.com/andrewferdinandus/3-tier-nodeapp

## Purpose

The 3-tier Node.js app can be used for more realistic AKS practice beyond simple NGINX examples.

The app can be adapted for:

- Docker image builds
- ACR image pushes
- AKS deployments
- Gateway API routing
- CI/CD pipelines
- DevSecOps scans
- GitOps workflows
- Monitoring and observability
- dev / qa / prod promotion

## App type

The app is a typical 3-tier application:

- Frontend
- Backend API
- Database

The app source code is cloud-agnostic.

Any AWS-related wording in the app repository can be adapted for Azure AKS labs.

## Why this app is useful

Simple NGINX labs are good for learning Kubernetes basics.

A 3-tier app is better for practicing real DevOps workflows such as:

- Multiple container images
- Multiple services
- Environment variables
- Secrets
- Database connectivity
- Persistent storage
- Application-level troubleshooting
- Release promotion
- Observability

## Recommended use

Use this app after completing the beginner labs and basic practitioner CI/CD labs.

Recommended future labs:

- Deploy 3-tier Node.js app to AKS
- Build and push frontend/backend images to ACR
- Configure app settings with ConfigMaps
- Configure secrets with Key Vault and Workload Identity
- Expose frontend using Gateway API
- Add monitoring dashboards
- Add DevSecOps scanning
- Promote versions from dev to qa to prod
- Manage deployment using GitOps

## Important note

Do not copy secrets into this repository.

Do not commit local environment files.

Use this sample app as a learning application and adapt it to your own application structure.
