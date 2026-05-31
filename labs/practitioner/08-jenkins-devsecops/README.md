# Practitioner Lab 08 - Jenkins DevSecOps Checks

This lab shows how to add DevSecOps checks to a Jenkins pipeline.

It is a scan-only lab. It does not push images to ACR and it does not deploy to AKS.

This lab does not require:

- Azure credentials
- Registry credentials
- AKS access
- Jenkins deployment credentials
- CI/CD deployment variables

It does not replace Lab 07.

Lab 07 teaches:

    validate -> build image -> push image -> deploy -> verify

This lab teaches:

    validate -> scan config -> build image -> scan image -> summary

## What you will learn

You will learn:

- How to add Trivy to a Jenkins environment
- How to scan Dockerfiles and Kubernetes YAML
- How to build a local Docker image in Jenkins
- How to scan a saved image archive with Trivy
- Why scan-only pipelines do not need deployment credentials
- How to separate security checks from deployment

## Tool used

This lab uses Trivy.

Trivy can scan:

- Container images
- Dockerfiles
- Kubernetes YAML
- Infrastructure configuration
- Filesystems

## Why this lab does not deploy

This lab focuses only on DevSecOps checks.

Deployment with Jenkins is already covered in Lab 07.

Keeping this lab scan-only makes it easier to understand security scanning without mixing it with Azure login, registry push, AKS credentials, or rollout verification.

A production Jenkins pipeline can combine both patterns:

    validate
      |
      v
    scan config
      |
      v
    build image
      |
      v
    scan image
      |
      v
    push image
      |
      v
    deploy
      |
      v
    verify

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

Create a separate local test repository from the platform repo root:

    LAB_WORKDIR="$HOME/terraform-azure-aks-labs"
    PLATFORM_REPO="$(pwd)"
    APP_REPO="$LAB_WORKDIR/jenkins-devsecops-lab"

    mkdir -p "$LAB_WORKDIR"
    rm -rf "$APP_REPO"
    mkdir -p "$APP_REPO"
    cd "$APP_REPO"

    mkdir -p app k8s

Copy the lab files:

    cp "$PLATFORM_REPO/terraform-azure-aks/labs/practitioner/08-jenkins-devsecops/app/"* app/
    cp "$PLATFORM_REPO/terraform-azure-aks/labs/practitioner/08-jenkins-devsecops/k8s/"* k8s/
    cp "$PLATFORM_REPO/terraform-azure-aks/labs/practitioner/08-jenkins-devsecops/jenkins/Jenkinsfile" Jenkinsfile

Initialize Git:

    git init
    git add .
    git commit -m "Add Jenkins DevSecOps lab app"
    git branch -M main

Verify files:

    find . -maxdepth 3 -type f | sort

Expected files:

    ./Jenkinsfile
    ./app/Dockerfile
    ./app/index.html
    ./k8s/deployment.yaml
    ./k8s/namespace.yaml
    ./k8s/service.yaml

## Add Trivy to the Jenkins image

Lab 07 created a custom Jenkins image.

For this lab, add Trivy to `Dockerfile.jenkins`.

Add this after the kubectl install section:

    RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
        | sh -s -- -b /usr/local/bin

Rebuild the Jenkins image:

    docker build -t jenkins-aks-lab:local -f Dockerfile.jenkins .

Restart Jenkins:

    docker rm -f jenkins-aks-lab

    docker run -d \
      --name jenkins-aks-lab \
      --user root \
      -p 8088:8080 \
      -p 50000:50000 \
      -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true" \
      -v jenkins_home_aks_lab:/var/jenkins_home \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$LAB_WORKDIR/jenkins-aks-cicd-lab:/workspace/jenkins-aks-cicd-lab" \
      -v "$APP_REPO:/workspace/jenkins-devsecops-lab" \
      jenkins-aks-lab:local

Verify Trivy inside Jenkins:

    docker exec -it jenkins-aks-lab bash

    trivy --version
    docker version
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

## Pipeline stages

The Jenkinsfile uses these stages:

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

## Run the pipeline

Click:

    Build Now

The pipeline should:

1. Validate required files
2. Run Trivy config scan against the app directory
3. Run Trivy config scan against the k8s directory
4. Build a local Docker image
5. Save the image to `image.tar`
6. Scan `image.tar` with Trivy
7. Print a summary

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

to:

    --exit-code 1

Use strict mode carefully. Public base images may include vulnerabilities that require review, patching, or documented risk acceptance.

## Why the image is scanned from image.tar

In local Jenkins labs, Trivy may fail to scan an image directly from Docker Desktop because of Docker snapshot or daemon issues.

This lab avoids that issue by saving the image first:

    docker save "$IMAGE_NAME:$BUILD_NUMBER" -o image.tar

Then scanning the archive:

    trivy image \
      --input image.tar \
      --severity HIGH,CRITICAL \
      --exit-code 0

This makes the scan more stable in local Docker Desktop environments.

## Expected result

The pipeline should complete all stages:

    Validate
    Scan Config
    Build Image
    Scan Image
    Summary

The summary should show:

    Jenkins DevSecOps checks completed.
    This lab does not push images to ACR.
    This lab does not deploy to AKS.

## Troubleshooting

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

### Jenkins cannot access Docker

If Jenkins cannot access Docker:

    permission denied while trying to connect to the Docker daemon socket

Run the Jenkins container with:

    --user root

This is only for the local learning lab.

### Local Git checkout blocked

If Jenkins blocks `file://` Git checkout:

    Checkout of Git remote file:///workspace/jenkins-devsecops-lab aborted

Run Jenkins with:

    -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"

## Cleanup

Remove the local test image:

    docker rmi jenkins-devsecops-demo:<build-number> 2>/dev/null || true

Remove dangling images:

    docker image prune -f

Remove build cache if needed:

    docker builder prune -f

This lab does not create AKS resources and does not push images to ACR.

## Important note

This is a learning lab.

It teaches DevSecOps scanning in Jenkins without deployment credentials.

Production Jenkins DevSecOps pipelines should include:

- Code quality checks
- Dependency scanning
- Secret scanning
- IaC scanning
- SBOM generation
- Image signing
- Strict gates for protected branches
- Documented exception process
