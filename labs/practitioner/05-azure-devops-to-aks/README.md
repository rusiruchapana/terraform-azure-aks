# Practitioner Lab 05 - Azure DevOps to AKS

This lab shows how to use Azure DevOps Pipelines to build backend and frontend application images, push them to Azure Container Registry, and deploy a 3-tier application to AKS.

This lab uses the 3-tier Node.js sample app as a more realistic application example.

Sample app repository:

    https://github.com/andrewferdinandus/3-tier-nodeapp

## What you will learn

- Azure DevOps pipeline stages
- Building a Node.js backend Docker image
- Pushing an image to ACR
- Deploying MySQL to AKS
- Deploying a backend API to AKS
- Using Kubernetes Secrets, ConfigMaps, PVCs, Deployments, and Services
- Verifying rollout from Azure DevOps
- Testing backend health from your local machine

## Lab scope

This lab deploys a full 3-tier application:

- MySQL database
- Node.js backend API
- React frontend served by NGINX

The frontend uses an NGINX reverse proxy so browser requests to `/api` and `/health` are routed to the backend service inside the cluster.

## App source

The app source lives in a separate repository:

    3-tier-nodeapp

This platform repository stores the lab template and reference files only.

## Required Azure DevOps setup

Create or use an Azure DevOps project.

Recommended project name:

    aks-azure-devops-cicd-lab

You can use either:

- Azure Repos Git
- GitHub connected to Azure Pipelines

If you use Azure Repos as a copy of a GitHub repo, make sure the Azure Repos copy is updated when GitHub changes.

## Prepare Azure CI/CD variables

This lab deploys to AKS and pushes images to a registry.

Before running the pipeline, prepare the required Azure and registry values using the shared guide:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

## Required pipeline variables

Add these variables in Azure DevOps:

    Pipelines -> select pipeline -> Edit -> Variables

Variables:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

For this platform example:

    AZURE_RESOURCE_GROUP = rg-aks-dev-001
    AKS_CLUSTER_NAME = aks-dev-001
    REGISTRY_LOGIN_SERVER = acraksdev001andrew.azurecr.io

For ACR using the same service principal:

    REGISTRY_USERNAME = AZURE_CLIENT_ID
    REGISTRY_PASSWORD = AZURE_CLIENT_SECRET

Mark these as secret:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

## Required permissions

The service principal should have:

- Permission to get AKS credentials
- AcrPush permission on ACR

For learning, Contributor on the resource group or subscription can be used.

For production, use least privilege.

## Files in this lab

    backend/Dockerfile
      Dockerfile used to build the backend image

    frontend/Dockerfile
      Dockerfile used to build the React frontend image

    frontend/nginx.conf
      NGINX reverse proxy configuration for frontend-to-backend traffic

    k8s/
      Kubernetes manifests for MySQL, backend, and frontend

    azure-pipelines/azure-pipelines.yml
      Azure DevOps pipeline template

## Files to copy into the app repository

Copy these into the root of the 3-tier app repository:

    backend/Dockerfile
    frontend/Dockerfile
    frontend/nginx.conf
    k8s/
    azure-pipelines.yml

Also update the frontend app to use relative backend paths:

    const BACKEND_URL = '/api';
    fetch('/health');

The app repository should have:

    backend/
      Dockerfile
      package.json
      package-lock.json
      server.js

    k8s/
      namespace.yaml
      mysql-secret.yaml
      mysql-init-configmap.yaml
      mysql-pvc.yaml
      mysql-deployment.yaml
      mysql-service.yaml
      backend-deployment.yaml
      backend-service.yaml
      frontend-deployment.yaml
      frontend-service.yaml

    azure-pipelines.yml

## Pipeline stages

The pipeline uses these stages:

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

## How it works

The pipeline:

1. Validates required files
2. Builds the backend Docker image
3. Builds the frontend Docker image
4. Pushes both images to ACR
5. Logs in to Azure
6. Gets AKS credentials
7. Installs kubectl
8. Deploys MySQL resources
9. Deploys backend resources
10. Deploys frontend resources
11. Verifies rollouts

## Local validation

Before running the pipeline, you can test the backend Docker build locally from the app repository:

    docker build -t node-backend-test backend

Run the container locally:

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

## Verify after pipeline success

From your local machine:

    kubectl get pods -n practitioner-azure-devops
    kubectl get svc -n practitioner-azure-devops
    kubectl rollout status deployment/mysql -n practitioner-azure-devops
    kubectl rollout status deployment/node-backend -n practitioner-azure-devops
    kubectl rollout status deployment/node-frontend -n practitioner-azure-devops

Port-forward frontend service:

    kubectl port-forward svc/node-frontend -n practitioner-azure-devops 8087:80

Test health through the frontend proxy:

    curl http://localhost:8087/health

Test tasks API through the frontend proxy:

    curl http://localhost:8087/api/tasks

Expected:

    {"status":"UP","database":"CONNECTED"}

## Common issues

### Docker build uses old Dockerfile

If Azure DevOps still runs:

    npm ci --omit=dev

but your GitHub repo has:

    npm install --omit=dev

then Azure DevOps may be building an outdated Azure Repos copy.

Fix:

- Push the latest code to Azure Repos
- Or connect the pipeline directly to GitHub

### kubectl command not found

The Azure CLI image may not include kubectl.

This pipeline uses:

    az aks install-cli

before running kubectl commands.

### Backend readiness probe fails

The backend health endpoint checks MySQL connectivity.

If MySQL is not ready yet, the backend may not become ready immediately.

Check:

    kubectl get pods -n practitioner-azure-devops
    kubectl logs deployment/mysql -n practitioner-azure-devops
    kubectl logs deployment/node-backend -n practitioner-azure-devops

## Cleanup

Delete the namespace:

    kubectl delete namespace practitioner-azure-devops

Optional ACR cleanup:

    az acr repository delete \
      --name <acr-name> \
      --repository node-backend \
      --yes

    az acr repository delete \
      --name <acr-name> \
      --repository node-frontend \
      --yes

## Security cleanup

After testing, remove or rotate temporary service principal secrets used in Azure DevOps.

Do not commit secrets into Git.

## Important note

This is a learning lab.

Production pipelines should use:

- Service connections
- OIDC or federated credentials where possible
- Least privilege permissions
- Environment approvals
- Secret rotation
- DevSecOps scanning
- GitOps or controlled deployment promotion
