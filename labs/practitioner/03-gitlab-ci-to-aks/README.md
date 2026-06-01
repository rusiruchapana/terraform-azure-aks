# Practitioner Lab 03 - GitLab CI/CD to AKS

This lab shows how to use GitLab CI/CD to build a small web application image, publish the image to Azure Container Registry, deploy it to AKS, and verify that the deployed application responds through a Kubernetes Service.

This is a standalone deployment lab.

The lab uses:

- A GitLab project where you can run CI/CD pipelines
- A GitLab CI/CD pipeline template
- Azure Container Registry
- AKS deployment
- GitLab CI/CD variables for Azure and registry access
- `kubectl port-forward` to test the deployed app locally

## Lab goal

By the end of this lab, you should have:

- A GitLab pipeline using `.gitlab-ci.yml`
- A container image pushed to Azure Container Registry
- A Kubernetes namespace named `practitioner-gitlab-ci`
- A deployment named `gitlab-ci-demo`
- A service named `gitlab-ci-demo`
- A working web page tested through `kubectl port-forward`

This lab does not expose the application publicly.

The final application test uses a temporary local tunnel from your laptop to the Kubernetes Service inside AKS:

    http://localhost:8085

Expected page text:

    GitLab CI/CD to AKS Lab
    This app was built and deployed by GitLab CI/CD.

## What you will learn

You will learn:

- How to prepare a GitLab CI/CD pipeline for AKS deployment
- How to configure GitLab CI/CD variables
- How to build a container image in GitLab CI/CD
- How to publish a container image to Azure Container Registry
- How to verify that the pushed image exists in ACR
- How to authenticate to Azure from GitLab CI/CD
- How to get AKS credentials in a pipeline
- How to deploy Kubernetes manifests from GitLab CI/CD
- How to verify Kubernetes rollout
- How to test the deployed app using `kubectl port-forward`
- How to clean up AKS, ACR, and copied GitLab project resources

## Lab architecture

The flow is:

    GitLab project
      |
      v
    GitLab CI/CD pipeline
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

The GitLab pipeline uses these stages:

    validate
      |
      v
    build_push
      |
      v
    deploy
      |
      v
    verify

## What this lab requires

You need:

- A GitLab account
- A GitLab project where you can add `.gitlab-ci.yml` and run pipelines
- Git
- Azure CLI
- kubectl
- A terminal
- A web browser
- An AKS cluster
- Azure Container Registry
- A service principal for CI/CD credentials

This lab builds the image on a GitLab runner.

You do not need Docker Desktop on your local machine for the GitLab pipeline.

## GitLab project requirement

GitLab CI/CD pipelines are detected from this file in the GitLab project root:

    .gitlab-ci.yml

For this lab, use a GitLab project that you own or maintain.

Do not push lab pipeline changes to a project you do not own or maintain.

The pipeline template stays in the lab folder:

    labs/practitioner/03-gitlab-ci-to-aks/gitlab-ci/.gitlab-ci.yml

During the lab, you copy that template to the root of your GitLab project as:

    .gitlab-ci.yml

After the lab, remove the copied pipeline file from your GitLab project if you do not want it to keep running on future pushes.

Do not delete the pipeline template under the lab folder.

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

Before running the pipeline, prepare the required Azure and registry values using the shared guide:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

You will need these values for GitLab CI/CD variables:

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

## Configure GitLab CI/CD variables

In your GitLab project, go to:

    Settings
    CI/CD
    Variables
    Add variable

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

For secret values, use:

    Masked: yes

For this learning lab, use:

    Protected: no

Use protected variables only when your branch is protected.

The variable names must exactly match the pipeline.

Do not commit secrets into Git.

## Files in this lab

This lab includes:

    app/
      Static NGINX app files

    k8s/
      Kubernetes manifests

    gitlab-ci/
      GitLab CI/CD pipeline template

Files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    gitlab-ci/.gitlab-ci.yml

## Copy files into your GitLab project

Run these commands from the `terraform-azure-aks` repository root.

Set a local path to your GitLab project clone:

    GITLAB_PROJECT_DIR="<path-to-your-gitlab-project>"

Example:

    GITLAB_PROJECT_DIR="$HOME/terraform-azure-aks-labs/aks-gitlab-cicd-lab"

Create folders in your GitLab project:

    mkdir -p "$GITLAB_PROJECT_DIR/app"
    mkdir -p "$GITLAB_PROJECT_DIR/k8s"

Copy the lab files:

    cp labs/practitioner/03-gitlab-ci-to-aks/app/* "$GITLAB_PROJECT_DIR/app/"
    cp labs/practitioner/03-gitlab-ci-to-aks/k8s/* "$GITLAB_PROJECT_DIR/k8s/"
    cp labs/practitioner/03-gitlab-ci-to-aks/gitlab-ci/.gitlab-ci.yml "$GITLAB_PROJECT_DIR/.gitlab-ci.yml"

Verify the GitLab project structure:

    find "$GITLAB_PROJECT_DIR" -maxdepth 3 -type f | sort

Expected files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    .gitlab-ci.yml

## Commit the pipeline to your own GitLab project

GitLab CI/CD can only run pipelines that are committed to a GitLab project.

Move into your GitLab project clone:

    cd "$GITLAB_PROJECT_DIR"

Commit the copied app, manifests, and pipeline file:

    git add app k8s .gitlab-ci.yml
    git commit -m "Add GitLab CI/CD AKS deployment lab"
    git push

Only push to a GitLab project that you own or maintain.

Do not push these lab pipeline changes to someone else's project.

## Run the pipeline

Open your GitLab project in a browser.

Go to:

    Build
    Pipelines

The pipeline can run when you push to the project.

If you want to run it manually, use:

    Run pipeline

The pipeline should run these stages:

    validate
    build_push
    deploy
    verify

## Verify the GitLab pipeline run

Open the pipeline and check that each stage succeeded:

    validate
    build_push
    deploy
    verify

The `build_push` stage should log in to the registry, build the image, and push it.

The `deploy` stage should apply the namespace, deployment, and service.

The `verify` stage should show pods and services in the target namespace.

## Image tag

The pipeline builds the image and tags it with the GitLab commit SHA.

Example:

    myacr.azurecr.io/gitlab-ci-demo:<commit-sha>

To see the local commit SHA in your GitLab project clone:

    git rev-parse HEAD

The pipeline uses the GitLab CI commit SHA from the pipeline run:

    $CI_COMMIT_SHA

## Image platform note

The pipeline builds the image for `linux/amd64`:

    docker build --platform linux/amd64 -t "$REGISTRY_LOGIN_SERVER/$IMAGE_NAME:$CI_COMMIT_SHA" app

This is useful because most AKS node pools use amd64 nodes.

It also avoids image platform mismatch when a runner uses ARM hardware.

## Verify image in Azure Container Registry

After the pipeline succeeds, verify that GitLab pushed the image to ACR.

List repositories:

    az acr repository list \
      --name "$ACR_NAME" \
      --output table

Expected repository:

    gitlab-ci-demo

List image tags:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository gitlab-ci-demo \
      --output table

Expected:

    A tag matching the GitLab commit SHA should be listed.

## Verify deployment in AKS

After the pipeline succeeds, verify the Kubernetes resources:

    kubectl get ns practitioner-gitlab-ci
    kubectl get deployment gitlab-ci-demo -n practitioner-gitlab-ci
    kubectl get pods -n practitioner-gitlab-ci -o wide
    kubectl get svc gitlab-ci-demo -n practitioner-gitlab-ci

Expected:

    namespace exists
    deployment shows available replicas
    pod status is Running
    service exists

Check rollout:

    kubectl rollout status deployment/gitlab-ci-demo -n practitioner-gitlab-ci --timeout=180s

## Test the application with port-forward

This lab does not create a public Azure URL.

The Kubernetes Service is tested through `kubectl port-forward`.

Port-forward creates a temporary local connection from your laptop to the service running inside AKS.

Port-forward the service:

    kubectl port-forward svc/gitlab-ci-demo -n practitioner-gitlab-ci 8085:80

Open from your laptop:

    http://localhost:8085

Or test with curl from another terminal:

    curl http://localhost:8085

Expected page text:

    GitLab CI/CD to AKS Lab
    This app was built and deployed by GitLab CI/CD.

Stop the port-forward with `Ctrl+C`.

## Troubleshooting

### Pipeline does not start

Verify `.gitlab-ci.yml` exists in the root of your GitLab project:

    .gitlab-ci.yml

The pipeline template under the lab folder is not enough by itself.

GitLab detects pipelines from `.gitlab-ci.yml` in the project root.

### Required file validation failed

If the `validate` stage fails, verify these files exist in your GitLab project:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml

### Docker login or image push failed

If Docker login or image push fails, verify the GitLab CI/CD variables:

    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Check that the service principal has permission to push to ACR.

For a learning setup, the service principal usually needs `AcrPush` on the registry.

### Azure login failed

If Azure login fails, verify these GitLab CI/CD variables:

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

### ImagePullBackOff with platform mismatch

If the pod shows:

    no match for platform in manifest

Make sure the pipeline builds the image using:

    --platform linux/amd64

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

### Rollout timeout

If rollout times out, inspect pods and events:

    kubectl get pods -n practitioner-gitlab-ci -o wide
    kubectl describe pod -n practitioner-gitlab-ci -l app=gitlab-ci-demo
    kubectl get events -n practitioner-gitlab-ci --sort-by=.lastTimestamp | tail -30

## Cleanup

Delete AKS resources:

    kubectl delete namespace practitioner-gitlab-ci --ignore-not-found

Delete the ACR repository created by this lab:

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository gitlab-ci-demo \
      --yes

If the files were copied only for this lab, remove them from your GitLab project clone:

    cd "$GITLAB_PROJECT_DIR"

    rm -rf app k8s .gitlab-ci.yml

Commit and push the cleanup change to your own GitLab project if you no longer want the pipeline to remain active:

    git add -A app k8s .gitlab-ci.yml
    git commit -m "Remove GitLab CI/CD AKS deployment lab files"
    git push

Do not delete the lab templates under:

    labs/practitioner/03-gitlab-ci-to-aks/

## Security cleanup

After testing, remove or rotate temporary service principal secrets used in GitLab CI/CD variables.

Do not commit secrets into Git.

Do not store long-lived credentials in local notes or screenshots.

For production, prefer:

- Least privilege permissions
- Short-lived credentials
- Secret rotation
- OIDC or federated credentials where possible
- Protected variables
- Protected branches
- Environment approvals

## Important note

This is a learning lab.

It uses Azure service principal secret authentication because it is easier for beginners to understand.

For production-style GitLab CI/CD workflows, prefer least privilege identity, protected variables, protected branches, environment approvals, and short-lived credentials.
