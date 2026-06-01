# Practitioner Lab 07 - Jenkins to AKS

මෙම lab එකෙන් Jenkins use කරලා small web application image එකක් build කරලා, ඒ image එක Azure Container Registry වලට publish කරලා, AKS වලට deploy කරලා, Kubernetes Service එක හරහා deployed application එක respond වෙනවද verify කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone deployment lab එකක්.

මෙම lab එක clean local setup එකකින් run කරන්න පුළුවන්.

මෙම lab එක use කරන්නේ:

- Docker තුළ locally run කරන Jenkins
- Local test repository එකක්
- Docker image build
- Azure Container Registry
- AKS deployment
- Azure සහ registry access සඳහා Jenkins credentials

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `jenkins-aks-cicd-lab` කියන Jenkins pipeline job එකක්
- Azure Container Registry වලට push වුණු container image එකක්
- `practitioner-jenkins` කියන Kubernetes namespace එකක්
- `jenkins-demo` කියන deployment එකක්
- `jenkins-demo` කියන service එකක්
- `kubectl port-forward` හරහා test කළ working web page එකක්

මෙම lab එක application එක publicly expose කරන්නේ නැහැ.

Final application test එක ඔයාගේ laptop එකෙන් AKS තුළ තියෙන Kubernetes Service එකට temporary local tunnel එකක් use කරනවා:

    http://localhost:8089

Expected page text:

    Jenkins to AKS Lab
    This app was built and deployed by Jenkins.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Standalone Jenkins deployment lab එකක් locally run කරන විදිය
- Docker, Azure CLI, kubectl, සහ required Jenkins plugins තියෙන custom Jenkins image එකක් build කරන විදිය
- Local Jenkins pipeline repository එකක් prepare කරන විදිය
- Azure සහ ACR සඳහා Jenkins credentials configure කරන විදිය
- Pipeline script from SCM සමඟ Jenkinsfile එකක් use කරන විදිය
- Jenkins තුළ container image එකක් build කරන විදිය
- Container image එකක් Azure Container Registry වලට publish කරන විදිය
- Push කළ image එක ACR තුළ තියෙනවද verify කරන විදිය
- Jenkins හරහා application එක AKS වලට deploy කරන විදිය
- Kubernetes rollout verify කරන විදිය
- `kubectl port-forward` use කරලා deployed app එක test කරන විදිය
- Jenkins, AKS, සහ ACR lab resources clean up කරන විදිය

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

Jenkins pipeline එක මේ stages use කරනවා:

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

ඔයාට මේවා අවශ්‍යයි:

- Docker Desktop
- Git
- Azure CLI
- kubectl
- Terminal එකක්
- Web browser එකක්
- AKS cluster එකක්
- Azure Container Registry
- CI/CD credentials සඳහා service principal එකක්

මෙම lab එක Jenkins Docker container එකක් තුළ run කරනවා. ඔයාගේ machine එකට Jenkins direct install කරන්න අවශ්‍ය නැහැ.

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

### Azure CLI

Azure CLI install කරන්න:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Azure CLI verify කරන්න:

    az version

Azure වලට login වෙන්න:

    az login

Active account එක verify කරන්න:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

### kubectl

kubectl install කරන්න:

    https://kubernetes.io/docs/tasks/tools/

kubectl verify කරන්න:

    kubectl version --client

## Check local tools and Azure access

Continue කරන්න කලින් verify කරන්න:

    docker version
    git --version
    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl version --client

ඔයාගේ AKS සහ ACR values set කරන්න:

    RESOURCE_GROUP="<resource-group-name>"
    AKS_NAME="<aks-cluster-name>"
    ACR_NAME="<acr-name>"

AKS access verify කරන්න:

    az aks get-credentials \
      --resource-group "$RESOURCE_GROUP" \
      --name "$AKS_NAME" \
      --overwrite-existing

    kubectl get nodes

ACR verify කරන්න:

    az acr show \
      --name "$ACR_NAME" \
      --query "{name:name, loginServer:loginServer}" \
      -o table

## Prepare Azure CI/CD variables

මෙම lab එක AKS වලට deploy කරනවා සහ image එක Azure Container Registry වලට publish කරනවා.

Jenkins pipeline run කරන්න කලින් required Azure සහ registry values shared guide එකෙන් සකස් කරන්න:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

Jenkins credentials සඳහා ඔයාට මේ values අවශ්‍යයි:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

මෙම learning setup එකට service principal එකට මේ permissions ප්‍රමාණවත් විය යුතුයි:

- ACR වලට images push කිරීම
- AKS credentials ලබා ගැනීම
- Target namespace එකට Kubernetes manifests apply කිරීම

## Files in this lab

මෙම lab එකේ files:

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

පළමු commands `terraform-azure-aks` repository root එකේ සිට run කරන්න.

Local test repository එක platform repository එකෙන් පිටත මෙතන create වෙනවා:

    $HOME/terraform-azure-aks-labs

Paths set කරන්න:

    LAB_WORKDIR="$HOME/terraform-azure-aks-labs"
    PLATFORM_REPO="$(pwd)"
    APP_REPO="$LAB_WORKDIR/jenkins-aks-cicd-lab"

Local test repository එක create කරන්න:

    mkdir -p "$LAB_WORKDIR"
    rm -rf "$APP_REPO"
    mkdir -p "$APP_REPO"
    cd "$APP_REPO"

    mkdir -p app k8s

`cd "$APP_REPO"` කළාට පස්සේ ඉතිරි local repository, Jenkins image build, සහ Jenkins run commands මේ path එකෙන් run වෙනවා:

    $HOME/terraform-azure-aks-labs/jenkins-aks-cicd-lab

Lab files copy කරන්න:

    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/app/"* app/
    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/k8s/"* k8s/
    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/jenkins/Jenkinsfile" Jenkinsfile

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
    git commit -m "Add Jenkins AKS lab app"
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

මෙම plugins මෙම lab එකට අවශ්‍ය Jenkins Pipeline, Git SCM, සහ credentials functionality provide කරනවා.

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

Jenkins image එක build කරන්න:

    docker build -t jenkins-aks-lab:local -f Dockerfile.jenkins .

Expected result:

    naming to docker.io/library/jenkins-aks-lab:local

## Run Jenkins locally

Same lab names තියෙන previous container හෝ volume තිබුණොත් remove කරන්න:

    docker rm -f jenkins-aks-lab 2>/dev/null || true
    docker volume rm jenkins_home_aks_lab 2>/dev/null || true

Jenkins volume එක create කරන්න:

    docker volume create jenkins_home_aks_lab

Jenkins run කරන්න:

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

මෙම lab එක Jenkins root ලෙස run කරනවා Docker socket access කරන්න. මෙය local learning සඳහා විතරයි.

Container එක running ද verify කරන්න:

    docker ps | grep jenkins-aks-lab

Initial admin password එක ගන්න:

    docker exec jenkins-aks-lab cat /var/jenkins_home/secrets/initialAdminPassword

Jenkins open කරන්න:

    http://localhost:8088

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

Pipeline job type, Git SCM option, සහ credentials UI තියෙනවා නම්, lab එක continue කරන්න.

Pipeline job type හෝ Git SCM option missing නම්, custom image එක සහ fresh volume එක use කරලා Jenkins නැවත create කරන්න.

## Verify tools inside Jenkins

Jenkins container එක ඇතුළේ shell එකක් open කරන්න:

    docker exec -it jenkins-aks-lab bash

Tools check කරන්න:

    whoami
    docker version
    az version
    kubectl version --client

Expected:

    whoami should show root
    docker version should work
    az version should work
    kubectl version --client should work

Exit කරන්න:

    exit

## Add Jenkins credentials

Jenkins වලට යන්න:

    Manage Jenkins
    Credentials
    System
    Global credentials
    Add Credentials

Each value එක සඳහා:

    Kind: Secret text
    Scope: Global
    ID: exact ID shown below
    Description: same as ID

මෙම credential IDs add කරන්න:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

මෙම ACR learning setup එකට:

    REGISTRY_USERNAME = AZURE_CLIENT_ID
    REGISTRY_PASSWORD = AZURE_CLIENT_SECRET

Credential IDs Jenkinsfile එකේ IDs සමඟ exact match වෙන්න ඕන.

Secrets Jenkinsfile එකට paste කරන්න එපා.

Secrets Git වලට commit කරන්න එපා.

## Create the Jenkins pipeline job

Jenkins වල:

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

Job එක save කරන්න.

## Run the pipeline

Click කරන්න:

    Build Now

Pipeline එක මේ stages complete කරන්න ඕන:

    Validate
    Build and Push
    Deploy
    Verify

Pipeline එක කරන්නේ:

1. Required files validate කරනවා
2. Azure Container Registry වලට login වෙනවා
3. Docker image එක build කරනවා
4. Image එක ACR වලට push කරනවා
5. Azure login වෙනවා
6. AKS credentials ගන්නවා
7. Kubernetes manifests apply කරනවා
8. Rollout verify කරනවා

Image එක Jenkins build number එකෙන් tag වෙනවා:

    <registry-login-server>/jenkins-demo:<build-number>

Jenkinsfile එක image එක `linux/amd64` සඳහා build කරනවා:

    docker build \
      --platform linux/amd64 \
      -t "$REGISTRY_LOGIN_SERVER/$IMAGE_NAME:$BUILD_NUMBER" \
      app

Jenkins Apple Silicon machine එකක run වෙලා AKS nodes amd64 නම් මේක වැදගත්.

## Verify image in Azure Container Registry

Pipeline success වුණාට පස්සේ Jenkins image එක ACR වලට push කළාද verify කරන්න.

Repositories list කරන්න:

    az acr repository list \
      --name "$ACR_NAME" \
      --output table

Expected repository:

    jenkins-demo

Image tags list කරන්න:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository jenkins-demo \
      --output table

Expected:

    Jenkins build number එකට match වෙන tag එකක් list වෙන්න ඕන.

## Verify deployment in AKS

Pipeline success වුණාට පස්සේ Kubernetes resources verify කරන්න:

    kubectl get ns practitioner-jenkins
    kubectl get deployment jenkins-demo -n practitioner-jenkins
    kubectl get pods -n practitioner-jenkins -o wide
    kubectl get svc jenkins-demo -n practitioner-jenkins

Expected:

    namespace exists
    deployment shows available replicas
    pod status is Running
    service exists

Rollout check කරන්න:

    kubectl rollout status deployment/jenkins-demo -n practitioner-jenkins --timeout=180s

## Test the application with port-forward

මෙම lab එක public Azure URL එකක් create කරන්නේ නැහැ.

Kubernetes Service එක `kubectl port-forward` හරහා test කරනවා.

Port-forward එක ඔයාගේ laptop එකෙන් AKS තුළ run වෙන service එකට temporary local connection එකක් create කරනවා.

Service එක port-forward කරන්න:

    kubectl port-forward svc/jenkins-demo -n practitioner-jenkins 8089:80

ඔයාගේ laptop එකෙන් open කරන්න:

    http://localhost:8089

නැත්නම් වෙන terminal එකකින් curl test කරන්න:

    curl http://localhost:8089

Expected page text:

    Jenkins to AKS Lab
    This app was built and deployed by Jenkins.

Port-forward stop කරන්න `Ctrl+C` press කරන්න.

## Troubleshooting

### Suggested plugin installation failures

Jenkins suggested plugins වල Workspace Cleanup, Gradle, GitHub Branch Source, Pipeline Graph View, හෝ Email Extension වගේ plugins fail වුණොත්, lab එක වහාම නවත්තන්න එපා.

මෙම lab එක required plugins already installed කරපු custom Jenkins image එකක් use කරනවා.

Jenkins dashboard එකට continue කරලා Pipeline job එක create කරන්න.

Pipeline job type හෝ Git SCM option missing නම්, custom image එක සහ fresh volume එක use කරලා Jenkins නැවත create කරන්න.

### Jenkins dashboard does not open

Container එක check කරන්න:

    docker ps | grep jenkins-aks-lab

Logs check කරන්න:

    docker logs jenkins-aks-lab --tail=100

Port mapping එක මෙහෙම use කරනවද බලන්න:

    8088:8080

ඊට පස්සේ open කරන්න:

    http://localhost:8088

### Docker socket permission denied

Jenkins Docker access කරන්න බැරි නම්:

    permission denied while trying to connect to the Docker daemon socket

Jenkins start කළේ මේ option එකෙන්ද බලන්න:

    --user root

සහ:

    -v /var/run/docker.sock:/var/run/docker.sock

මෙය local learning lab එකට විතරයි.

### Local Git checkout blocked

Jenkins `file://` Git checkout block කළොත්:

    Checkout of Git remote file:///workspace/jenkins-aks-cicd-lab aborted

Jenkins start කළේ මේ option එකෙන්ද බලන්න:

    -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"

### Azure login failed

Pipeline එකේ Azure login fail වුණොත් Jenkins credentials verify කරන්න:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID

Service principal secret expire වෙලා නැද්ද බලන්න.

### ACR login or push failed

Docker login හෝ image push fail වුණොත් verify කරන්න:

    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Service principal එකට ACR වලට push කරන්න permission තියෙනවද බලන්න.

Learning setup එකකට service principal එකට registry එකේ `AcrPush` permission අවශ්‍ය වෙන්න සාමාන්‍යයි.

### AKS credentials failed

`az aks get-credentials` fail වුණොත් verify කරන්න:

    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME

Service principal එකට AKS cluster details read කරන්න permission තියෙනවදත් බලන්න.

### ImagePullBackOff with platform mismatch

Pod එකේ මේ error එක පේනවා නම්:

    no match for platform in manifest

Jenkinsfile එක image build කරන්න මේ option එක use කරනවද බලන්න:

    --platform linux/amd64

ඊට පස්සේ pipeline එක නැවත run කරන්න.

### ACR pull permission issue

ACR access check කරන්න:

    az aks check-acr \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --acr <acr-name>

අවශ්‍ය නම් ACR attach කරන්න:

    az aks update \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --attach-acr <acr-name>

### Rollout timeout

Rollout timeout වුණොත් pods සහ events inspect කරන්න:

    kubectl get pods -n practitioner-jenkins -o wide
    kubectl describe pod -n practitioner-jenkins -l app=jenkins-demo
    kubectl get events -n practitioner-jenkins --sort-by=.lastTimestamp | tail -30

## Cleanup

AKS resources delete කරන්න:

    kubectl delete namespace practitioner-jenkins --ignore-not-found

මෙම lab එකෙන් create කළ ACR repository එක delete කරන්න:

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository jenkins-demo \
      --yes

Jenkins stop කරලා remove කරන්න:

    docker rm -f jenkins-aks-lab

Jenkins volume remove කරන්න:

    docker volume rm jenkins_home_aks_lab

Custom Jenkins image remove කරන්න:

    docker rmi jenkins-aks-lab:local

Optional local repository cleanup:

    rm -rf "$APP_REPO"

Optional Docker cleanup:

    docker image prune -f
    docker builder prune -f

## Security cleanup

Testing ඉවර වුණාම Jenkins වල use කළ temporary service principal secrets remove හෝ rotate කරන්න.

Secrets Git වලට commit කරන්න එපා.

Long-lived credentials local notes හෝ screenshots වල store කරන්න එපා.

Production සඳහා prefer කරන්න:

- Dedicated Jenkins agents
- Least privilege permissions
- Short-lived credentials
- Secret rotation
- OIDC or federated credentials where possible
- External secret managers
- Jenkins credentials with restricted access

## Important note

මෙය learning lab එකක්.

Jenkins root ලෙස run කිරීම සහ Docker socket mount කිරීම local lab එකකට acceptable වුණත් production සඳහා recommended නැහැ.

Production Jenkins setups වලදී dedicated build agents, hardened worker nodes, least privilege access, සහ stronger credential isolation use කරන්න.
