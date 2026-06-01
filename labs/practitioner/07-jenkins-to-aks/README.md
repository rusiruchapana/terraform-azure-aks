# Practitioner Lab 07 - Jenkins to AKS

This lab shows how to use Jenkins to build a small web application image, publish the image to Azure Container Registry, deploy it to AKS, and verify that the deployed application responds through a Kubernetes Service.

This is a standalone deployment lab.

You can run this lab from a clean local setup.

The lab uses:

- Jenkins running locally in Docker
- A local test repository
- Docker image build
- Azure Container Registry
- AKS deployment
- Jenkins credentials for Azure and registry access

## Lab goal

By the end of this lab, you should have:

- A Jenkins pipeline job named `jenkins-aks-cicd-lab`
- A container image pushed to Azure Container Registry
- A Kubernetes namespace named `practitioner-jenkins`
- A deployment named `jenkins-demo`
- A service named `jenkins-demo`
- A working web page tested through `kubectl port-forward`

This lab does not expose the application publicly.

The final application test uses a temporary local tunnel from your laptop to the Kubernetes Service inside AKS:

    http://localhost:8089

Expected page text:

    Jenkins to AKS Lab
    This app was built and deployed by Jenkins.

## What you will learn

You will learn:

- How to run a standalone Jenkins deployment lab locally
- How to build a custom Jenkins image with Docker, Azure CLI, kubectl, and required Jenkins plugins
- How to prepare a local Jenkins pipeline repository
- How to configure Jenkins credentials for Azure and ACR
- How to use a Jenkinsfile with Pipeline script from SCM
- How to build a container image in Jenkins
- How to publish a container image to Azure Container Registry
- How to verify that the pushed image exists in ACR
- How to deploy an application to AKS from Jenkins
- How to verify Kubernetes rollout
- How to test the deployed app using `kubectl port-forward`
- How to clean up Jenkins, AKS, and ACR lab resources

## Lab architecture

The flow is:

    Local test repository
      |
      v
    Jenkins running in Docker
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

The Jenkins pipeline uses these stages:

    Validate
      |
      v
    Build and Push
      |
      v
    Deploy
      |
      v
    Verify

## What this lab requires

You need:

- Docker Desktop
- Git
- Azure CLI
- kubectl
- A terminal
- A web browser
- An AKS cluster
- Azure Container Registry
- A service principal for CI/CD credentials

This lab runs Jenkins inside Docker. You do not need to install Jenkins directly on your machine.

## Install required local tools

### Docker Desktop

Install Docker Desktop for your operating system:

    https://www.docker.com/products/docker-desktop/

After installing Docker Desktop, start it and verify Docker from your terminal:

    docker version

Expected:

    Docker should show both Client and Server sections.

If the Server section is missing, Docker Desktop is not running.

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

    docker version
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

Before running the Jenkins pipeline, prepare the required Azure and registry values using the shared guide:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

You will need these values for Jenkins credentials:

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

## Files in this lab

This lab includes:

    app/
      Static NGINX app files

    k8s/
      Kubernetes manifests

    jenkins/
      Jenkinsfile pipeline template

Files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    jenkins/Jenkinsfile

## Create the Jenkins test app repository

Run the first commands from the `terraform-azure-aks` repository root.

The local test repository is created outside the platform repository under:

    $HOME/terraform-azure-aks-labs

Set paths:

    LAB_WORKDIR="$HOME/terraform-azure-aks-labs"
    PLATFORM_REPO="$(pwd)"
    APP_REPO="$LAB_WORKDIR/jenkins-aks-cicd-lab"

Create the local test repository:

    mkdir -p "$LAB_WORKDIR"
    rm -rf "$APP_REPO"
    mkdir -p "$APP_REPO"
    cd "$APP_REPO"

    mkdir -p app k8s

After `cd "$APP_REPO"`, the remaining local repository, Jenkins image build, and Jenkins run commands are executed from:

    $HOME/terraform-azure-aks-labs/jenkins-aks-cicd-lab

Copy the lab files:

    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/app/"* app/
    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/k8s/"* k8s/
    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/jenkins/Jenkinsfile" Jenkinsfile

Verify files before initializing Git:

    find . -maxdepth 3 -type f | sort

Expected files:

    ./Jenkinsfile
    ./app/Dockerfile
    ./app/index.html
    ./k8s/deployment.yaml
    ./k8s/namespace.yaml
    ./k8s/service.yaml

Initialize a local Git repository for Jenkins SCM:

    git init
    git add .
    git commit -m "Add Jenkins AKS lab app"
    git branch -M main

This repository is local only. Jenkins reads it through the mounted workspace path.

Do not push this test repository to GitHub.

Verify the local Git repository:

    git status

Expected:

    On branch main
    nothing to commit, working tree clean

## Create the custom Jenkins image

This lab builds its own Jenkins image.

Create `plugins.txt` in the local test repository:

    cat > plugins.txt <<'EOF_PLUGINS'
    workflow-aggregator
    git
    credentials-binding
    pipeline-stage-view
    EOF_PLUGINS

These plugins provide the Jenkins Pipeline, Git SCM, and credentials functionality required for this lab.

Create `Dockerfile.jenkins` in the local test repository:

    cat > Dockerfile.jenkins <<'EOF_DOCKERFILE'
    FROM jenkins/jenkins:lts-jdk17

    USER root

    RUN apt-get update && \
        apt-get install -y \
          ca-certificates \
          curl \
          gnupg \
          lsb-release \
          apt-transport-https \
          docker.io && \
        rm -rf /var/lib/apt/lists/*

    RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

    RUN ARCH="$(dpkg --print-architecture)" && \
        case "$ARCH" in \
          amd64) KUBECTL_ARCH="amd64" ;; \
          arm64) KUBECTL_ARCH="arm64" ;; \
          *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
        esac && \
        curl -LO "https://dl.k8s.io/release/v1.34.0/bin/linux/${KUBECTL_ARCH}/kubectl" && \
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
        rm kubectl

    RUN usermod -aG docker jenkins

    USER jenkins

    COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
    RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
    EOF_DOCKERFILE

Build the Jenkins image:

    docker build -t jenkins-aks-lab:local -f Dockerfile.jenkins .

Expected result:

    naming to docker.io/library/jenkins-aks-lab:local

## Run Jenkins locally

Remove any previous container or volume with the same lab names:

    docker rm -f jenkins-aks-lab 2>/dev/null || true
    docker volume rm jenkins_home_aks_lab 2>/dev/null || true

Create a Jenkins volume:

    docker volume create jenkins_home_aks_lab

Run Jenkins:

    docker run -d \
      --name jenkins-aks-lab \
      --user root \
      -p 8088:8080 \
      -p 50000:50000 \
      -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true" \
      -v jenkins_home_aks_lab:/var/jenkins_home \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$APP_REPO:/workspace/jenkins-aks-cicd-lab" \
      jenkins-aks-lab:local

This lab runs Jenkins as root only for local learning so it can access the Docker socket.

Verify the container is running:

    docker ps | grep jenkins-aks-lab

Get the initial admin password:

    docker exec jenkins-aks-lab cat /var/jenkins_home/secrets/initialAdminPassword

Open Jenkins:

    http://localhost:8088

## Jenkins setup wizard guidance

The required Jenkins plugins are already installed in the custom Jenkins image.

If Jenkins asks about plugin installation, do not depend on the suggested plugins for this lab.

You can skip suggested plugin installation if Jenkins gives that option.

If you choose to install suggested plugins and some optional plugins fail, do not stop immediately.

Examples of optional suggested plugins that are not required for this lab include:

- Workspace Cleanup
- Gradle
- GitHub Branch Source
- Pipeline: GitHub Groovy Libraries
- Pipeline Graph View
- Email Extension

Continue to the Jenkins dashboard and check whether you can create a Pipeline job.

If the Pipeline job type, Git SCM option, and credentials UI are available, continue the lab.

If the Pipeline job type or Git SCM option is missing, recreate Jenkins with the custom image and a fresh volume.

## Verify tools inside Jenkins

Open a shell inside the Jenkins container:

    docker exec -it jenkins-aks-lab bash

Check tools:

    whoami
    docker version
    az version
    kubectl version --client

Expected:

    whoami should show root
    docker version should work
    az version should work
    kubectl version --client should work

Exit:

    exit

## Add Jenkins credentials

In Jenkins, go to:

    Manage Jenkins
    Credentials
    System
    Global credentials
    Add Credentials

For each value, use:

    Kind: Secret text
    Scope: Global
    ID: exact ID shown below
    Description: same as ID

Add these credential IDs:

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

The credential IDs must exactly match the Jenkinsfile.

Do not paste secrets into the Jenkinsfile.

Do not commit secrets into Git.

## Create the Jenkins pipeline job

In Jenkins:

    New Item
    jenkins-aks-cicd-lab
    Pipeline
    OK

Pipeline configuration:

    Definition: Pipeline script from SCM
    SCM: Git
    Repository URL: file:///workspace/jenkins-aks-cicd-lab
    Branch Specifier: */main
    Script Path: Jenkinsfile

Save the job.

## Run the pipeline

Click:

    Build Now

The pipeline should complete these stages:

    Validate
    Build and Push
    Deploy
    Verify

The pipeline should:

1. Validate required files
2. Log in to Azure Container Registry
3. Build the Docker image
4. Push the image to ACR
5. Log in to Azure
6. Get AKS credentials
7. Apply Kubernetes manifests
8. Verify rollout

The image is tagged using the Jenkins build number:

    <registry-login-server>/jenkins-demo:<build-number>

The Jenkinsfile builds the image for `linux/amd64`:

    docker build \
      --platform linux/amd64 \
      -t "$REGISTRY_LOGIN_SERVER/$IMAGE_NAME:$BUILD_NUMBER" \
      app

This is important when Jenkins runs on Apple Silicon but AKS nodes are amd64.

## Verify image in Azure Container Registry

After the pipeline succeeds, verify that Jenkins pushed the image to ACR.

List repositories:

    az acr repository list \
      --name "$ACR_NAME" \
      --output table

Expected repository:

    jenkins-demo

List image tags:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository jenkins-demo \
      --output table

Expected:

    A tag matching the Jenkins build number should be listed.

## Verify deployment in AKS

After the pipeline succeeds, verify the Kubernetes resources:

    kubectl get ns practitioner-jenkins
    kubectl get deployment jenkins-demo -n practitioner-jenkins
    kubectl get pods -n practitioner-jenkins -o wide
    kubectl get svc jenkins-demo -n practitioner-jenkins

Expected:

    namespace exists
    deployment shows available replicas
    pod status is Running
    service exists

Check rollout:

    kubectl rollout status deployment/jenkins-demo -n practitioner-jenkins --timeout=180s

## Test the application with port-forward

This lab does not create a public Azure URL.

The Kubernetes Service is tested through `kubectl port-forward`.

Port-forward creates a temporary local connection from your laptop to the service running inside AKS.

Port-forward the service:

    kubectl port-forward svc/jenkins-demo -n practitioner-jenkins 8089:80

Open from your laptop:

    http://localhost:8089

Or test with curl from another terminal:

    curl http://localhost:8089

Expected page text:

    Jenkins to AKS Lab
    This app was built and deployed by Jenkins.

Stop the port-forward with `Ctrl+C`.

## Troubleshooting

### Suggested plugin installation failures

If Jenkins reports failures for suggested plugins such as Workspace Cleanup, Gradle, GitHub Branch Source, Pipeline Graph View, or Email Extension, do not stop the lab immediately.

This lab uses a custom Jenkins image with the required plugins already installed.

Continue to the Jenkins dashboard and create the Pipeline job.

If the Pipeline job type or Git SCM option is missing, recreate Jenkins with a fresh volume using the custom image.

### Jenkins dashboard does not open

Check the container:

    docker ps | grep jenkins-aks-lab

Check logs:

    docker logs jenkins-aks-lab --tail=100

Make sure the port mapping uses:

    8088:8080

Then open:

    http://localhost:8088

### Docker socket permission denied

If Jenkins cannot access Docker:

    permission denied while trying to connect to the Docker daemon socket

Make sure Jenkins was started with:

    --user root

And with:

    -v /var/run/docker.sock:/var/run/docker.sock

This is only for the local learning lab.

### Local Git checkout blocked

If Jenkins blocks `file://` Git checkout:

    Checkout of Git remote file:///workspace/jenkins-aks-cicd-lab aborted

Make sure Jenkins was started with:

    -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"

### Azure login failed

If Azure login fails in the pipeline, verify the Jenkins credentials:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID

Also verify that the service principal secret has not expired.

### ACR login or push failed

If Docker login or image push fails, verify:

    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Check that the service principal has permission to push to ACR.

For a learning setup, the service principal usually needs `AcrPush` on the registry.

### AKS credentials failed

If `az aks get-credentials` fails, verify:

    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME

Also verify that the service principal has permission to read AKS cluster details.

### ImagePullBackOff with platform mismatch

If the pod shows:

    no match for platform in manifest

Make sure the Jenkinsfile builds the image using:

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

    kubectl get pods -n practitioner-jenkins -o wide
    kubectl describe pod -n practitioner-jenkins -l app=jenkins-demo
    kubectl get events -n practitioner-jenkins --sort-by=.lastTimestamp | tail -30

## Cleanup

Delete AKS resources:

    kubectl delete namespace practitioner-jenkins --ignore-not-found

Delete the ACR repository created by this lab:

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository jenkins-demo \
      --yes

Stop and remove Jenkins:

    docker rm -f jenkins-aks-lab

Remove the Jenkins volume:

    docker volume rm jenkins_home_aks_lab

Remove the custom Jenkins image:

    docker rmi jenkins-aks-lab:local

Optional local repository cleanup:

    rm -rf "$APP_REPO"

Optional Docker cleanup:

    docker image prune -f
    docker builder prune -f

## Security cleanup

After testing, remove or rotate temporary service principal secrets used in Jenkins.

Do not commit secrets into Git.

Do not store long-lived credentials in local notes or screenshots.

For production, prefer:

- Dedicated Jenkins agents
- Least privilege permissions
- Short-lived credentials
- Secret rotation
- OIDC or federated credentials where possible
- External secret managers
- Jenkins credentials with restricted access

## Important note

This is a learning lab.

Running Jenkins as root and mounting the Docker socket is acceptable for a local lab, but it is not recommended for production.

Production Jenkins setups should use dedicated build agents, hardened worker nodes, least privilege access, and stronger credential isolation.
