# Practitioner Lab 07 - Jenkins to AKS

මෙම lab එකෙන් Jenkins use කරලා container image එකක් build කරලා Azure Container Registry එකට push කරලා, application එක AKS වලට deploy කරන විදිය ඉගෙන ගන්නවා.

මෙම lab එක simple static NGINX app එකක් use කරනවා. ඒ නිසා focus එක Jenkins, Docker, ACR, සහ AKS deployment flow එකට තියාගන්න පුළුවන්.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Jenkins locally Docker එක්ක run කරන විදිය
- Jenkins pipeline repository එක prepare කරන විදිය
- Docker, Azure CLI, සහ kubectl තියෙන custom Jenkins image එකක් build කරන විදිය
- Jenkins credentials add කරන විදිය
- Jenkinsfile එකක් use කරන විදිය
- Container image එකක් build කරලා ACR එකට push කරන විදිය
- Jenkins හරහා AKS වලට deploy කරන විදිය
- Rollout verify කරලා app එක local machine එකෙන් test කරන විදිය

## Lab architecture

Flow එක:

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
- Azure CLI
- kubectl
- AKS cluster
- Azure Container Registry
- Jenkins running locally in Docker
- CI/CD credentials සඳහා service principal එකක්

Local tools check කරන්න:

    docker version
    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl get nodes
    az acr show --name <acr-name> --query loginServer -o tsv

## Prepare Azure CI/CD variables

මෙම lab එක AKS වලට deploy කරනවා සහ image එක registry එකට push කරනවා.

Jenkins pipeline run කරන්න කලින් required Azure සහ registry values shared guide එකෙන් සකස් කරන්න:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

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

Separate local test repository එකක් create කරන්න:

    LAB_WORKDIR="$HOME/terraform-azure-aks-labs"
    PLATFORM_REPO="$(pwd)"
    APP_REPO="$LAB_WORKDIR/jenkins-aks-cicd-lab"

    mkdir -p "$LAB_WORKDIR"
    rm -rf "$APP_REPO"
    mkdir -p "$APP_REPO"
    cd "$APP_REPO"

    mkdir -p app k8s

Lab files copy කරන්න:

    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/app/"* app/
    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/k8s/"* k8s/
    cp "$PLATFORM_REPO/labs/practitioner/07-jenkins-to-aks/jenkins/Jenkinsfile" Jenkinsfile

Jenkins SCM සඳහා local Git repository එක initialize කරන්න:

    git init
    git add .
    git commit -m "Add Jenkins AKS lab app"
    git branch -M main

මේ repository එක local only. Jenkins mounted workspace path එක හරහා මෙය read කරනවා.
මේ test repository එක GitHub එකට push කරන්න එපා.

Files verify කරන්න:

    find . -maxdepth 3 -type f | sort

Expected files:

    ./Jenkinsfile
    ./app/Dockerfile
    ./app/index.html
    ./k8s/deployment.yaml
    ./k8s/namespace.yaml
    ./k8s/service.yaml

## Create the custom Jenkins image

Jenkins container එකට Docker, Azure CLI, kubectl, සහ required Jenkins plugins අවශ්‍යයි.

Test repository එකේ `plugins.txt` create කරන්න:

    cat > plugins.txt <<'EOF'
    workflow-aggregator
    git
    credentials-binding
    pipeline-stage-view
    EOF

`Dockerfile.jenkins` create කරන්න:

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

Jenkins image එක build කරන්න:

    docker build -t jenkins-aks-lab:local -f Dockerfile.jenkins .

## Run Jenkins locally

Jenkins volume එකක් create කරන්න:

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

මෙම lab එක Jenkins root ලෙස run කරනවා Docker socket access කරන්න. මෙය local learning lab එකකට විතරයි.

Initial admin password එක ගන්න:

    docker exec jenkins-aks-lab cat /var/jenkins_home/secrets/initialAdminPassword

Jenkins open කරන්න:

    http://localhost:8088

Suggested plugins install කරන්න, නැත්නම් required plugins custom image එකෙන් already install වෙලා නම් continue කරන්න.

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

Pipeline එක කරන්නේ:

1. Required files validate කරනවා
2. Docker image එක build කරනවා
3. Image එක ACR එකට push කරනවා
4. Azure login වෙනවා
5. AKS credentials ගන්නවා
6. Kubernetes manifests apply කරනවා
7. Rollout verify කරනවා

Image එක Jenkins build number එකෙන් tag වෙනවා:

    <registry-login-server>/jenkins-demo:<build-number>

Jenkinsfile එක image එක `linux/amd64` සඳහා build කරනවා:

    docker build \
      --platform linux/amd64 \
      -t "$REGISTRY_LOGIN_SERVER/$IMAGE_NAME:$BUILD_NUMBER" \
      app

Jenkins Apple Silicon machine එකක run වෙලා AKS nodes amd64 නම් මේක වැදගත්.

## Verify deployment

Pipeline success වුණාට පස්සේ local machine එකෙන් verify කරන්න:

    kubectl rollout status deployment/jenkins-demo -n practitioner-jenkins --timeout=180s
    kubectl get pods -n practitioner-jenkins -o wide
    kubectl get svc -n practitioner-jenkins

Service එක port-forward කරන්න:

    kubectl port-forward svc/jenkins-demo -n practitioner-jenkins 8089:80

Open කරන්න:

    http://localhost:8089

Expected page:

    Jenkins to AKS Lab
    This app was built and deployed by Jenkins.

## Troubleshooting

### Jenkins plugin download timeout

Plugin installation timeout error එකක් ආවොත්, `plugins.txt` use කරලා custom Jenkins image එක build කරන්න.

මෙම plugins preinstall වෙනවා:

    workflow-aggregator
    git
    credentials-binding
    pipeline-stage-view

### Docker socket permission denied

Jenkins Docker access කරද්දී මේ error එක ආවොත්:

    permission denied while trying to connect to the Docker daemon socket

Jenkins container එක මේ option එකෙන් run කරන්න:

    --user root

මෙය local learning lab එකට විතරයි.

### Local Git checkout blocked

Jenkins `file://` Git checkout block කළොත්:

    Checkout of Git remote file:///workspace/jenkins-aks-cicd-lab aborted

Jenkins මේ option එකෙන් run කරන්න:

    -e JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"

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
      --acr <acr-login-server>

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

ACR repository delete කරන්න:

    az acr repository delete \
      --name <acr-name> \
      --repository jenkins-demo \
      --yes

Jenkins stop කරලා remove කරන්න:

    docker rm -f jenkins-aks-lab

Jenkins volume remove කරන්න:

    docker volume rm jenkins_home_aks_lab

Optional local image cleanup:

    docker rmi jenkins-aks-lab:local
    docker image prune -f
    docker builder prune -f

## Security cleanup

Testing ඉවර වුණාම Jenkins වල use කළ temporary service principal secrets remove හෝ rotate කරන්න.

Secrets Git වලට commit කරන්න එපා.

Production සඳහා prefer කරන්න:

- Dedicated Jenkins agents
- Least privilege permissions
- Secret rotation
- OIDC or federated credentials where possible
- External secret managers
- Jenkins credentials with restricted access

## Important note

මෙය learning lab එකක්.

Jenkins root ලෙස run කිරීම සහ Docker socket mount කිරීම local lab එකකට acceptable වුණත් production සඳහා recommended නැහැ.

Production Jenkins setups වලදී dedicated build agents, hardened worker nodes, least privilege access, සහ stronger credential isolation use කරන්න.
