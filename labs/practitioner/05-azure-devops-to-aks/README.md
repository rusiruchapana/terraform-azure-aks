# Practitioner Lab 05 - Azure DevOps to AKS

This lab shows how to use Azure DevOps Pipelines to build backend and frontend application images, publish both images to Azure Container Registry, deploy a 3-tier application to AKS, and verify that the application works through a Kubernetes Service.

This is a standalone deployment lab.

The lab uses a 3-tier Node.js sample application:

- MySQL database
- Node.js backend API
- React frontend served by NGINX
- NGINX reverse proxy from the frontend to the backend service

The frontend routes browser requests for `/api` and `/health` to the backend service inside the cluster.

## Lab goal

By the end of this lab, you should have:

- An Azure DevOps pipeline using `azure-pipelines.yml`
- A backend image pushed to Azure Container Registry
- A frontend image pushed to Azure Container Registry
- A Kubernetes namespace named `practitioner-azure-devops`
- A MySQL deployment and service
- A backend deployment and service
- A frontend deployment and service
- A working frontend proxy tested through `kubectl port-forward`

This lab does not expose the application publicly.

The final application test uses a temporary local tunnel from your laptop to the frontend Kubernetes Service inside AKS:

    http://localhost:8087

Expected health response:

    {"status":"UP","database":"CONNECTED"}

## What you will learn

You will learn:

- How to prepare an Azure DevOps pipeline for AKS deployment
- How to configure Azure DevOps pipeline variables
- How to build backend and frontend container images
- How to publish both images to Azure Container Registry
- How to verify that pushed images exist in ACR
- How to authenticate to Azure from Azure DevOps Pipelines
- How to get AKS credentials in a pipeline
- How to deploy MySQL, backend, and frontend Kubernetes manifests
- How to verify Kubernetes rollouts
- How to test the deployed app using `kubectl port-forward`
- How to clean up AKS, ACR, and copied app repository resources

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
    Build backend image
      |
      v
    Build frontend image
      |
      v
    Push images to Azure Container Registry
      |
      v
    Azure login
      |
      v
    AKS credentials
      |
      v
    Deploy MySQL
      |
      v
    Deploy backend API
      |
      v
    Deploy frontend
      |
      v
    Rollout verification
      |
      v
    Port-forward frontend service
      |
      v
    Browser or curl test

The Azure DevOps pipeline uses these stages:

    Validate
      |
      v
    BuildPush
      |
      v
    Deploy
      |
      v
    Verify

## What this lab requires

You need:

- Azure DevOps account
- Azure DevOps project where you can create and run pipelines
- Git repository connected to Azure DevOps Pipelines
- Git
- Azure CLI
- kubectl
- A terminal
- A web browser
- An AKS cluster
- Azure Container Registry
- A service principal for CI/CD credentials

This lab builds the images on an Azure DevOps pipeline agent.

You do not need Docker Desktop on your local machine unless you want to run the optional local backend validation.

## Azure DevOps project and repository requirement

Azure DevOps Pipelines can run from:

- Azure Repos Git
- GitHub connected to Azure Pipelines

For this lab, use a repository that you own or maintain.

Do not push lab pipeline changes to a repository you do not own or maintain.

The pipeline template stays in the lab folder:

    labs/practitioner/05-azure-devops-to-aks/azure-pipelines/azure-pipelines.yml

During the lab, you copy that template to the root of your app repository as:

    azure-pipelines.yml

After the lab, remove the copied pipeline file from your app repository if you do not want it to keep running on future pushes.

Do not delete the pipeline template under the lab folder.

## App source

This lab uses a separate 3-tier Node.js sample app repository as the application source.

Sample app repository:

    https://github.com/andrewferdinandus/3-tier-nodeapp

Use your own copy of the sample app repository for this lab.

The learning platform repository stores the lab template and reference files only.

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

### Docker Desktop for optional local validation

Docker Desktop is optional for this lab.

You only need Docker Desktop if you want to run the optional local backend container test.

Install Docker Desktop:

    https://www.docker.com/products/docker-desktop/

Verify Docker:

    docker version

## Check local tools and Azure access

Before continuing, verify:

    git --version
    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl version --client

Set your AKS and ACR names:

    AZURE_RESOURCE_GROUP="<your-resource-group>"
    AKS_CLUSTER_NAME="<your-aks-cluster-name>"
    ACR_NAME="<your-acr-name>"

Verify AKS access:

    az aks get-credentials \
      --resource-group "$AZURE_RESOURCE_GROUP" \
      --name "$AKS_CLUSTER_NAME" \
      --overwrite-existing

    kubectl get nodes

Verify ACR:

    az acr show \
      --name "$ACR_NAME" \
      --query "{name:name, loginServer:loginServer}" \
      -o table

## Find your Azure values

Use these commands to find the values needed for Azure DevOps pipeline variables.

List resource groups:

    az group list --query "[].name" -o table

List AKS clusters:

    az aks list --query "[].{name:name, resourceGroup:resourceGroup}" -o table

List Azure Container Registries:

    az acr list --query "[].{name:name, resourceGroup:resourceGroup, loginServer:loginServer}" -o table

Set your values:

    AZURE_RESOURCE_GROUP="<your-resource-group>"
    AKS_CLUSTER_NAME="<your-aks-cluster-name>"
    ACR_NAME="<your-acr-name>"

Get the ACR login server:

    REGISTRY_LOGIN_SERVER="$(az acr show \
      --name "$ACR_NAME" \
      --query loginServer \
      -o tsv)"

Verify:

    echo "$AZURE_RESOURCE_GROUP"
    echo "$AKS_CLUSTER_NAME"
    echo "$ACR_NAME"
    echo "$REGISTRY_LOGIN_SERVER"

Do not copy values from another environment.

Use the values from your own Azure subscription.

## Prepare Azure CI/CD variables

This lab deploys to AKS and publishes images to Azure Container Registry.

Before running the pipeline, prepare the required Azure and registry values using the shared guide:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

You will need these values for Azure DevOps pipeline variables:

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

## Configure Azure DevOps pipeline variables

In Azure DevOps, go to:

    Pipelines
    Select your pipeline
    Edit
    Variables

Create these variables:

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

Mark these variables as secret:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

The variable names must exactly match the pipeline.

Do not commit secrets into Git.

## Files in this lab

This lab includes:

    backend/Dockerfile
      Dockerfile used to build the backend image

    frontend/Dockerfile
      Dockerfile used to build the React frontend image

    frontend/nginx.conf
      NGINX reverse proxy configuration for frontend-to-backend traffic

    k8s/
      Kubernetes manifests for MySQL, backend, and frontend

    azure-pipelines/
      Azure DevOps pipeline template

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
    azure-pipelines/azure-pipelines.yml

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

    cp labs/practitioner/05-azure-devops-to-aks/backend/Dockerfile "$APP_REPO_DIR/backend/Dockerfile"
    cp labs/practitioner/05-azure-devops-to-aks/frontend/Dockerfile "$APP_REPO_DIR/frontend/Dockerfile"
    cp labs/practitioner/05-azure-devops-to-aks/frontend/nginx.conf "$APP_REPO_DIR/frontend/nginx.conf"
    cp labs/practitioner/05-azure-devops-to-aks/k8s/* "$APP_REPO_DIR/k8s/"
    cp labs/practitioner/05-azure-devops-to-aks/azure-pipelines/azure-pipelines.yml "$APP_REPO_DIR/azure-pipelines.yml"

Verify the app repository structure:

    find "$APP_REPO_DIR" -maxdepth 3 -type f | sort

Expected important files:

    backend/Dockerfile
    backend/package.json
    backend/package-lock.json
    backend/server.js
    frontend/Dockerfile
    frontend/nginx.conf
    frontend/package.json
    frontend/src/App.js
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
    azure-pipelines.yml

## Update frontend backend paths

The frontend should call the backend through the NGINX reverse proxy.

In the frontend app, use relative backend paths:

    const BACKEND_URL = '/api';

And for health checks:

    fetch('/health');

This allows the frontend service to proxy requests to the backend service inside the cluster.

## Commit the pipeline to your app repository

Azure DevOps Pipelines can only run pipeline files committed to the connected repository.

Move into your app repository clone:

    cd "$APP_REPO_DIR"

Commit the copied Dockerfiles, manifests, NGINX config, and pipeline file:

    git add backend/Dockerfile frontend/Dockerfile frontend/nginx.conf k8s azure-pipelines.yml
    git commit -m "Add Azure DevOps AKS deployment lab"
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

    azure-pipelines.yml

Save and run the pipeline.

## Run the pipeline

The pipeline should run these stages:

    Validate
    BuildPush
    Deploy
    Verify

Open the pipeline run and check that each stage succeeds.

## Verify the Azure DevOps pipeline run

The `Validate` stage should confirm required files exist.

The `BuildPush` stage should build and push both images:

    node-backend
    node-frontend

The `Deploy` stage should apply MySQL, backend, and frontend resources.

The `Verify` stage should show rollout status for backend and frontend deployments.

## Image tag

The pipeline tags images with the Azure DevOps source version:

    $(Build.SourceVersion)

Example:

    myacr.azurecr.io/node-backend:<commit-sha>
    myacr.azurecr.io/node-frontend:<commit-sha>

## Image platform note

The pipeline builds both images for `linux/amd64`.

This is useful because most AKS node pools use amd64 nodes.

It also avoids image platform mismatch when an agent uses ARM hardware.

## Verify images in Azure Container Registry

After the pipeline succeeds, verify that Azure DevOps pushed both images to ACR.

List repositories:

    az acr repository list \
      --name "$ACR_NAME" \
      --output table

Expected repositories:

    node-backend
    node-frontend

List backend image tags:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository node-backend \
      --output table

List frontend image tags:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository node-frontend \
      --output table

Expected:

    A tag matching the Azure DevOps source version should be listed for each repository.

## Verify deployment in AKS

After the pipeline succeeds, verify the Kubernetes resources:

    kubectl get ns practitioner-azure-devops
    kubectl get pods -n practitioner-azure-devops -o wide
    kubectl get svc -n practitioner-azure-devops
    kubectl get pvc -n practitioner-azure-devops

Check rollouts:

    kubectl rollout status deployment/mysql -n practitioner-azure-devops --timeout=180s
    kubectl rollout status deployment/node-backend -n practitioner-azure-devops --timeout=180s
    kubectl rollout status deployment/node-frontend -n practitioner-azure-devops --timeout=180s

Expected:

    MySQL pod is Running
    backend pod is Running
    frontend pod is Running
    services exist
    PVC is Bound

## Test the application with port-forward

This lab does not create a public Azure URL.

The frontend Kubernetes Service is tested through `kubectl port-forward`.

Port-forward creates a temporary local connection from your laptop to the frontend service running inside AKS.

Port-forward the frontend service:

    kubectl port-forward svc/node-frontend -n practitioner-azure-devops 8087:80

Test health through the frontend proxy:

    curl http://localhost:8087/health

Expected:

    {"status":"UP","database":"CONNECTED"}

Test tasks API through the frontend proxy:

    curl http://localhost:8087/api/tasks

Open from your laptop:

    http://localhost:8087

Stop the port-forward with `Ctrl+C`.

## Optional local backend validation

This optional test requires Docker Desktop and a reachable local database.

Run from the app repository clone:

    cd "$APP_REPO_DIR"

Build the backend image:

    docker build --platform linux/amd64 -t node-backend-test backend

Run the backend container:

    docker run --rm -p 5002:5000 \
      -e DB_HOST=host.docker.internal \
      -e DB_USER=root \
      -e DB_PASSWORD=password \
      -e DB_NAME=devops_db \
      node-backend-test

Test health:

    curl http://localhost:5002/health

If a local database is available, expected output:

    {"status":"UP","database":"CONNECTED"}

## Troubleshooting

### Pipeline does not start

Verify `azure-pipelines.yml` exists in the root of the connected app repository:

    azure-pipelines.yml

The pipeline template under the lab folder is not enough by itself.

Azure DevOps uses the pipeline file from the connected repository.

### Docker build uses old Dockerfile

If Azure DevOps still runs old Dockerfile commands, your connected repository may be outdated.

Fix:

- Push the latest code to the connected repository
- Confirm the Azure DevOps pipeline is connected to the correct repository and branch
- If using Azure Repos as a copy of a GitHub repository, update the Azure Repos copy

### Docker login or image push failed

If Docker login or image push fails, verify the Azure DevOps pipeline variables:

    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Check that the service principal has permission to push to ACR.

For a learning setup, the service principal usually needs `AcrPush` on the registry.

### Azure login failed

If Azure login fails, verify these Azure DevOps pipeline variables:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID

Also verify that the service principal secret has not expired.

### AKS credentials failed

If `az aks get-credentials` fails in the pipeline, verify:

    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME

Also verify that the service principal has permission to read AKS cluster details.

### kubectl command not found

The Azure CLI image may not include kubectl.

This pipeline uses:

    az aks install-cli

before running kubectl commands.

### ImagePullBackOff with platform mismatch

If a pod shows:

    no match for platform in manifest

Make sure the pipeline builds images for:

    linux/amd64

Then run the pipeline again.

### ACR pull permission issue

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

### Backend readiness probe fails

The backend health endpoint checks MySQL connectivity.

If MySQL is not ready yet, the backend may not become ready immediately.

Check:

    kubectl get pods -n practitioner-azure-devops
    kubectl logs deployment/mysql -n practitioner-azure-devops
    kubectl logs deployment/node-backend -n practitioner-azure-devops

### Rollout timeout

If rollout times out, inspect pods and events:

    kubectl get pods -n practitioner-azure-devops -o wide
    kubectl describe pod -n practitioner-azure-devops -l app=node-backend
    kubectl describe pod -n practitioner-azure-devops -l app=node-frontend
    kubectl get events -n practitioner-azure-devops --sort-by=.lastTimestamp | tail -30

## Cleanup

Delete AKS resources:

    kubectl delete namespace practitioner-azure-devops --ignore-not-found

This removes MySQL, backend, frontend, services, ConfigMaps, Secrets, and PVC resources created by this lab.

Delete the ACR repositories created by this lab:

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository node-backend \
      --yes

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository node-frontend \
      --yes

If the files were copied only for this lab, remove them from your app repository clone:

    cd "$APP_REPO_DIR"

    rm -rf k8s azure-pipelines.yml
    rm -f backend/Dockerfile
    rm -f frontend/Dockerfile
    rm -f frontend/nginx.conf

Commit and push the cleanup change to your own app repository if you no longer want the pipeline to remain active:

    git add -A backend/Dockerfile frontend/Dockerfile frontend/nginx.conf k8s azure-pipelines.yml
    git commit -m "Remove Azure DevOps AKS deployment lab files"
    git push

Do not delete the lab templates under:

    labs/practitioner/05-azure-devops-to-aks/

## Security cleanup

After testing, remove or rotate temporary service principal secrets used in Azure DevOps pipeline variables.

Do not commit secrets into Git.

Do not store long-lived credentials in local notes or screenshots.

For production, prefer:

- Least privilege permissions
- Short-lived credentials
- Secret rotation
- OIDC or federated credentials where possible
- Pipeline variable groups with restricted access
- Protected branches
- Environment approvals

## Important note

This is a learning lab.

It uses Azure service principal secret authentication because it is easier for beginners to understand.

For production-style Azure DevOps pipelines, prefer least privilege identity, protected variables, protected branches, environment approvals, and short-lived credentials.
