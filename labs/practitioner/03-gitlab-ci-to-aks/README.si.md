# Practitioner Lab 03 - GitLab CI/CD to AKS

මෙම lab එකෙන් GitLab CI/CD use කරලා small web application image එකක් build කරලා, ඒ image එක Azure Container Registry වලට publish කරලා, AKS වලට deploy කරලා, Kubernetes Service එක හරහා deployed application එක respond වෙනවද verify කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone deployment lab එකක්.

මෙම lab එක use කරන්නේ:

- CI/CD pipelines run කරන්න පුළුවන් GitLab project එකක්
- GitLab CI/CD pipeline template එකක්
- Azure Container Registry
- AKS deployment
- Azure සහ registry access සඳහා GitLab CI/CD variables
- Deployed app එක locally test කරන්න `kubectl port-forward`

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `.gitlab-ci.yml` use කරන GitLab pipeline එකක්
- Azure Container Registry වලට push වුණු container image එකක්
- `practitioner-gitlab-ci` කියන Kubernetes namespace එකක්
- `gitlab-ci-demo` කියන deployment එකක්
- `gitlab-ci-demo` කියන service එකක්
- `kubectl port-forward` හරහා test කළ working web page එකක්

මෙම lab එක application එක publicly expose කරන්නේ නැහැ.

Final application test එක ඔයාගේ laptop එකෙන් AKS තුළ තියෙන Kubernetes Service එකට temporary local tunnel එකක් use කරනවා:

    http://localhost:8085

Expected page text:

    GitLab CI/CD to AKS Lab
    This app was built and deployed by GitLab CI/CD.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- AKS deployment සඳහා GitLab CI/CD pipeline එකක් prepare කරන විදිය
- GitLab CI/CD variables configure කරන විදිය
- GitLab CI/CD තුළ container image එකක් build කරන විදිය
- Container image එකක් Azure Container Registry වලට publish කරන විදිය
- Push කළ image එක ACR තුළ තියෙනවද verify කරන විදිය
- GitLab CI/CD තුළින් Azure වලට authenticate වෙන විදිය
- Pipeline එකක් තුළ AKS credentials ලබාගන්න විදිය
- GitLab CI/CD හරහා Kubernetes manifests deploy කරන විදිය
- Kubernetes rollout verify කරන විදිය
- `kubectl port-forward` use කරලා deployed app එක test කරන විදිය
- AKS, ACR, සහ copied GitLab project resources clean up කරන විදිය

## Lab architecture

Flow එක:

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

GitLab pipeline එක මේ stages use කරනවා:

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

ඔයාට මේවා අවශ්‍යයි:

- GitLab account එකක්
- `.gitlab-ci.yml` add කරන්න සහ pipelines run කරන්න පුළුවන් GitLab project එකක්
- Git
- Azure CLI
- kubectl
- Terminal එකක්
- Web browser එකක්
- AKS cluster එකක්
- Azure Container Registry
- CI/CD credentials සඳහා service principal එකක්

මෙම lab එක image එක build කරන්නේ GitLab runner එකක.

GitLab pipeline එක run කරන්න ඔයාගේ local machine එකේ Docker Desktop අවශ්‍ය නැහැ.

## GitLab project requirement

GitLab CI/CD pipelines GitLab project root එකේ මෙම file එකෙන් detect වෙනවා:

    .gitlab-ci.yml

මෙම lab එකට ඔයා own කරන හෝ maintain කරන GitLab project එකක් use කරන්න.

ඔයා own හෝ maintain නොකරන project එකකට lab pipeline changes push කරන්න එපා.

Pipeline template එක lab folder එකේ තියෙනවා:

    labs/practitioner/03-gitlab-ci-to-aks/gitlab-ci/.gitlab-ci.yml

Lab එක කරන අතරතුර ඒ template එක GitLab project root එකට මෙහෙම copy කරනවා:

    .gitlab-ci.yml

Lab එක ඉවර වුණාට පස්සේ future pushes වලදී pipeline එක run වෙන්න එපා නම් copied pipeline file එක GitLab project එකෙන් remove කරන්න.

Lab folder එකේ තියෙන pipeline template එක delete කරන්න එපා.

## Install required local tools

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

Pipeline එක run කරන්න කලින් required Azure සහ registry values shared guide එකෙන් සකස් කරන්න:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

GitLab CI/CD variables සඳහා ඔයාට මේ values අවශ්‍යයි:

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

## Configure GitLab CI/CD variables

ඔයාගේ GitLab project එකේ මෙතනට යන්න:

    Settings
    CI/CD
    Variables
    Add variable

මෙම variables create කරන්න:

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

Secret values සඳහා:

    Masked: yes

මෙම learning lab එකට:

    Protected: no

Protected variables use කරන්න branch එක protected නම් විතරයි.

Variable names pipeline එක සමඟ exact match වෙන්න ඕන.

Secrets Git වලට commit කරන්න එපා.

## Files in this lab

මෙම lab එකේ files:

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

මෙම commands `terraform-azure-aks` repository root එකේ සිට run කරන්න.

ඔයාගේ GitLab project clone එකට local path එකක් set කරන්න:

    GITLAB_PROJECT_DIR="<path-to-your-gitlab-project>"

Example:

    GITLAB_PROJECT_DIR="$HOME/terraform-azure-aks-labs/aks-gitlab-cicd-lab"

GitLab project එකේ folders create කරන්න:

    mkdir -p "$GITLAB_PROJECT_DIR/app"
    mkdir -p "$GITLAB_PROJECT_DIR/k8s"

Lab files copy කරන්න:

    cp labs/practitioner/03-gitlab-ci-to-aks/app/* "$GITLAB_PROJECT_DIR/app/"
    cp labs/practitioner/03-gitlab-ci-to-aks/k8s/* "$GITLAB_PROJECT_DIR/k8s/"
    cp labs/practitioner/03-gitlab-ci-to-aks/gitlab-ci/.gitlab-ci.yml "$GITLAB_PROJECT_DIR/.gitlab-ci.yml"

GitLab project structure එක verify කරන්න:

    find "$GITLAB_PROJECT_DIR" -maxdepth 3 -type f | sort

Expected files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    .gitlab-ci.yml

## Commit the pipeline to your own GitLab project

GitLab CI/CD run වෙන්නේ GitLab project එකකට committed pipelines පමණයි.

ඔයාගේ GitLab project clone එකට move වෙන්න:

    cd "$GITLAB_PROJECT_DIR"

Copied app, manifests, සහ pipeline file commit කරන්න:

    git add app k8s .gitlab-ci.yml
    git commit -m "Add GitLab CI/CD AKS deployment lab"
    git push

ඔයා own හෝ maintain කරන GitLab project එකකට විතරක් push කරන්න.

මේ lab pipeline changes වෙන කෙනෙකුගේ project එකකට push කරන්න එපා.

## Run the pipeline

Browser එකෙන් ඔයාගේ GitLab project එක open කරන්න.

මෙතනට යන්න:

    Build
    Pipelines

Project එකට push කළාම pipeline එක run වෙන්න පුළුවන්.

Manually run කරන්න අවශ්‍ය නම්:

    Run pipeline

Pipeline එක මේ stages run කරන්න ඕන:

    validate
    build_push
    deploy
    verify

## Verify the GitLab pipeline run

Pipeline එක open කරලා each stage succeeded ද check කරන්න:

    validate
    build_push
    deploy
    verify

`build_push` stage එක registry එකට login වෙලා image build කරලා push කරන්න ඕන.

`deploy` stage එක namespace, deployment, සහ service apply කරන්න ඕන.

`verify` stage එක target namespace එකේ pods සහ services පෙන්වන්න ඕන.

## Image tag

Pipeline එක image එක GitLab commit SHA එකෙන් tag කරනවා.

Example:

    myacr.azurecr.io/gitlab-ci-demo:<commit-sha>

ඔයාගේ GitLab project clone එකේ local commit SHA එක බලන්න:

    git rev-parse HEAD

Pipeline එක GitLab CI pipeline run එකේ commit SHA එක use කරනවා:

    $CI_COMMIT_SHA

## Image platform note

Pipeline එක image එක `linux/amd64` සඳහා build කරනවා:

    docker build --platform linux/amd64 -t "$REGISTRY_LOGIN_SERVER/$IMAGE_NAME:$CI_COMMIT_SHA" app

මෙය වැදගත්, මොකද බොහෝ AKS node pools amd64 nodes use කරනවා.

Runner එක ARM hardware එකක run වෙන විට image platform mismatch avoid කරන්නත් මෙය උදව් වෙනවා.

## Verify image in Azure Container Registry

Pipeline success වුණාට පස්සේ GitLab image එක ACR වලට push කළාද verify කරන්න.

Repositories list කරන්න:

    az acr repository list \
      --name "$ACR_NAME" \
      --output table

Expected repository:

    gitlab-ci-demo

Image tags list කරන්න:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository gitlab-ci-demo \
      --output table

Expected:

    GitLab commit SHA එකට match වෙන tag එකක් list වෙන්න ඕන.

## Verify deployment in AKS

Pipeline success වුණාට පස්සේ Kubernetes resources verify කරන්න:

    kubectl get ns practitioner-gitlab-ci
    kubectl get deployment gitlab-ci-demo -n practitioner-gitlab-ci
    kubectl get pods -n practitioner-gitlab-ci -o wide
    kubectl get svc gitlab-ci-demo -n practitioner-gitlab-ci

Expected:

    namespace exists
    deployment shows available replicas
    pod status is Running
    service exists

Rollout check කරන්න:

    kubectl rollout status deployment/gitlab-ci-demo -n practitioner-gitlab-ci --timeout=180s

## Test the application with port-forward

මෙම lab එක public Azure URL එකක් create කරන්නේ නැහැ.

Kubernetes Service එක `kubectl port-forward` හරහා test කරනවා.

Port-forward එක ඔයාගේ laptop එකෙන් AKS තුළ run වෙන service එකට temporary local connection එකක් create කරනවා.

Service එක port-forward කරන්න:

    kubectl port-forward svc/gitlab-ci-demo -n practitioner-gitlab-ci 8085:80

ඔයාගේ laptop එකෙන් open කරන්න:

    http://localhost:8085

නැත්නම් වෙන terminal එකකින් curl test කරන්න:

    curl http://localhost:8085

Expected page text:

    GitLab CI/CD to AKS Lab
    This app was built and deployed by GitLab CI/CD.

Port-forward stop කරන්න `Ctrl+C` press කරන්න.

## Troubleshooting

### Pipeline does not start

GitLab project root එකේ `.gitlab-ci.yml` තියෙනවද verify කරන්න:

    .gitlab-ci.yml

Lab folder එකේ pipeline template එක තිබීම පමණක් ප්‍රමාණවත් නැහැ.

GitLab project root එකේ `.gitlab-ci.yml` file එකෙන් pipelines detect කරනවා.

### Required file validation failed

`validate` stage එක fail වුණොත්, GitLab project එකේ මෙම files තියෙනවද verify කරන්න:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml

### Docker login or image push failed

Docker login හෝ image push fail වුණොත් GitLab CI/CD variables verify කරන්න:

    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Service principal එකට ACR වලට push කරන්න permission තියෙනවද බලන්න.

Learning setup එකකට service principal එකට registry එකේ `AcrPush` permission අවශ්‍ය වෙන්න සාමාන්‍යයි.

### Azure login failed

Azure login fail වුණොත් මේ GitLab CI/CD variables verify කරන්න:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID

Service principal secret expire වෙලා නැද්දත් බලන්න.

### AKS credentials failed

Pipeline එකේ `az aks get-credentials` fail වුණොත් verify කරන්න:

    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME

Service principal එකට AKS cluster details read කරන්න permission තියෙනවදත් බලන්න.

### ImagePullBackOff with platform mismatch

Pod එකේ මේ error එක පේනවා නම්:

    no match for platform in manifest

Pipeline එක image build කරන්න මේ option එක use කරනවද බලන්න:

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

    kubectl get pods -n practitioner-gitlab-ci -o wide
    kubectl describe pod -n practitioner-gitlab-ci -l app=gitlab-ci-demo
    kubectl get events -n practitioner-gitlab-ci --sort-by=.lastTimestamp | tail -30

## Cleanup

AKS resources delete කරන්න:

    kubectl delete namespace practitioner-gitlab-ci --ignore-not-found

මෙම lab එකෙන් create කළ ACR repository එක delete කරන්න:

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository gitlab-ci-demo \
      --yes

Files මෙම lab එකට විතරක් copy කළා නම්, ඒවා ඔයාගේ GitLab project clone එකෙන් remove කරන්න:

    cd "$GITLAB_PROJECT_DIR"

    rm -rf app k8s .gitlab-ci.yml

Pipeline එක active තබාගන්න අවශ්‍ය නැත්නම්, cleanup change එක ඔයාගේ GitLab project එකට commit සහ push කරන්න:

    git add -A app k8s .gitlab-ci.yml
    git commit -m "Remove GitLab CI/CD AKS deployment lab files"
    git push

Lab templates මෙතනින් delete කරන්න එපා:

    labs/practitioner/03-gitlab-ci-to-aks/

## Security cleanup

Testing ඉවර වුණාම GitLab CI/CD variables තුළ use කළ temporary service principal secrets remove හෝ rotate කරන්න.

Secrets Git වලට commit කරන්න එපා.

Long-lived credentials local notes හෝ screenshots වල store කරන්න එපා.

Production සඳහා prefer කරන්න:

- Least privilege permissions
- Short-lived credentials
- Secret rotation
- OIDC or federated credentials where possible
- Protected variables
- Protected branches
- Environment approvals

## Important note

මෙය learning lab එකක්.

මෙම lab එක Azure service principal secret authentication use කරනවා, මොකද beginnersලාට ඒක තේරුම් ගන්න ලේසි.

Production-style GitLab CI/CD workflows සඳහා least privilege identity, protected variables, protected branches, environment approvals, සහ short-lived credentials prefer කරන්න.
