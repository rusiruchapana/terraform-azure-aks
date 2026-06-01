# Practitioner Lab 06 - Azure DevOps DevSecOps Checks

This lab shows how to run DevSecOps checks in Azure DevOps Pipelines before any deployment happens.

This is a standalone scan-only lab.

It does not deploy to AKS.

It does not push images to a container registry.

The lab uses:

- An Azure DevOps project where you can run pipelines
- An Azure DevOps pipeline template
- Trivy for security scanning
- Backend and frontend Dockerfiles used as image scan targets
- Kubernetes manifests used as config scan targets
- Local image builds inside the Azure DevOps pipeline agent
- Azure DevOps pipeline output for scan results

## Lab goal

By the end of this lab, you should have:

- An Azure DevOps pipeline using `azure-pipelines-devsecops.yml`
- A pipeline run that validates required files
- A pipeline run that scans Dockerfiles and Kubernetes YAML
- A pipeline run that builds backend and frontend images locally inside CI
- A pipeline run that scans the local backend and frontend images
- No AKS resources created by this lab
- No container image pushed to a registry by this lab

This lab focuses on security checks only.

## What you will learn

You will learn:

- How to prepare a scan-only Azure DevOps pipeline
- How to run DevSecOps checks without Azure deployment credentials
- How to scan Dockerfiles and Kubernetes YAML with Trivy
- How to build local images inside Azure DevOps Pipelines
- How to scan locally built images
- How to read Trivy vulnerability output
- How to switch from learning mode to strict security gate mode
- Why supply-chain pinning matters for CI/CD tools
- How to clean up copied app repository files after the lab

## Lab architecture

The flow is:

    Azure DevOps project
      |
      v
    Azure DevOps Pipeline
      |
      v
    Validate files
      |
      v
    Scan Dockerfiles and Kubernetes YAML
      |
      v
    Build backend and frontend images locally
      |
      v
    Save image artifacts
      |
      v
    Scan backend and frontend images
      |
      v
    Summary

The Azure DevOps pipeline uses these stages:

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

## What this lab requires

You need:

- Azure DevOps account
- Azure DevOps project where you can create and run pipelines
- Git repository connected to Azure DevOps Pipelines
- Git
- A terminal
- A web browser

This lab does not require:

- Azure credentials
- Registry credentials
- AKS access
- Azure DevOps service connections
- Paid security scanning accounts
- Docker Desktop on your local machine

The image builds happen on the Azure DevOps pipeline agent.

## Azure DevOps project and repository requirement

Azure DevOps Pipelines can run from:

- Azure Repos Git
- GitHub connected to Azure Pipelines

For this lab, use a repository that you own or maintain.

Do not push lab pipeline changes to a repository you do not own or maintain.

The pipeline template stays in the lab folder:

    labs/practitioner/06-azure-devops-devsecops/azure-pipelines/azure-pipelines-devsecops.yml

During the lab, you copy that template to the root of your app repository as:

    azure-pipelines-devsecops.yml

After the lab, remove the copied pipeline file from your app repository if you do not want it to keep running on future pushes.

Do not delete the pipeline template under the lab folder.

## App source

This lab is designed to run against a 3-tier Node.js sample app repository.

Sample app repository:

    https://github.com/andrewferdinandus/3-tier-nodeapp

Use your own copy of the sample app repository for this lab.

The learning platform repository stores the DevSecOps pipeline template and scan target reference files.

## Install required local tools

### Git

Install Git for your operating system:

    https://git-scm.com/downloads

Verify Git:

    git --version

Expected:

    git version should print successfully.

## Check local tools

Before continuing, verify:

    git --version

## Files in this lab

This lab includes:

    backend/
      Backend Dockerfile used as an image scan target

    frontend/
      Frontend Dockerfile and NGINX configuration used as scan targets

    k8s/
      Kubernetes manifests used as config scan targets

    azure-pipelines/
      Azure DevOps DevSecOps pipeline template

Files:

    backend/Dockerfile
    frontend/Dockerfile
    frontend/nginx.conf
    k8s/namespace.yaml
    k8s/mysql-secret.yaml
    k8s/mysql-init-configmap.yaml
    k8s/mysql-pvc.yaml
    k8s/mysql-deployment.yaml
    k8s/mysql-service.yaml
    k8s/backend-deployment.yaml
    k8s/backend-service.yaml
    k8s/frontend-deployment.yaml
    k8s/frontend-service.yaml
    azure-pipelines/azure-pipelines-devsecops.yml

These app and Kubernetes files are scan targets for this lab.

They are not deployed by this lab.

## Copy files into the app repository

Run these commands from the `terraform-azure-aks` repository root.

Set a local path to your 3-tier app repository clone:

    APP_REPO_DIR="<path-to-your-3-tier-nodeapp-repo>"

Example:

    APP_REPO_DIR="$HOME/terraform-azure-aks-labs/3-tier-nodeapp"

Create folders in your app repository:

    mkdir -p "$APP_REPO_DIR/backend"
    mkdir -p "$APP_REPO_DIR/frontend"
    mkdir -p "$APP_REPO_DIR/k8s"

Copy the lab files:

    cp labs/practitioner/06-azure-devops-devsecops/backend/Dockerfile "$APP_REPO_DIR/backend/Dockerfile"
    cp labs/practitioner/06-azure-devops-devsecops/frontend/Dockerfile "$APP_REPO_DIR/frontend/Dockerfile"
    cp labs/practitioner/06-azure-devops-devsecops/frontend/nginx.conf "$APP_REPO_DIR/frontend/nginx.conf"
    cp labs/practitioner/06-azure-devops-devsecops/k8s/* "$APP_REPO_DIR/k8s/"
    cp labs/practitioner/06-azure-devops-devsecops/azure-pipelines/azure-pipelines-devsecops.yml "$APP_REPO_DIR/azure-pipelines-devsecops.yml"

Verify the app repository structure:

    find "$APP_REPO_DIR" -maxdepth 3 -type f | sort

Expected important files:

    backend/Dockerfile
    backend/package.json
    backend/server.js
    frontend/Dockerfile
    frontend/nginx.conf
    frontend/package.json
    frontend/src/App.js
    k8s/namespace.yaml
    k8s/backend-deployment.yaml
    k8s/backend-service.yaml
    k8s/frontend-deployment.yaml
    k8s/frontend-service.yaml
    k8s/mysql-deployment.yaml
    k8s/mysql-service.yaml
    azure-pipelines-devsecops.yml

## Commit the pipeline to your app repository

Azure DevOps Pipelines can only run pipeline files committed to the connected repository.

Move into your app repository clone:

    cd "$APP_REPO_DIR"

Commit the copied Dockerfiles, manifests, NGINX config, and pipeline file:

    git add backend/Dockerfile frontend/Dockerfile frontend/nginx.conf k8s azure-pipelines-devsecops.yml
    git commit -m "Add Azure DevOps DevSecOps checks lab"
    git push

Only push to a repository that you own or maintain.

Do not push these lab pipeline changes to someone else's repository.

## Create or connect the Azure DevOps pipeline

In Azure DevOps:

    Pipelines
    New pipeline

Choose your repository source:

    Azure Repos Git

or:

    GitHub

Select the app repository.

Choose existing YAML pipeline.

Set the YAML path:

    azure-pipelines-devsecops.yml

Save and run the pipeline.

## Run the pipeline

The pipeline should run these stages:

    Validate
    ScanConfig
    BuildImages
    ScanImages
    Summary

Open the pipeline run and check that each stage completes.

## Verify the Azure DevOps pipeline run

The `Validate` stage should confirm required files exist.

The `ScanConfig` stage should show Trivy config scan output.

The `BuildImages` stage should build backend and frontend images locally.

The `ScanImages` stage should show Trivy image scan output for both images.

The `Summary` stage should explain that this lab does not deploy to AKS.

## Expected result

The pipeline should:

- Validate required files
- Scan Dockerfiles and Kubernetes YAML
- Build backend and frontend images locally
- Save backend and frontend image artifacts
- Scan backend and frontend images
- Report vulnerabilities in learning mode
- Avoid pushing images to a registry
- Avoid deploying anything to AKS

## Image platform note

The pipeline builds both images for `linux/amd64`.

This is useful because most AKS node pools use amd64 nodes.

It also avoids image platform mismatch when an agent uses ARM hardware.

## Learning mode

This lab runs in learning mode by default.

Learning mode means Trivy reports findings but does not fail the pipeline.

The pipeline uses:

    --exit-code 0

## Strict security gate mode

After you understand the scan output, you can make scans fail the pipeline when HIGH or CRITICAL vulnerabilities are found.

Change:

    --exit-code 0

To:

    --exit-code 1

Use strict mode carefully.

Public base images can include vulnerabilities that require review, patching, or documented risk acceptance.

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

## Scan-only lab vs production pipeline

This lab separates security scanning from deployment so the learning goal is clear.

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

## Important supply-chain note

Security tools are also dependencies.

Pin container image versions carefully and review upstream project security advisories.

For stronger production-style security, pin tools to trusted versions and rotate secrets if you suspect a compromised CI/CD dependency.

## Trivy notices

Trivy may print notices such as:

    A newer Trivy version is available
    VEX notice

These are informational.

They do not always mean the pipeline failed.

Focus first on:

- vulnerability severity
- whether a fix is available
- whether the affected package is actually used
- whether this is a learning lab or production deployment

## What to do if the image scan fails

Read the vulnerability output.

Possible actions:

- Use a newer base image
- Use a smaller base image
- Patch dependencies
- Rebuild the image
- Accept risk only through a documented exception process

## Troubleshooting

### Pipeline does not start

Verify `azure-pipelines-devsecops.yml` exists in the root of the connected app repository:

    azure-pipelines-devsecops.yml

The pipeline template under the lab folder is not enough by itself.

Azure DevOps uses the pipeline file from the connected repository.

### Required file validation failed

If the `Validate` stage fails, verify these files exist in your app repository:

    backend/Dockerfile
    backend/package.json
    backend/server.js
    frontend/Dockerfile
    frontend/nginx.conf
    frontend/package.json
    frontend/src/App.js
    k8s/namespace.yaml
    k8s/backend-deployment.yaml
    k8s/backend-service.yaml
    k8s/frontend-deployment.yaml
    k8s/frontend-service.yaml
    k8s/mysql-deployment.yaml
    k8s/mysql-service.yaml

### Trivy reports vulnerabilities

This is expected in many learning labs.

Read the severity, package name, installed version, fixed version, and vulnerability description.

Decide whether the finding should block the pipeline.

### Docker build failed

Check the `BuildImages` stage logs.

Verify the Dockerfiles exist:

    backend/Dockerfile
    frontend/Dockerfile

### No AKS resources were created

This is expected.

This lab is scan-only and does not deploy to AKS.

## Cleanup

This lab does not create AKS resources.

This lab does not push images to a registry.

No Kubernetes or ACR cleanup is required.

If the files were copied only for this lab, remove them from your app repository clone:

    cd "$APP_REPO_DIR"

    rm -rf k8s azure-pipelines-devsecops.yml
    rm -f backend/Dockerfile
    rm -f frontend/Dockerfile
    rm -f frontend/nginx.conf

Commit and push the cleanup change to your own app repository if you no longer want the pipeline to remain active:

    git add -A backend/Dockerfile frontend/Dockerfile frontend/nginx.conf k8s azure-pipelines-devsecops.yml
    git commit -m "Remove Azure DevOps DevSecOps checks lab files"
    git push

Do not delete the lab templates under:

    labs/practitioner/06-azure-devops-devsecops/

## Security cleanup

This lab does not use Azure credentials or registry credentials.

If you added any temporary secrets while experimenting, remove or rotate them.

Do not commit secrets into Git.

For production, prefer:

- Least privilege permissions
- Azure DevOps service connections
- OIDC or federated credentials where possible
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code

## Important note

This is a learning lab.

It teaches DevSecOps scanning in Azure DevOps Pipelines without cloud deployment credentials.

A production DevSecOps pipeline should combine scanning, approvals, least privilege identity, SBOM generation, image signing, and policy validation.
