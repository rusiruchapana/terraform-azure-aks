# Practitioner Lab 06 - Azure DevOps DevSecOps Checks

This lab adds DevSecOps checks to the Azure DevOps learning flow.

It does not require:

- Azure credentials
- Registry credentials
- Paid security scanning accounts
- AKS access
- Azure DevOps service connections

It does not replace Lab 05.

Lab 05 teaches:

    Validate -> BuildPush -> Deploy -> Verify

This lab teaches:

    Validate -> ScanConfig -> BuildImages -> ScanImages -> Summary

## What you will learn

- How to add security checks to Azure DevOps Pipelines
- How to scan Dockerfiles and Kubernetes YAML
- How to build local container images in Azure Pipelines
- How to scan local container images
- How to read vulnerability findings
- How to switch from learning mode to strict security gate mode

## Tool used

This lab uses Trivy for learning security scans.

Trivy can scan:

- Container images
- Filesystems
- Kubernetes configuration
- Infrastructure configuration

## App used

This lab is designed to run against the 3-tier Node.js sample app:

    https://github.com/andrewferdinandus/3-tier-nodeapp

Expected app repository structure:

    backend/
    frontend/
    k8s/
    azure-pipelines-devsecops.yml

## Pipeline file

This platform repository stores the template here:

    labs/practitioner/06-azure-devops-devsecops/azure-pipelines/azure-pipelines-devsecops.yml

Copy it into the root of the app repository as:

    azure-pipelines-devsecops.yml

Then create a new Azure DevOps pipeline using that YAML file.

## Pipeline stages

The pipeline uses these stages:

    Validate
      |
      v
    ScanConfig
      |
      v
    BuildImages
      |
      v
    ScanImages
      |
      v
    Summary

## Learning mode

This lab runs in learning mode by default.

Learning mode means Trivy reports findings but does not fail the pipeline.

The pipeline uses:

    --exit-code 0

## Strict security gate mode

After you understand the scan output, you can make scans fail the pipeline when HIGH or CRITICAL vulnerabilities are found.

Change:

    --exit-code 0

to:

    --exit-code 1

Use strict mode carefully because public base images can contain vulnerabilities that require review, patching, or risk acceptance.

## Why this lab does not use variables or secrets

This lab is intentionally designed as a scan-only DevSecOps lab.

It does not use Azure DevOps pipeline variables such as:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Those variables are required for deployment pipelines because deployment pipelines need to:

- Log in to Azure
- Push images to ACR
- Get AKS credentials
- Run kubectl against the cluster

This DevSecOps lab does not do those actions.

Instead, it only:

- Validates files
- Scans Dockerfiles and Kubernetes YAML
- Builds container images locally on the pipeline agent
- Scans the local container images
- Shows a summary

This keeps the lab safe and beginner-friendly.

Learners can practice DevSecOps concepts without needing cloud credentials, registry access, AKS permissions, or paid security tools.

## Scan-only lab vs production pipeline

This lab separates security scanning from deployment so the learning goal is clear.

Lab 05 answers:

    How do I deploy an app to AKS with Azure DevOps?

Lab 06 answers:

    How do I add DevSecOps checks to Azure DevOps?

In a real production pipeline, DevSecOps checks are often combined with deployment:

    validate
      |
      v
    scan source and configuration
      |
      v
    build images
      |
      v
    scan images
      |
      v
    push images to registry
      |
      v
    deploy to AKS
      |
      v
    verify

That production-style pipeline would require credentials or, preferably, Azure DevOps service connections or federated identity.

For learning, this lab avoids secrets.

For production, prefer:

- Azure DevOps service connections
- OIDC or federated credentials where possible
- Least privilege permissions
- Environment approvals
- Secret rotation
- Strict scan gates for protected branches


## Why this lab does not deploy

This lab focuses on security checks.

Deployment is already covered in Lab 05.

A later advanced lab can combine DevSecOps checks with deployment approvals, service connections, OIDC, and environment gates.

## Expected result

The pipeline should:

- Validate required files
- Scan Dockerfiles and Kubernetes YAML
- Build backend and frontend images locally
- Scan backend and frontend images
- Report vulnerabilities in learning mode
- Finish without deploying anything to AKS

## Common findings

It is normal for image scans to report vulnerabilities in base images such as Node or NGINX.

This does not always mean the lab is broken.

In real DevSecOps workflows, review findings and decide what to do next.

Possible actions:

- Use newer base images
- Use smaller base images
- Rebuild after upstream patches are available
- Change base image family
- Document accepted risk
- Fail only on selected severity levels
- Use strict gates on production branches

## Cleanup

This workflow does not deploy to AKS.

No Kubernetes cleanup is required.

You may delete local or pipeline image artifacts after testing.

## Important note

This is a learning lab.

Production DevSecOps pipelines should also consider:

- Service connections
- OIDC or federated credentials
- Least privilege permissions
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code
