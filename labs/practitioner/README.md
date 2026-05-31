# Practitioner Labs

Practitioner labs are for users who already understand basic AKS and Kubernetes concepts.

These labs focus on real DevOps workflows on top of the AKS platform.

For the current full lab order, see:

    ../README.md

## Track goal

Practice building, pushing, deploying, observing, and securing applications on AKS.

## Current practitioner flow

1. GitHub Actions to AKS
2. GitHub Actions DevSecOps Checks
3. GitLab CI/CD to AKS
4. GitLab CI/CD DevSecOps Checks
5. Azure DevOps to AKS
6. Azure DevOps DevSecOps Checks
7. Jenkins to AKS
8. Jenkins DevSecOps Checks
9. Key Vault and Workload Identity
10. Monitoring Basics
11. OpenTelemetry App

## Lab 01 - GitHub Actions to AKS

Folder:

    01-github-actions-to-aks

Goal:

Use GitHub Actions to build a container image, push it to a registry, and deploy it to AKS.

## Lab 02 - GitHub Actions DevSecOps Checks

Folder:

    02-github-actions-devsecops

Goal:

Add security checks to a GitHub Actions workflow without requiring cloud credentials or paid security accounts.

## Lab 03 - GitLab CI/CD to AKS

Folder:

    03-gitlab-ci-to-aks

Goal:

Use GitLab CI/CD to build, push, and deploy an application to AKS.

## Lab 04 - GitLab CI/CD DevSecOps Checks

Folder:

    04-gitlab-ci-devsecops

Goal:

Add security checks to a GitLab CI/CD workflow without requiring cloud credentials or paid security accounts.

## Lab 05 - Azure DevOps to AKS

Folder:

    05-azure-devops-to-aks

Goal:

Use Azure DevOps Pipelines to build, push, and deploy a 3-tier application to AKS.

## Lab 06 - Azure DevOps DevSecOps Checks

Folder:

    06-azure-devops-devsecops

Goal:

Add security checks to an Azure DevOps Pipeline without requiring cloud credentials or paid security accounts.

What you learn:

- Azure DevOps security stages
- Dockerfile scanning
- Kubernetes manifest scanning
- Local container image scanning
- Security checks before deployment
- Why DevSecOps belongs in CI/CD

## Lab 07 - Jenkins to AKS

Folder:

    07-jenkins-to-aks

Goal:

Use Jenkins to build and deploy an application to AKS.

## Lab 08 - Jenkins DevSecOps Checks

Folder:

    08-jenkins-devsecops

Goal:

Add DevSecOps checks to a Jenkins pipeline.

## Lab 09 - Key Vault and Workload Identity

Folder:

    09-key-vault-workload-identity

Goal:

Use AKS Workload Identity to let an application read a secret from Azure Key Vault.

## Lab 10 - Monitoring Basics

Folder:

    10-monitoring-basics

Goal:

Use Prometheus and Grafana to observe cluster and workload metrics.

## Lab 11 - OpenTelemetry App

Folder:

    11-opentelemetry-app

Goal:

Send application telemetry to the OpenTelemetry Collector.

## Important note

These labs are practice examples.

They are not strict production templates.

After completing a lab, replace the sample app, registry, image tag, credentials method, and deployment strategy with your own workflow.
