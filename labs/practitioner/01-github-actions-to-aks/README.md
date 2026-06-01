# Practitioner Lab 01 - GitHub Actions to AKS

This lab shows how to use GitHub Actions to build a small web application image, publish the image to Azure Container Registry, deploy it to AKS, and verify that the deployed application responds through a Kubernetes Service.

This is a standalone deployment lab.

The lab uses:

- A GitHub repository where you can run GitHub Actions
- A GitHub Actions workflow template
- Azure Container Registry
- AKS deployment
- GitHub repository secrets for Azure and registry access
- `kubectl port-forward` to test the deployed app locally

## Lab goal

By the end of this lab, you should have:

- A GitHub Actions workflow named `Build and deploy to AKS`
- A container image pushed to Azure Container Registry
- A Kubernetes namespace named `practitioner-github-actions`
- A deployment named `github-actions-demo`
- A service named `github-actions-demo`
- A working web page tested through `kubectl port-forward`

This lab does not expose the application publicly.

The final application test uses a temporary local tunnel from your laptop to the Kubernetes Service inside AKS:

    http://localhost:8084

Expected page text:

    GitHub Actions to AKS Lab
    This app was built and deployed by GitHub Actions.

## What you will learn

You will learn:

- How to prepare a GitHub Actions workflow for AKS deployment
- How to configure GitHub repository secrets
- How to build a container image in GitHub Actions
- How to publish a container image to Azure Container Registry
- How to verify that the pushed image exists in ACR
- How to authenticate to Azure from GitHub Actions
- How to get AKS credentials in a workflow
- How to deploy Kubernetes manifests from GitHub Actions
- How to verify Kubernetes rollout
- How to test the deployed app using `kubectl port-forward`
- How to clean up AKS, ACR, and copied workflow resources

## Lab architecture

The flow is:

    GitHub repository
      |
      v
    GitHub Actions workflow
      |
      v
    Validate files
      |
      v
    Docker image build
      |
      v
    Push image to Azure Container Registry
      |
      v
    Azure login
      |
      v
    AKS credentials
      |
      v
    Kubernetes deployment
      |
      v
    Rollout verification
      |
      v
    Port-forward service
      |
      v
    Browser or curl test

The GitHub Actions workflow uses these jobs:

    validate
      |
      v
    build-and-push
      |
      v
    deploy
      |
      v
    verify

## What this lab requires

You need:

- A GitHub account
- A GitHub repository where you can add workflow files and configure repository secrets
- Git
- Azure CLI
- kubectl
- A terminal
- A web browser
- An AKS cluster
- Azure Container Registry
- A service principal for CI/CD credentials

This lab builds the image on a GitHub-hosted runner.

You do not need Docker Desktop on your local machine for the GitHub Actions workflow.

## GitHub repository requirement

GitHub Actions workflows must live under this path in a GitHub repository:

    .github/workflows/

For this lab, use a repository that you own or maintain.

You can use your own copy of this learning repository.

Do not push lab workflow changes to a repository you do not own or maintain.

The workflow template stays in the lab folder:

    labs/practitioner/01-github-actions-to-aks/github-actions/build-deploy-aks.yaml

During the lab, you copy that template to:

    .github/workflows/build-deploy-aks.yaml

After the lab, remove the copied workflow if you do not want it to keep running on future pushes.

Do not delete the workflow template under the lab folder.

## Install required local tools

### Git

Install Git for your operating system:

    https://git-scm.com/downloads

Verify Git:

    git --version

Expected:

    git version should print successfully.

### Azure CLI

Install Azure CLI:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Verify Azure CLI:

    az version

Login to Azure:

    az login

Verify the active account:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

### kubectl

Install kubectl:

    https://kubernetes.io/docs/tasks/tools/

Verify kubectl:

    kubectl version --client

## Check local tools and Azure access

Before continuing, verify:

    git --version
    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl version --client

Set your AKS and ACR values:

    RESOURCE_GROUP="<resource-group-name>"
    AKS_NAME="<aks-cluster-name>"
    ACR_NAME="<acr-name>"

Verify AKS access:

    az aks get-credentials \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --overwrite-existing

    kubectl get nodes

Verify ACR:

    az acr show \
      --name "$ACR_NAME" \
      --query "{name:name, loginServer:loginServer}" \
      -o table

## Prepare Azure CI/CD variables

This lab deploys to AKS and publishes an image to Azure Container Registry.

Before running the workflow, prepare the required Azure and registry values using the shared guide:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

You will need these values for GitHub repository secrets:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

For this learning setup, the service principal should have enough permission to:

- Push images to ACR
- Get AKS credentials
- Apply Kubernetes manifests to the target namespace

## Configure GitHub repository secrets

In your GitHub repository, go to:

    Settings
    Secrets and variables
    Actions
    New repository secret

Create these repository secrets:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

For ACR in this learning setup:

    REGISTRY_USERNAME = AZURE_CLIENT_ID
    REGISTRY_PASSWORD = AZURE_CLIENT_SECRET

The secret names must exactly match the workflow.

Do not commit secrets into Git.

## Files in this lab

This lab includes:

    app/
      Static NGINX app files

    k8s/
      Kubernetes manifests

    github-actions/
      GitHub Actions workflow template

Files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    github-actions/build-deploy-aks.yaml

## Copy the workflow template

Run these commands from the `terraform-azure-aks` repository root.

Create the GitHub Actions workflow folder:

    mkdir -p .github/workflows

Copy the workflow template:

    cp labs/practitioner/01-github-actions-to-aks/github-actions/build-deploy-aks.yaml \
      .github/workflows/build-deploy-aks.yaml

Verify the copied workflow:

    test -f .github/workflows/build-deploy-aks.yaml

## Review the workflow trigger

The workflow supports both manual and push-based execution:

    workflow_dispatch

and:

    push to main

The push trigger watches:

    labs/practitioner/01-github-actions-to-aks/**
    .github/workflows/build-deploy-aks.yaml

This means the workflow can run when you push changes to the lab files or the workflow file on the `main` branch.

You can also run it manually from the GitHub Actions tab.

## Commit the workflow to your own GitHub repository

GitHub Actions can only run workflows that are committed to a GitHub repository.

Commit the copied workflow and lab files to your own repository:

    git add .github/workflows/build-deploy-aks.yaml
    git add labs/practitioner/01-github-actions-to-aks

    git commit -m "Add GitHub Actions AKS deployment lab"
    git push

Only push to a repository that you own or maintain.

Do not push these lab workflow changes to someone else's repository.

## Run the workflow

Open your GitHub repository in a browser.

Go to:

    Actions
    Build and deploy to AKS

You can run the workflow in either of these ways:

Option 1, manual run:

    Run workflow
    Branch: main
    Run workflow

Option 2, push trigger:

    Push a commit to main that changes the workflow or lab files.

The workflow should run these jobs:

    validate
    build-and-push
    deploy
    verify

## Verify the GitHub Actions run

Open the workflow run and check that each job succeeded:

    validate
    build-and-push
    deploy
    verify

The `build-and-push` job should show the image name and registry.

The `deploy` job should apply the namespace, deployment, and service.

The `verify` job should show pods and services in the target namespace.

## Image tag

The workflow builds the image and tags it with the GitHub commit SHA.

Example:

    myacr.azurecr.io/practitioner-github-actions:<commit-sha>

To see the local commit SHA:

    git rev-parse HEAD

The workflow uses the GitHub Actions commit SHA from the workflow run.

## Verify image in Azure Container Registry

After the workflow succeeds, verify that GitHub Actions pushed the image to ACR.

List repositories:

    az acr repository list \
      --name "$ACR_NAME" \
      --output table

Expected repository:

    practitioner-github-actions

List image tags:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository practitioner-github-actions \
      --output table

Expected:

    A tag matching the GitHub Actions commit SHA should be listed.

## Verify deployment in AKS

After the workflow succeeds, verify the Kubernetes resources:

    kubectl get ns practitioner-github-actions
    kubectl get deployment github-actions-demo -n practitioner-github-actions
    kubectl get pods -n practitioner-github-actions -o wide
    kubectl get svc github-actions-demo -n practitioner-github-actions

Expected:

    namespace exists
    deployment shows available replicas
    pod status is Running
    service exists

Check rollout:

    kubectl rollout status deployment/github-actions-demo -n practitioner-github-actions --timeout=180s

## Test the application with port-forward

This lab does not create a public Azure URL.

The Kubernetes Service is tested through `kubectl port-forward`.

Port-forward creates a temporary local connection from your laptop to the service running inside AKS.

Port-forward the service:

    kubectl port-forward svc/github-actions-demo -n practitioner-github-actions 8084:80

Open from your laptop:

    http://localhost:8084

Or test with curl from another terminal:

    curl http://localhost:8084

Expected page text:

    GitHub Actions to AKS Lab
    This app was built and deployed by GitHub Actions.

Stop the port-forward with `Ctrl+C`.

## Optional local manifest test

Before running the GitHub Actions workflow, you can test the Kubernetes manifests locally by replacing `IMAGE_PLACEHOLDER` with a public image.

This test validates the Kubernetes manifests, but it does not test GitHub Actions or ACR image publishing.

Run from the `terraform-azure-aks` repository root:

    kubectl apply -f labs/practitioner/01-github-actions-to-aks/k8s/namespace.yaml

    sed "s|IMAGE_PLACEHOLDER|nginx:1.27-alpine|g" \
      labs/practitioner/01-github-actions-to-aks/k8s/deployment.yaml \
      | kubectl apply -f -

    kubectl apply -f labs/practitioner/01-github-actions-to-aks/k8s/service.yaml

Verify:

    kubectl get pods -n practitioner-github-actions
    kubectl rollout status deployment/github-actions-demo -n practitioner-github-actions

Port-forward:

    kubectl port-forward svc/github-actions-demo -n practitioner-github-actions 8084:80

Open:

    http://localhost:8084

Stop the port-forward with `Ctrl+C`.

Clean up the optional local manifest test before running the full workflow if needed:

    kubectl delete namespace practitioner-github-actions --ignore-not-found

## Troubleshooting

### Workflow does not appear in the Actions tab

Verify the workflow file exists in the root GitHub Actions folder:

    .github/workflows/build-deploy-aks.yaml

The workflow template under the lab folder is not enough by itself.

GitHub Actions only runs workflow files under:

    .github/workflows/

### Workflow is not triggered by push

The workflow runs on pushes to `main` only when these paths change:

    labs/practitioner/01-github-actions-to-aks/**
    .github/workflows/build-deploy-aks.yaml

You can also run it manually using:

    Actions
    Build and deploy to AKS
    Run workflow

### Required file validation failed

If the `validate` job fails, verify the lab files exist in your repository:

    labs/practitioner/01-github-actions-to-aks/app/Dockerfile
    labs/practitioner/01-github-actions-to-aks/k8s/namespace.yaml
    labs/practitioner/01-github-actions-to-aks/k8s/deployment.yaml
    labs/practitioner/01-github-actions-to-aks/k8s/service.yaml

### Docker login or image push failed

If Docker login or image push fails, verify the GitHub repository secrets:

    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Check that the service principal has permission to push to ACR.

For a learning setup, the service principal usually needs `AcrPush` on the registry.

### Azure login failed

If Azure login fails, verify these GitHub repository secrets:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID

Also verify that the service principal secret has not expired.

### AKS credentials failed

If `az aks get-credentials` fails in the workflow, verify:

    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME

Also verify that the service principal has permission to read AKS cluster details.

### ImagePullBackOff

If the pod is stuck in `ImagePullBackOff`, check whether AKS can pull from ACR.

Check ACR access:

    az aks check-acr \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --acr <acr-name>

If needed, attach ACR:

    az aks update \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --attach-acr <acr-name>

### Rollout timeout

If rollout times out, inspect pods and events:

    kubectl get pods -n practitioner-github-actions -o wide
    kubectl describe pod -n practitioner-github-actions -l app=github-actions-demo
    kubectl get events -n practitioner-github-actions --sort-by=.lastTimestamp | tail -30

## Cleanup

Delete AKS resources:

    kubectl delete namespace practitioner-github-actions --ignore-not-found

Delete the ACR repository created by this lab:

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository practitioner-github-actions \
      --yes

If the workflow was copied only for this lab, remove it from the root GitHub Actions folder:

    rm -f .github/workflows/build-deploy-aks.yaml

Do not delete the workflow template under:

    labs/practitioner/01-github-actions-to-aks/github-actions/

Commit and push the cleanup change to your own repository if you no longer want the workflow to remain active:

    git add .github/workflows/build-deploy-aks.yaml
    git commit -m "Remove GitHub Actions AKS lab workflow"
    git push

If the file was already removed, `git add` may need:

    git add -u .github/workflows/build-deploy-aks.yaml

## Security cleanup

After testing, remove or rotate temporary service principal secrets used in GitHub repository secrets.

Do not commit secrets into Git.

Do not store long-lived credentials in local notes or screenshots.

For production, prefer:

- GitHub OIDC federation instead of long-lived client secrets
- Least privilege permissions
- Short-lived credentials
- Secret rotation
- Environment protection rules
- Required reviewers for protected environments

## Important note

This is a learning lab.

It uses Azure service principal secret authentication because it is easier for beginners to understand.

For production-style GitHub Actions workflows, prefer GitHub OIDC federation instead of long-lived client secrets.
