# Practitioner Lab 07 - Jenkins to AKS

This lab shows how to use Jenkins to build a container image, push it to Azure Container Registry, and deploy the application to AKS.

The lab uses a simple static NGINX app so the focus stays on Jenkins, Docker, ACR, and AKS deployment flow.

## What you will learn

You will learn:

- How to run Jenkins locally with Docker
- How to prepare a Jenkins pipeline repository
- How to build a custom Jenkins image with Docker, Azure CLI, and kubectl
- How to add Jenkins credentials
- How to use a Jenkinsfile
- How to build and push a container image to ACR
- How to deploy to AKS from Jenkins
- How to verify rollout and test the app locally

## Lab architecture

The flow is:

    Jenkins
      |
      v
    Docker build
      |
      v
    Azure Container Registry
      |
      v
    AKS Deployment
      |
      v
    Kubernetes Service

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
- Azure CLI
- kubectl
- AKS cluster
- Azure Container Registry
- Jenkins running locally in Docker
- A service principal for CI/CD credentials

Check local tools:

    docker version
    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl get nodes
    az acr show --name <acr-name> --query loginServer -o tsv

## Prepare Azure CI/CD variables

This lab deploys to AKS and pushes an image to a registry.

Before running the Jenkins pipeline, prepare the required Azure and registry values using the shared guide:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

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

Create a separate local test repository:

    LAB_WORKDIR="$HOME/terraform-azure-aks-labs"
    PLATFORM_REPO="$(pwd)"
    APP_REPO="$LAB_WORKDIR/jenkins-aks-cicd-lab"

    mkdir -p "$LAB_WORKDIR"
    rm -rf "$APP_REPO"
    mkdir -p "$APP_REPO"
    cd "$APP_REPO"

    mkdir -p app k8s

Copy the lab files:

    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/app/"* app/
    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/k8s/"* k8s/
    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/jenkins/Jenkinsfile" Jenkinsfile

Initialize a local Git repository for Jenkins SCM:

    git init
    git add .
    git commit -m "Add Jenkins AKS lab app"
    git branch -M main

This repository is local only. Jenkins reads it through the mounted workspace path.
Do not push this test repository to GitHub.

Verify files:

    find . -maxdepth 3 -type f | sort

Expected files:

    ./Jenkinsfile
    ./app/Dockerfile
    ./app/index.html
    ./k8s/deployment.yaml
    ./k8s/namespace.yaml
    ./k8s/service.yaml

## Create the custom Jenkins image

The Jenkins container needs Docker, Azure CLI, kubectl, and required Jenkins plugins.

Create `plugins.txt` in the test repository:

    cat > plugins.txt <<'EOF'
    workflow-aggregator
    git
    credentials-binding
    pipeline-stage-view
    EOF

Create `Dockerfile.jenkins`:

    cat > Dockerfile.jenkins <<'EOF'
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

    RUN curl -LO "https://dl.k8s.io/release/v1.34.0/bin/linux/arm64/kubectl" && \
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
        rm kubectl

    RUN usermod -aG docker jenkins

    USER jenkins

    COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
    RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
    EOF

Build the Jenkins image:

    docker build -t jenkins-aks-lab:local -f Dockerfile.jenkins .

## Run Jenkins locally

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

This lab runs Jenkins as root only for learning so it can access the Docker socket.

Get the initial admin password:

    docker exec jenkins-aks-lab cat /var/jenkins_home/secrets/initialAdminPassword

Open Jenkins:

    http://localhost:8088

Install suggested plugins, or continue if the required plugins are already installed from the custom image.

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

The pipeline should:

1. Validate required files
2. Build the Docker image
3. Push the image to ACR
4. Log in to Azure
5. Get AKS credentials
6. Apply Kubernetes manifests
7. Verify rollout

The image is tagged using the Jenkins build number:

    <registry-login-server>/jenkins-demo:<build-number>

The Jenkinsfile builds the image for `linux/amd64`:

    docker build \
      --platform linux/amd64 \
      -t "$REGISTRY_LOGIN_SERVER/$IMAGE_NAME:$BUILD_NUMBER" \
      app

This is important when Jenkins runs on Apple Silicon but AKS nodes are amd64.

## Verify deployment

After the pipeline succeeds, verify from your local machine:

    kubectl rollout status deployment/jenkins-demo -n practitioner-jenkins --timeout=180s
    kubectl get pods -n practitioner-jenkins -o wide
    kubectl get svc -n practitioner-jenkins

Port-forward the service:

    kubectl port-forward svc/jenkins-demo -n practitioner-jenkins 8089:80

Open:

    http://localhost:8089

Expected page:

    Jenkins to AKS Lab
    This app was built and deployed by Jenkins.

## Troubleshooting

### Jenkins plugin download timeout

If plugin installation fails with a timeout, build the custom Jenkins image with `plugins.txt`.

This preinstalls required plugins:

    workflow-aggregator
    git
    credentials-binding
    pipeline-stage-view

### Docker socket permission denied

If Jenkins cannot access Docker:

    permission denied while trying to connect to the Docker daemon socket

Run the Jenkins container with:

    --user root

This is used only for this local learning lab.

### Local Git checkout blocked

If Jenkins blocks `file://` Git checkout:

    Checkout of Git remote file:///workspace/jenkins-aks-cicd-lab aborted

Run Jenkins with:

    -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"

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
      --acr <acr-login-server>

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

Delete the ACR repository:

    az acr repository delete \
      --name <acr-name> \
      --repository jenkins-demo \
      --yes

Stop and remove Jenkins:

    docker rm -f jenkins-aks-lab

Remove the Jenkins volume:

    docker volume rm jenkins_home_aks_lab

Optional local image cleanup:

    docker rmi jenkins-aks-lab:local
    docker image prune -f
    docker builder prune -f

## Security cleanup

After testing, remove or rotate temporary service principal secrets used in Jenkins.

Do not commit secrets into Git.

For production, prefer:

- Dedicated Jenkins agents
- Least privilege permissions
- Secret rotation
- OIDC or federated credentials where possible
- External secret managers
- Jenkins credentials with restricted access

## Important note

This is a learning lab.

Running Jenkins as root and mounting the Docker socket is acceptable for a local lab, but it is not recommended for production.

Production Jenkins setups should use dedicated build agents, hardened worker nodes, least privilege access, and stronger credential isolation.
