# Practitioner Lab 08 - Jenkins DevSecOps Checks

This lab shows how to add DevSecOps checks to a Jenkins pipeline.

This is a standalone scan-only lab.

It does not push images to Azure Container Registry and it does not deploy to AKS.

The lab uses:

- Jenkins running locally in Docker
- A local test repository
- Trivy for security scanning
- A local Docker image build

## What you will learn

You will learn:

- How to run a standalone Jenkins DevSecOps lab locally
- How to build a custom Jenkins image with Docker, kubectl, Trivy, and required Jenkins plugins
- How to prepare a local Jenkins pipeline repository
- How to scan Dockerfiles and Kubernetes YAML with Trivy
- How to build a local Docker image in Jenkins
- How to scan a saved image archive with Trivy
- Why scan-only pipelines do not need Azure, registry, or AKS deployment credentials
- How to handle optional Jenkins suggested plugin failures during setup
- How to clean up all local lab resources

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
    Trivy config scan
      |
      v
    Docker image build
      |
      v
    Save image as image.tar
      |
      v
    Trivy image scan
      |
      v
    Summary

The Jenkins pipeline uses these stages:

    Validate
      |
      v
    Scan Config
      |
      v
    Build Image
      |
      v
    Scan Image
      |
      v
    Summary

## What this lab requires

You need:

- Docker Desktop
- Git
- A terminal
- A web browser

This lab runs Jenkins inside Docker. You do not need to install Jenkins directly on your machine.

This lab does not require:

- Azure credentials
- Registry credentials
- AKS access
- Jenkins deployment credentials
- CI/CD deployment variables

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

## Check local tools

Before continuing, verify:

    docker version
    git --version

## Files in this lab

This lab includes:

    app/
      Static NGINX app files

    k8s/
      Kubernetes manifests used for config scanning

    jenkins/
      Jenkinsfile DevSecOps pipeline template

Files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    jenkins/Jenkinsfile

## Create the Jenkins DevSecOps test repository

Run these commands from the `terraform-azure-aks` repository root.

The local test repository is created outside the platform repository under:

    $HOME/terraform-azure-aks-labs

Set paths:

    LAB_WORKDIR="$HOME/terraform-azure-aks-labs"
    PLATFORM_REPO="$(pwd)"
    APP_REPO="$LAB_WORKDIR/jenkins-devsecops-lab"

Create the local test repository:

    mkdir -p "$LAB_WORKDIR"
    rm -rf "$APP_REPO"
    mkdir -p "$APP_REPO"
    cd "$APP_REPO"

    mkdir -p app k8s

Copy the lab files:

    cp "$PLATFORM_REPO/labs/practitioner/08-jenkins-devsecops/app/"* app/
    cp "$PLATFORM_REPO/labs/practitioner/08-jenkins-devsecops/k8s/"* k8s/
    cp "$PLATFORM_REPO/labs/practitioner/08-jenkins-devsecops/jenkins/Jenkinsfile" Jenkinsfile

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
    git commit -m "Add Jenkins DevSecOps lab app"
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

These plugins provide the Jenkins Pipeline and Git SCM functionality required for this lab.

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

    RUN ARCH="$(dpkg --print-architecture)" && \
        case "$ARCH" in \
          amd64) KUBECTL_ARCH="amd64" ;; \
          arm64) KUBECTL_ARCH="arm64" ;; \
          *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
        esac && \
        curl -LO "https://dl.k8s.io/release/v1.34.0/bin/linux/${KUBECTL_ARCH}/kubectl" && \
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
        rm kubectl

    RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
        | sh -s -- -b /usr/local/bin

    RUN usermod -aG docker jenkins

    USER jenkins

    COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
    RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
    EOF_DOCKERFILE

Build the Jenkins image:

    docker build -t jenkins-devsecops-lab:local -f Dockerfile.jenkins .

Expected result:

    naming to docker.io/library/jenkins-devsecops-lab:local

## Run Jenkins locally

Remove any previous container or volume with the same lab names:

    docker rm -f jenkins-devsecops-lab 2>/dev/null || true
    docker volume rm jenkins_home_devsecops_lab 2>/dev/null || true

Create a Jenkins volume:

    docker volume create jenkins_home_devsecops_lab

Run Jenkins:

    docker run -d \
      --name jenkins-devsecops-lab \
      --user root \
      -p 8090:8080 \
      -p 50001:50000 \
      -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true" \
      -v jenkins_home_devsecops_lab:/var/jenkins_home \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$APP_REPO:/workspace/jenkins-devsecops-lab" \
      jenkins-devsecops-lab:local

This lab runs Jenkins as root only for local learning so it can access the Docker socket.

Verify the container is running:

    docker ps | grep jenkins-devsecops-lab

Get the initial admin password:

    docker exec jenkins-devsecops-lab cat /var/jenkins_home/secrets/initialAdminPassword

Open Jenkins:

    http://localhost:8090

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

If the Pipeline job type and Git SCM option are available, continue the lab.

If the Pipeline job type or Git SCM option is missing, recreate Jenkins with the custom image and a fresh volume.

## Verify tools inside Jenkins

Open a shell inside the Jenkins container:

    docker exec -it jenkins-devsecops-lab bash

Check tools:

    whoami
    docker version
    kubectl version --client
    trivy --version

Expected:

    whoami should show root
    docker version should work
    kubectl version --client should work
    trivy --version should work

Exit:

    exit

## Create the Jenkins pipeline job

In Jenkins:

    New Item
    jenkins-devsecops-lab
    Pipeline
    OK

Pipeline configuration:

    Definition: Pipeline script from SCM
    SCM: Git
    Repository URL: file:///workspace/jenkins-devsecops-lab
    Branch Specifier: */main
    Script Path: Jenkinsfile

Save the job.

This lab does not need Jenkins credentials.

## Run the pipeline

Click:

    Build Now

The pipeline should complete these stages:

    Validate
    Scan Config
    Build Image
    Scan Image
    Summary

The pipeline should:

1. Validate required files
2. Run Trivy config scan against the app directory
3. Run Trivy config scan against the k8s directory
4. Build a local Docker image
5. Save the image to `image.tar`
6. Scan `image.tar` with Trivy
7. Print a summary

Expected summary:

    Jenkins DevSecOps checks completed.
    This lab does not push images to ACR.
    This lab does not deploy to AKS.
    Image scanned locally: jenkins-devsecops-demo:<build-number>

## Learning mode

This lab uses learning mode.

The Trivy commands use:

    --exit-code 0

This means findings are reported, but the pipeline does not fail.

This is useful while learning how to read scan output.

## Strict security gate mode

After you understand the scan output, you can make the pipeline fail when HIGH or CRITICAL findings are detected.

Change:

    --exit-code 0

To:

    --exit-code 1

Use strict mode carefully.

Public base images can include vulnerabilities that require review, patching, or documented risk acceptance.

## Why the image is scanned from image.tar

In local Jenkins labs, Trivy can fail to scan an image directly from Docker Desktop because of Docker snapshot or daemon issues.

This lab avoids that issue by saving the image first:

    docker save "$IMAGE_NAME:$BUILD_NUMBER" -o image.tar

Then scanning the archive:

    trivy image \
      --input image.tar \
      --severity HIGH,CRITICAL \
      --exit-code 0

This makes the scan more stable in local Docker Desktop environments.

## Troubleshooting

### Suggested plugin installation failures

If Jenkins reports failures for suggested plugins such as Workspace Cleanup, Gradle, GitHub Branch Source, Pipeline Graph View, or Email Extension, do not stop the lab immediately.

This lab uses a custom Jenkins image with the required plugins already installed.

Continue to the Jenkins dashboard and create the Pipeline job.

If the Pipeline job type or Git SCM option is missing, recreate Jenkins with a fresh volume using the custom image.

### Jenkins dashboard does not open

Check the container:

    docker ps | grep jenkins-devsecops-lab

Check logs:

    docker logs jenkins-devsecops-lab --tail=100

Make sure the port mapping uses:

    8090:8080

Then open:

    http://localhost:8090

### Local Git checkout blocked

If Jenkins blocks `file://` Git checkout:

    Checkout of Git remote file:///workspace/jenkins-devsecops-lab aborted

Make sure Jenkins was started with:

    -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"

### Jenkins cannot access Docker

If Jenkins cannot access Docker:

    permission denied while trying to connect to the Docker daemon socket

Make sure Jenkins was started with:

    --user root

And with:

    -v /var/run/docker.sock:/var/run/docker.sock

This is only for the local learning lab.

### Trivy config multiple targets error

If you see:

    multiple targets cannot be specified

Do not run:

    trivy config app k8s

Run separate scans:

    trivy config app
    trivy config k8s

### Trivy image cannot find local image

If Trivy cannot find the image or reports Docker snapshot errors, use `docker save` and scan the archive:

    docker save "$IMAGE_NAME:$BUILD_NUMBER" -o image.tar

    trivy image --input image.tar

## Cleanup

Stop and remove Jenkins:

    docker rm -f jenkins-devsecops-lab

Remove the Jenkins volume:

    docker volume rm jenkins_home_devsecops_lab

Remove the custom Jenkins image:

    docker rmi jenkins-devsecops-lab:local

Remove the local test image created by the pipeline:

    docker rmi jenkins-devsecops-demo:<build-number> 2>/dev/null || true

Remove dangling images:

    docker image prune -f

Remove build cache if needed:

    docker builder prune -f

Optional local repository cleanup:

    rm -rf "$APP_REPO"

This lab does not create AKS resources.

This lab does not push images to ACR.

## Important note

This is a learning lab.

It teaches DevSecOps scanning in Jenkins without Azure, registry, or AKS deployment credentials.

Running Jenkins as root and mounting the Docker socket is acceptable for a local lab, but it is not recommended for production.

Production Jenkins DevSecOps pipelines should include:

- Dedicated Jenkins agents
- Least privilege permissions
- Code quality checks
- Dependency scanning
- Secret scanning
- IaC scanning
- SBOM generation
- Image signing
- Strict gates for protected branches
- Documented exception process
