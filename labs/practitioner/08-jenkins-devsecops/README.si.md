# Practitioner Lab 08 - Jenkins DevSecOps Checks

මෙම lab එකෙන් Jenkins pipeline එකකට DevSecOps checks add කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone scan-only lab එකක්.

මෙම lab එක Azure Container Registry එකට images push කරන්නේ නැහැ සහ AKS වලට deploy කරන්නේ නැහැ.

මෙම lab එක use කරන්නේ:

- Docker තුළ locally run කරන Jenkins
- Local test repository එකක්
- Security scanning සඳහා Trivy
- Local Docker image build එකක්

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Standalone Jenkins DevSecOps lab එකක් locally run කරන විදිය
- Docker, kubectl, Trivy, සහ required Jenkins plugins තියෙන custom Jenkins image එකක් build කරන විදිය
- Local Jenkins pipeline repository එකක් prepare කරන විදිය
- Trivy use කරලා Dockerfiles සහ Kubernetes YAML scan කරන විදිය
- Jenkins තුළ local Docker image එකක් build කරන විදිය
- Saved image archive එකක් Trivy වලින් scan කරන විදිය
- Scan-only pipelines වලට Azure, registry, හෝ AKS deployment credentials අවශ්‍ය නැත්තේ ඇයි කියලා
- Jenkins setup එකේ optional suggested plugin failures handle කරන විදිය
- Local lab resources සියල්ල clean up කරන විදිය

## Lab architecture

Flow එක:

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

Jenkins pipeline එක මේ stages use කරනවා:

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

ඔයාට මේවා අවශ්‍යයි:

- Docker Desktop
- Git
- Terminal එකක්
- Web browser එකක්

මෙම lab එක Jenkins Docker container එකක් තුළ run කරනවා. ඔයාගේ machine එකට Jenkins direct install කරන්න අවශ්‍ය නැහැ.

මෙම lab එකට අවශ්‍ය නැහැ:

- Azure credentials
- Registry credentials
- AKS access
- Jenkins deployment credentials
- CI/CD deployment variables

## Install required local tools

### Docker Desktop

ඔයාගේ operating system එකට Docker Desktop install කරන්න:

    https://www.docker.com/products/docker-desktop/

Docker Desktop install කළාට පස්සේ ඒක start කරලා terminal එකෙන් Docker verify කරන්න:

    docker version

Expected:

    Docker Client සහ Server sections දෙකම පේන්න ඕන.

Server section එක නැත්නම් Docker Desktop running නැහැ.

### Git

ඔයාගේ operating system එකට Git install කරන්න:

    https://git-scm.com/downloads

Git verify කරන්න:

    git --version

Expected:

    git version එක successfully print වෙන්න ඕන.

## Check local tools

Continue කරන්න කලින් verify කරන්න:

    docker version
    git --version

## Files in this lab

මෙම lab එකේ files:

    app/
      Static NGINX app files

    k8s/
      Config scanning සඳහා use කරන Kubernetes manifests

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

මෙම commands `terraform-azure-aks` repository root එකේ සිට run කරන්න.

Local test repository එක platform repository එකෙන් පිටත මෙතන create වෙනවා:

    $HOME/terraform-azure-aks-labs

Paths set කරන්න:

    LAB_WORKDIR="$HOME/terraform-azure-aks-labs"
    PLATFORM_REPO="$(pwd)"
    APP_REPO="$LAB_WORKDIR/jenkins-devsecops-lab"

Local test repository එක create කරන්න:

    mkdir -p "$LAB_WORKDIR"
    rm -rf "$APP_REPO"
    mkdir -p "$APP_REPO"
    cd "$APP_REPO"

    mkdir -p app k8s

Lab files copy කරන්න:

    cp "$PLATFORM_REPO/labs/practitioner/08-jenkins-devsecops/app/"* app/
    cp "$PLATFORM_REPO/labs/practitioner/08-jenkins-devsecops/k8s/"* k8s/
    cp "$PLATFORM_REPO/labs/practitioner/08-jenkins-devsecops/jenkins/Jenkinsfile" Jenkinsfile

Git initialize කරන්න කලින් files verify කරන්න:

    find . -maxdepth 3 -type f | sort

Expected files:

    ./Jenkinsfile
    ./app/Dockerfile
    ./app/index.html
    ./k8s/deployment.yaml
    ./k8s/namespace.yaml
    ./k8s/service.yaml

Jenkins SCM සඳහා local Git repository එක initialize කරන්න:

    git init
    git add .
    git commit -m "Add Jenkins DevSecOps lab app"
    git branch -M main

මේ repository එක local only. Jenkins mounted workspace path එක හරහා මෙය read කරනවා.

මේ test repository එක GitHub එකට push කරන්න එපා.

Local Git repository එක verify කරන්න:

    git status

Expected:

    On branch main
    nothing to commit, working tree clean

## Create the custom Jenkins image

මෙම lab එක තමන්ගේම Jenkins image එකක් build කරනවා.

Local test repository එකේ `plugins.txt` create කරන්න:

    cat > plugins.txt <<'EOF_PLUGINS'
    workflow-aggregator
    git
    credentials-binding
    pipeline-stage-view
    EOF_PLUGINS

මෙම plugins මෙම lab එකට අවශ්‍ය Jenkins Pipeline සහ Git SCM functionality provide කරනවා.

Local test repository එකේ `Dockerfile.jenkins` create කරන්න:

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

Jenkins image එක build කරන්න:

    docker build -t jenkins-devsecops-lab:local -f Dockerfile.jenkins .

Expected result:

    naming to docker.io/library/jenkins-devsecops-lab:local

## Run Jenkins locally

Same lab names තියෙන previous container හෝ volume තිබුණොත් remove කරන්න:

    docker rm -f jenkins-devsecops-lab 2>/dev/null || true
    docker volume rm jenkins_home_devsecops_lab 2>/dev/null || true

Jenkins volume එක create කරන්න:

    docker volume create jenkins_home_devsecops_lab

Jenkins run කරන්න:

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

මෙම lab එක Jenkins root ලෙස run කරනවා Docker socket access කරන්න. මෙය local learning සඳහා විතරයි.

Container එක running ද verify කරන්න:

    docker ps | grep jenkins-devsecops-lab

Initial admin password එක ගන්න:

    docker exec jenkins-devsecops-lab cat /var/jenkins_home/secrets/initialAdminPassword

Jenkins open කරන්න:

    http://localhost:8090

## Jenkins setup wizard guidance

Required Jenkins plugins custom Jenkins image එකේ already installed.

Jenkins plugin installation ගැන අහනවා නම්, මෙම lab එකට suggested plugins මත depend වෙන්න එපා.

Jenkins option එක දෙනවා නම් suggested plugin installation skip කරන්න පුළුවන්.

ඔයා suggested plugins install කළා සහ optional plugins කිහිපයක් fail වුණා නම්, lab එක නවත්තන්න එපා.

මෙම lab එකට අවශ්‍ය නැති optional suggested plugins examples:

- Workspace Cleanup
- Gradle
- GitHub Branch Source
- Pipeline: GitHub Groovy Libraries
- Pipeline Graph View
- Email Extension

Jenkins dashboard එකට continue කරලා Pipeline job එකක් create කරන්න පුළුවන්ද බලන්න.

Pipeline job type සහ Git SCM option තියෙනවා නම්, lab එක continue කරන්න.

Pipeline job type හෝ Git SCM option missing නම්, custom image එක සහ fresh volume එක use කරලා Jenkins නැවත create කරන්න.

## Verify tools inside Jenkins

Jenkins container එක ඇතුළේ shell එකක් open කරන්න:

    docker exec -it jenkins-devsecops-lab bash

Tools check කරන්න:

    whoami
    docker version
    kubectl version --client
    trivy --version

Expected:

    whoami should show root
    docker version should work
    kubectl version --client should work
    trivy --version should work

Exit කරන්න:

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

## Run the pipeline

Click කරන්න:

    Build Now

Pipeline එක මේ stages complete කරන්න ඕන:

    Validate
    Scan Config
    Build Image
    Scan Image
    Summary

Pipeline එක කරන්නේ:

1. Required files validate කරනවා
2. app directory එකට Trivy config scan run කරනවා
3. k8s directory එකට Trivy config scan run කරනවා
4. Local Docker image එකක් build කරනවා
5. Image එක `image.tar` ලෙස save කරනවා
6. `image.tar` Trivy වලින් scan කරනවා
7. Summary එක print කරනවා

Expected summary:

    Jenkins DevSecOps checks completed.
    This lab does not push images to ACR.
    This lab does not deploy to AKS.
    Image scanned locally: jenkins-devsecops-demo:<build-number>

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

To:

    --exit-code 1

Strict mode carefulව use කරන්න.

Public base images වල vulnerabilities තිබිය හැකියි. ඒවා review කිරීම, patch කිරීම, හෝ documented risk acceptance අවශ්‍ය වෙන්න පුළුවන්.

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

## Troubleshooting

### Suggested plugin installation failures

Jenkins suggested plugins වල Workspace Cleanup, Gradle, GitHub Branch Source, Pipeline Graph View, හෝ Email Extension වගේ plugins fail වුණොත්, lab එක වහාම නවත්තන්න එපා.

මෙම lab එක required plugins already installed කරපු custom Jenkins image එකක් use කරනවා.

Jenkins dashboard එකට continue කරලා Pipeline job එක create කරන්න.

Pipeline job type හෝ Git SCM option missing නම්, custom image එක සහ fresh volume එක use කරලා Jenkins නැවත create කරන්න.

### Jenkins dashboard does not open

Container එක check කරන්න:

    docker ps | grep jenkins-devsecops-lab

Logs check කරන්න:

    docker logs jenkins-devsecops-lab --tail=100

Port mapping එක මෙහෙම use කරනවද බලන්න:

    8090:8080

ඊට පස්සේ open කරන්න:

    http://localhost:8090

### Local Git checkout blocked

Jenkins `file://` Git checkout block කළොත්:

    Checkout of Git remote file:///workspace/jenkins-devsecops-lab aborted

Jenkins start කළේ මේ option එකෙන්ද බලන්න:

    -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"

### Jenkins cannot access Docker

Jenkins Docker access කරන්න බැරි නම්:

    permission denied while trying to connect to the Docker daemon socket

Jenkins start කළේ මේ option එකෙන්ද බලන්න:

    --user root

සහ:

    -v /var/run/docker.sock:/var/run/docker.sock

මෙය local learning lab එකට විතරයි.

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

## Cleanup

Jenkins stop කරලා remove කරන්න:

    docker rm -f jenkins-devsecops-lab

Jenkins volume remove කරන්න:

    docker volume rm jenkins_home_devsecops_lab

Custom Jenkins image remove කරන්න:

    docker rmi jenkins-devsecops-lab:local

Pipeline එකෙන් create වුණු local test image එක remove කරන්න:

    docker rmi jenkins-devsecops-demo:<build-number> 2>/dev/null || true

Dangling images remove කරන්න:

    docker image prune -f

Build cache remove කරන්න අවශ්‍ය නම්:

    docker builder prune -f

Optional local repository cleanup:

    rm -rf "$APP_REPO"

මෙම lab එක AKS resources create කරන්නේ නැහැ.

මෙම lab එක ACR වලට images push කරන්නේ නැහැ.

## Important note

මෙය learning lab එකක්.

මෙම lab එක Azure, registry, හෝ AKS deployment credentials නැතුව Jenkins DevSecOps scanning teach කරනවා.

Jenkins root ලෙස run කිරීම සහ Docker socket mount කිරීම local lab එකකට acceptable වුණත් production සඳහා recommended නැහැ.

Production Jenkins DevSecOps pipelines වලදී include කරන්න:

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
