# Practitioner Lab 08 - Jenkins DevSecOps Checks

මෙම lab එකෙන් Jenkins pipeline එකකට DevSecOps checks add කරන විදිය ඉගෙන ගන්නවා.

මෙය scan-only lab එකක්. මෙය ACR වලට images push කරන්නේ නැහැ, AKS වලට deploy කරන්නේ නැහැ.

මෙම lab එකට අවශ්‍ය නැති දේවල්:

- Azure credentials
- Registry credentials
- AKS access
- Jenkins deployment credentials
- CI/CD deployment variables

මෙය Lab 07 replace කරන්නේ නැහැ.

Lab 07 teaches:

    validate -> build image -> push image -> deploy -> verify

This lab teaches:

    validate -> scan config -> build image -> scan image -> summary

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Jenkins environment එකට Trivy add කරන විදිය
- Dockerfiles සහ Kubernetes YAML scan කරන විදිය
- Jenkins වල local Docker image එකක් build කරන විදිය
- Saved image archive එකක් Trivy වලින් scan කරන විදිය
- Scan-only pipelines වලට deployment credentials අවශ්‍ය නැත්තේ ඇයි කියලා
- Security checks deployment වලින් separate කරන විදිය

## Tool used

මෙම lab එක Trivy use කරනවා.

Trivy scan කරන්න පුළුවන්:

- Container images
- Dockerfiles
- Kubernetes YAML
- Infrastructure configuration
- Filesystems

## Why this lab does not deploy

මෙම lab එක DevSecOps checks වලට විතරක් focus කරනවා.

Jenkins deployment flow එක Lab 07 වල cover කරලා තියෙනවා.

මෙම lab එක scan-only විදියට තියාගන්න එකෙන් Azure login, registry push, AKS credentials, rollout verification වගේ deployment steps mix නොකර security scanning තේරුම් ගන්න ලේසි වෙනවා.

Production Jenkins pipeline එකකදී patterns දෙකම combine කරන්න පුළුවන්:

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

මෙම lab එකේ files:

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

Platform repo root එකෙන් separate local test repository එකක් create කරන්න:

    LAB_WORKDIR="$HOME/terraform-azure-aks-labs"
    PLATFORM_REPO="$(pwd)"
    APP_REPO="$LAB_WORKDIR/jenkins-devsecops-lab"

    mkdir -p "$LAB_WORKDIR"
    rm -rf "$APP_REPO"
    mkdir -p "$APP_REPO"
    cd "$APP_REPO"

    mkdir -p app k8s

Lab files copy කරන්න:

    cp "$PLATFORM_REPO/terraform-azure-aks/labs/practitioner/08-jenkins-devsecops/app/"* app/
    cp "$PLATFORM_REPO/terraform-azure-aks/labs/practitioner/08-jenkins-devsecops/k8s/"* k8s/
    cp "$PLATFORM_REPO/terraform-azure-aks/labs/practitioner/08-jenkins-devsecops/jenkins/Jenkinsfile" Jenkinsfile

Git initialize කරන්න:

    git init
    git add .
    git commit -m "Add Jenkins DevSecOps lab app"
    git branch -M main

Files verify කරන්න:

    find . -maxdepth 3 -type f | sort

Expected files:

    ./Jenkinsfile
    ./app/Dockerfile
    ./app/index.html
    ./k8s/deployment.yaml
    ./k8s/namespace.yaml
    ./k8s/service.yaml

## Add Trivy to the Jenkins image

Lab 07 වල custom Jenkins image එකක් create කළා.

මෙම lab එකට `Dockerfile.jenkins` එකට Trivy add කරන්න.

kubectl install section එකට පස්සේ මෙය add කරන්න:

    RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
        | sh -s -- -b /usr/local/bin

Jenkins image එක rebuild කරන්න:

    docker build -t jenkins-aks-lab:local -f Dockerfile.jenkins .

Jenkins restart කරන්න:

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

Jenkins ඇතුළේ Trivy verify කරන්න:

    docker exec -it jenkins-aks-lab bash

    trivy --version
    docker version
    exit

## Create the Jenkins pipeline job

Jenkins වල:

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

Job එක save කරන්න.

මෙම lab එකට Jenkins credentials අවශ්‍ය නැහැ.

## Pipeline stages

Jenkinsfile එක මේ stages use කරනවා:

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

Click කරන්න:

    Build Now

Pipeline එක කරන්නේ:

1. Required files validate කරනවා
2. app directory එකට Trivy config scan run කරනවා
3. k8s directory එකට Trivy config scan run කරනවා
4. Local Docker image එකක් build කරනවා
5. Image එක `image.tar` ලෙස save කරනවා
6. `image.tar` Trivy වලින් scan කරනවා
7. Summary එක print කරනවා

## Learning mode

මෙම lab එක learning mode use කරනවා.

Trivy commands use කරන්නේ:

    --exit-code 0

ඒ කියන්නේ findings report වෙනවා, නමුත් pipeline එක fail වෙන්නේ නැහැ.

Scan output කියවන්න ඉගෙන ගන්නකොට මෙය useful.

## Strict security gate mode

Scan output එක තේරුම් ගත්තට පස්සේ, HIGH හෝ CRITICAL findings detect වුණොත් pipeline එක fail කරවන්න පුළුවන්.

Change කරන්න:

    --exit-code 0

to:

    --exit-code 1

Strict mode carefulව use කරන්න. Public base images වල vulnerabilities තිබිය හැකියි. ඒවා review කිරීම, patch කිරීම, හෝ documented risk acceptance අවශ්‍ය වෙන්න පුළුවන්.

## Why the image is scanned from image.tar

Local Jenkins labs වලදී Trivy direct Docker Desktop image scan එක Docker snapshot හෝ daemon issue නිසා fail වෙන්න පුළුවන්.

මෙම lab එක ඒ issue එක avoid කරන්න image එක මුලින් save කරනවා:

    docker save "$IMAGE_NAME:$BUILD_NUMBER" -o image.tar

ඊට පස්සේ archive එක scan කරනවා:

    trivy image \
      --input image.tar \
      --severity HIGH,CRITICAL \
      --exit-code 0

මෙය local Docker Desktop environments වල scan එක stable කරනවා.

## Expected result

Pipeline එක මේ stages සියල්ල complete කරන්න ඕන:

    Validate
    Scan Config
    Build Image
    Scan Image
    Summary

Summary එකේ මෙය පේන්න ඕන:

    Jenkins DevSecOps checks completed.
    This lab does not push images to ACR.
    This lab does not deploy to AKS.

## Troubleshooting

### Trivy config multiple targets error

මෙවැනි error එකක් පේනවා නම්:

    multiple targets cannot be specified

මෙහෙම run කරන්න එපා:

    trivy config app k8s

Separate scans run කරන්න:

    trivy config app
    trivy config k8s

### Trivy image cannot find local image

Trivy image එක හොයාගන්න බැරි නම් හෝ Docker snapshot errors report කරනවා නම්, `docker save` use කරලා archive එක scan කරන්න:

    docker save "$IMAGE_NAME:$BUILD_NUMBER" -o image.tar

    trivy image --input image.tar

### Jenkins cannot access Docker

Jenkins Docker access කරන්න බැරි නම්:

    permission denied while trying to connect to the Docker daemon socket

Jenkins container එක මෙහෙම run කරන්න:

    --user root

මෙය local learning lab එකට විතරයි.

### Local Git checkout blocked

Jenkins `file://` Git checkout block කළොත්:

    Checkout of Git remote file:///workspace/jenkins-devsecops-lab aborted

Jenkins මේ option එකෙන් run කරන්න:

    -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"

## Cleanup

Local test image එක remove කරන්න:

    docker rmi jenkins-devsecops-demo:<build-number> 2>/dev/null || true

Dangling images remove කරන්න:

    docker image prune -f

Build cache remove කරන්න අවශ්‍ය නම්:

    docker builder prune -f

මෙම lab එක AKS resources create කරන්නේ නැහැ සහ images ACR එකට push කරන්නේ නැහැ.

## Important note

මෙය learning lab එකක්.

මෙම lab එක deployment credentials නැතුව Jenkins DevSecOps scanning teach කරනවා.

Production Jenkins DevSecOps pipelines වලදී include කරන්න:

- Code quality checks
- Dependency scanning
- Secret scanning
- IaC scanning
- SBOM generation
- Image signing
- Strict gates for protected branches
- Documented exception process
