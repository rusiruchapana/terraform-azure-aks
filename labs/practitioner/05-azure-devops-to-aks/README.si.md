# Practitioner Lab 05 - Azure DevOps to AKS

මෙම lab එකෙන් Azure DevOps Pipelines use කරලා backend සහ frontend application images build කරලා, images දෙකම Azure Container Registry වලට publish කරලා, 3-tier application එකක් AKS වලට deploy කරලා, Kubernetes Service එකක් හරහා application එක වැඩ කරනවද verify කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone deployment lab එකක්.

මෙම lab එක 3-tier Node.js sample application එකක් use කරනවා:

- MySQL database
- Node.js backend API
- NGINX හරහා serve කරන React frontend
- Frontend සිට backend service එකට NGINX reverse proxy

Frontend එක browser requests `/api` සහ `/health` සඳහා cluster එක ඇතුළේ backend service එකට route කරනවා.

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `azure-pipelines.yml` use කරන Azure DevOps pipeline එකක්
- Azure Container Registry වලට push වුණු backend image එකක්
- Azure Container Registry වලට push වුණු frontend image එකක්
- `practitioner-azure-devops` කියන Kubernetes namespace එකක්
- MySQL deployment සහ service
- Backend deployment සහ service
- Frontend deployment සහ service
- `kubectl port-forward` හරහා test කළ working frontend proxy එකක්

මෙම lab එක application එක publicly expose කරන්නේ නැහැ.

Final application test එක ඔයාගේ laptop එකෙන් AKS තුළ තියෙන frontend Kubernetes Service එකට temporary local tunnel එකක් use කරනවා:

    http://localhost:8087

Expected health response:

    {"status":"UP","database":"CONNECTED"}

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- AKS deployment සඳහා Azure DevOps pipeline එකක් prepare කරන විදිය
- Azure DevOps pipeline variables configure කරන විදිය
- Backend සහ frontend container images build කරන විදිය
- Images දෙකම Azure Container Registry වලට publish කරන විදිය
- Push කළ images ACR තුළ තියෙනවද verify කරන විදිය
- Azure DevOps Pipelines තුළින් Azure වලට authenticate වෙන විදිය
- Pipeline එකක් තුළ AKS credentials ලබාගන්න විදිය
- MySQL, backend, සහ frontend Kubernetes manifests deploy කරන විදිය
- Kubernetes rollouts verify කරන විදිය
- `kubectl port-forward` use කරලා deployed app එක test කරන විදිය
- AKS, ACR, සහ copied app repository resources clean up කරන විදිය

## Lab architecture

Flow එක:

    Azure DevOps project
      |
      v
    Azure DevOps Pipeline
      |
      v
    Validate files
      |
      v
    Build backend image
      |
      v
    Build frontend image
      |
      v
    Push images to Azure Container Registry
      |
      v
    Azure login
      |
      v
    AKS credentials
      |
      v
    Deploy MySQL
      |
      v
    Deploy backend API
      |
      v
    Deploy frontend
      |
      v
    Rollout verification
      |
      v
    Port-forward frontend service
      |
      v
    Browser or curl test

Azure DevOps pipeline එක මේ stages use කරනවා:

    Validate
      |
      v
    BuildPush
      |
      v
    Deploy
      |
      v
    Verify

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- Azure DevOps account එකක්
- Pipelines create/run කරන්න පුළුවන් Azure DevOps project එකක්
- Azure DevOps Pipelines වලට connected Git repository එකක්
- Git
- Azure CLI
- kubectl
- Terminal එකක්
- Web browser එකක්
- AKS cluster එකක්
- Azure Container Registry
- CI/CD credentials සඳහා service principal එකක්

මෙම lab එක images build කරන්නේ Azure DevOps pipeline agent එකක.

Optional local backend validation run කරන්න අවශ්‍ය නැත්නම් local machine එකේ Docker Desktop අවශ්‍ය නැහැ.

## Azure DevOps project and repository requirement

Azure DevOps Pipelines මේ sources වලින් run කරන්න පුළුවන්:

- Azure Repos Git
- Azure Pipelines වලට connected GitHub

මෙම lab එකට ඔයා own කරන හෝ maintain කරන repository එකක් use කරන්න.

ඔයා own හෝ maintain නොකරන repository එකකට lab pipeline changes push කරන්න එපා.

Pipeline template එක lab folder එකේ තියෙනවා:

    labs/practitioner/05-azure-devops-to-aks/azure-pipelines/azure-pipelines.yml

Lab එක කරන අතරතුර ඒ template එක app repository root එකට මෙහෙම copy කරනවා:

    azure-pipelines.yml

Lab එක ඉවර වුණාට පස්සේ future pushes වලදී pipeline එක run වෙන්න එපා නම් copied pipeline file එක app repository එකෙන් remove කරන්න.

Lab folder එකේ තියෙන pipeline template එක delete කරන්න එපා.

## App source

මෙම lab එක application source ලෙස වෙනම 3-tier Node.js sample app repository එකක් use කරනවා.

Sample app repository:

    https://github.com/andrewferdinandus/3-tier-nodeapp

මෙම lab එකට sample app repository එකේ ඔයාගේ own copy එකක් use කරන්න.

Learning platform repository එක lab template සහ reference files පමණක් store කරනවා.

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

### Docker Desktop for optional local validation

Docker Desktop මෙම lab එකට optional.

Optional local backend container test එක run කරන්න ඕන නම් විතරක් Docker Desktop අවශ්‍යයි.

Docker Desktop install කරන්න:

    https://www.docker.com/products/docker-desktop/

Docker verify කරන්න:

    docker version

## Check local tools and Azure access

Continue කරන්න කලින් verify කරන්න:

    git --version
    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
    kubectl version --client

ඔයාගේ AKS සහ ACR names set කරන්න:

    AZURE_RESOURCE_GROUP="<your-resource-group>"
    AKS_CLUSTER_NAME="<your-aks-cluster-name>"
    ACR_NAME="<your-acr-name>"

AKS access verify කරන්න:

    az aks get-credentials \
      --resource-group "$AZURE_RESOURCE_GROUP" \
      --name "$AKS_CLUSTER_NAME" \
      --overwrite-existing

    kubectl get nodes

ACR verify කරන්න:

    az acr show \
      --name "$ACR_NAME" \
      --query "{name:name, loginServer:loginServer}" \
      -o table

## Find your Azure values

Azure DevOps pipeline variables සඳහා අවශ්‍ය values හොයාගන්න මේ commands use කරන්න.

Resource groups list කරන්න:

    az group list --query "[].name" -o table

AKS clusters list කරන්න:

    az aks list --query "[].{name:name, resourceGroup:resourceGroup}" -o table

Azure Container Registries list කරන්න:

    az acr list --query "[].{name:name, resourceGroup:resourceGroup, loginServer:loginServer}" -o table

ඔයාගේ values set කරන්න:

    AZURE_RESOURCE_GROUP="<your-resource-group>"
    AKS_CLUSTER_NAME="<your-aks-cluster-name>"
    ACR_NAME="<your-acr-name>"

ACR login server එක ගන්න:

    REGISTRY_LOGIN_SERVER="$(az acr show \
      --name "$ACR_NAME" \
      --query loginServer \
      -o tsv)"

Verify කරන්න:

    echo "$AZURE_RESOURCE_GROUP"
    echo "$AKS_CLUSTER_NAME"
    echo "$ACR_NAME"
    echo "$REGISTRY_LOGIN_SERVER"

වෙන environment එකක values copy කරන්න එපා.

ඔයාගේම Azure subscription එකේ values use කරන්න.

## Prepare Azure CI/CD variables

මෙම lab එක AKS වලට deploy කරනවා සහ images Azure Container Registry වලට publish කරනවා.

Pipeline එක run කරන්න කලින් required Azure සහ registry values shared guide එකෙන් සකස් කරන්න:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

Azure DevOps pipeline variables සඳහා ඔයාට මේ values අවශ්‍යයි:

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

## Configure Azure DevOps pipeline variables

Azure DevOps වල මෙතනට යන්න:

    Pipelines
    Select your pipeline
    Edit
    Variables

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

මෙම variables secret ලෙස mark කරන්න:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

Variable names pipeline එක සමඟ exact match වෙන්න ඕන.

Secrets Git වලට commit කරන්න එපා.

## Files in this lab

මෙම lab එකේ files:

    backend/Dockerfile
      Backend image එක build කරන්න use කරන Dockerfile

    frontend/Dockerfile
      React frontend image එක build කරන්න use කරන Dockerfile

    frontend/nginx.conf
      Frontend-to-backend traffic සඳහා NGINX reverse proxy configuration

    k8s/
      MySQL, backend, සහ frontend සඳහා Kubernetes manifests

    azure-pipelines/
      Azure DevOps pipeline template

Files:

    backend/Dockerfile
    frontend/Dockerfile
    frontend/nginx.conf
    k8s/namespace.yaml
    k8s/mysql-secret.yaml
    k8s/mysql-init-configmap.yaml
    k8s/mysql-pvc.yaml
    k8s/mysql-deployment.yaml
    k8s/mysql-service.yaml
    k8s/backend-deployment.yaml
    k8s/backend-service.yaml
    k8s/frontend-deployment.yaml
    k8s/frontend-service.yaml
    azure-pipelines/azure-pipelines.yml

## Copy files into the app repository

මෙම commands `terraform-azure-aks` repository root එකේ සිට run කරන්න.

ඔයාගේ 3-tier app repository clone එකට local path එකක් set කරන්න:

    APP_REPO_DIR="<path-to-your-3-tier-nodeapp-repo>"

Example:

    APP_REPO_DIR="$HOME/terraform-azure-aks-labs/3-tier-nodeapp"

App repository එකේ folders create කරන්න:

    mkdir -p "$APP_REPO_DIR/backend"
    mkdir -p "$APP_REPO_DIR/frontend"
    mkdir -p "$APP_REPO_DIR/k8s"

Lab files copy කරන්න:

    cp labs/practitioner/05-azure-devops-to-aks/backend/Dockerfile "$APP_REPO_DIR/backend/Dockerfile"
    cp labs/practitioner/05-azure-devops-to-aks/frontend/Dockerfile "$APP_REPO_DIR/frontend/Dockerfile"
    cp labs/practitioner/05-azure-devops-to-aks/frontend/nginx.conf "$APP_REPO_DIR/frontend/nginx.conf"
    cp labs/practitioner/05-azure-devops-to-aks/k8s/* "$APP_REPO_DIR/k8s/"
    cp labs/practitioner/05-azure-devops-to-aks/azure-pipelines/azure-pipelines.yml "$APP_REPO_DIR/azure-pipelines.yml"

App repository structure එක verify කරන්න:

    find "$APP_REPO_DIR" -maxdepth 3 -type f | sort

Expected important files:

    backend/Dockerfile
    backend/package.json
    backend/package-lock.json
    backend/server.js
    frontend/Dockerfile
    frontend/nginx.conf
    frontend/package.json
    frontend/src/App.js
    k8s/namespace.yaml
    k8s/mysql-secret.yaml
    k8s/mysql-init-configmap.yaml
    k8s/mysql-pvc.yaml
    k8s/mysql-deployment.yaml
    k8s/mysql-service.yaml
    k8s/backend-deployment.yaml
    k8s/backend-service.yaml
    k8s/frontend-deployment.yaml
    k8s/frontend-service.yaml
    azure-pipelines.yml

## Update frontend backend paths

Frontend එක backend එක call කරන්න ඕන NGINX reverse proxy හරහා.

Frontend app එකේ relative backend paths use කරන්න:

    const BACKEND_URL = '/api';

Health checks සඳහා:

    fetch('/health');

මෙයින් frontend service එක cluster එක ඇතුළේ backend service එකට requests proxy කරනවා.

## Commit the pipeline to your app repository

Azure DevOps Pipelines run වෙන්නේ connected repository එකට committed pipeline files වලින් පමණයි.

ඔයාගේ app repository clone එකට move වෙන්න:

    cd "$APP_REPO_DIR"

Copied Dockerfiles, manifests, NGINX config, සහ pipeline file commit කරන්න:

    git add backend/Dockerfile frontend/Dockerfile frontend/nginx.conf k8s azure-pipelines.yml
    git commit -m "Add Azure DevOps AKS deployment lab"
    git push

ඔයා own හෝ maintain කරන repository එකකට විතරක් push කරන්න.

මේ lab pipeline changes වෙන කෙනෙකුගේ repository එකකට push කරන්න එපා.

## Create or connect the Azure DevOps pipeline

Azure DevOps වල:

    Pipelines
    New pipeline

ඔයාගේ repository source එක තෝරන්න:

    Azure Repos Git

හෝ:

    GitHub

App repository එක select කරන්න.

Existing YAML pipeline තෝරන්න.

YAML path එක set කරන්න:

    azure-pipelines.yml

Pipeline එක save කරලා run කරන්න.

## Run the pipeline

Pipeline එක මේ stages run කරන්න ඕන:

    Validate
    BuildPush
    Deploy
    Verify

Pipeline run එක open කරලා each stage succeeds ද check කරන්න.

## Verify the Azure DevOps pipeline run

`Validate` stage එක required files තියෙනවද confirm කරන්න ඕන.

`BuildPush` stage එක images දෙකම build සහ push කරන්න ඕන:

    node-backend
    node-frontend

`Deploy` stage එක MySQL, backend, සහ frontend resources apply කරන්න ඕන.

`Verify` stage එක backend සහ frontend deployments වල rollout status පෙන්වන්න ඕන.

## Image tag

Pipeline එක Azure DevOps source version එකෙන් images tag කරනවා:

    $(Build.SourceVersion)

Example:

    myacr.azurecr.io/node-backend:<commit-sha>
    myacr.azurecr.io/node-frontend:<commit-sha>

## Image platform note

Pipeline එක images දෙකම `linux/amd64` සඳහා build කරනවා.

මෙය වැදගත්, මොකද බොහෝ AKS node pools amd64 nodes use කරනවා.

Agent එක ARM hardware එකක run වෙන විට image platform mismatch avoid කරන්නත් මෙය උදව් වෙනවා.

## Verify images in Azure Container Registry

Pipeline success වුණාට පස්සේ Azure DevOps images දෙකම ACR වලට push කළාද verify කරන්න.

Repositories list කරන්න:

    az acr repository list \
      --name "$ACR_NAME" \
      --output table

Expected repositories:

    node-backend
    node-frontend

Backend image tags list කරන්න:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository node-backend \
      --output table

Frontend image tags list කරන්න:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository node-frontend \
      --output table

Expected:

    Azure DevOps source version එකට match වෙන tag එකක් each repository එකේ list වෙන්න ඕන.

## Verify deployment in AKS

Pipeline success වුණාට පස්සේ Kubernetes resources verify කරන්න:

    kubectl get ns practitioner-azure-devops
    kubectl get pods -n practitioner-azure-devops -o wide
    kubectl get svc -n practitioner-azure-devops
    kubectl get pvc -n practitioner-azure-devops

Rollouts check කරන්න:

    kubectl rollout status deployment/mysql -n practitioner-azure-devops --timeout=180s
    kubectl rollout status deployment/node-backend -n practitioner-azure-devops --timeout=180s
    kubectl rollout status deployment/node-frontend -n practitioner-azure-devops --timeout=180s

Expected:

    MySQL pod is Running
    backend pod is Running
    frontend pod is Running
    services exist
    PVC is Bound

## Test the application with port-forward

මෙම lab එක public Azure URL එකක් create කරන්නේ නැහැ.

Frontend Kubernetes Service එක `kubectl port-forward` හරහා test කරනවා.

Port-forward එක ඔයාගේ laptop එකෙන් AKS තුළ run වෙන frontend service එකට temporary local connection එකක් create කරනවා.

Frontend service එක port-forward කරන්න:

    kubectl port-forward svc/node-frontend -n practitioner-azure-devops 8087:80

Frontend proxy හරහා health test කරන්න:

    curl http://localhost:8087/health

Expected:

    {"status":"UP","database":"CONNECTED"}

Frontend proxy හරහා tasks API test කරන්න:

    curl http://localhost:8087/api/tasks

ඔයාගේ laptop එකෙන් open කරන්න:

    http://localhost:8087

Port-forward stop කරන්න `Ctrl+C` press කරන්න.

## Optional local backend validation

මෙම optional test එකට Docker Desktop සහ reachable local database එකක් අවශ්‍යයි.

App repository clone එකේ සිට run කරන්න:

    cd "$APP_REPO_DIR"

Backend image එක build කරන්න:

    docker build --platform linux/amd64 -t node-backend-test backend

Backend container එක run කරන්න:

    docker run --rm -p 5002:5000 \
      -e DB_HOST=host.docker.internal \
      -e DB_USER=root \
      -e DB_PASSWORD=password \
      -e DB_NAME=devops_db \
      node-backend-test

Health test කරන්න:

    curl http://localhost:5002/health

Local database එක available නම් expected output:

    {"status":"UP","database":"CONNECTED"}

## Troubleshooting

### Pipeline does not start

Connected app repository root එකේ `azure-pipelines.yml` තියෙනවද verify කරන්න:

    azure-pipelines.yml

Lab folder එකේ pipeline template එක තිබීම පමණක් ප්‍රමාණවත් නැහැ.

Azure DevOps connected repository එකේ pipeline file එක use කරනවා.

### Docker build uses old Dockerfile

Azure DevOps තවම old Dockerfile commands run කරනවා නම්, connected repository එක outdated විය හැකියි.

Fix:

- Latest code connected repository එකට push කරන්න
- Azure DevOps pipeline එක correct repository සහ branch එකට connected ද confirm කරන්න
- Azure Repos GitHub repository copy එකක් ලෙස use කරනවා නම්, Azure Repos copy එක update කරන්න

### Docker login or image push failed

Docker login හෝ image push fail වුණොත් Azure DevOps pipeline variables verify කරන්න:

    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Service principal එකට ACR වලට push කරන්න permission තියෙනවද බලන්න.

Learning setup එකකට service principal එකට registry එකේ `AcrPush` permission අවශ්‍ය වෙන්න සාමාන්‍යයි.

### Azure login failed

Azure login fail වුණොත් මේ Azure DevOps pipeline variables verify කරන්න:

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

### kubectl command not found

Azure CLI image එකේ kubectl නැති විය හැකියි.

මෙම pipeline එක kubectl commands run කරන්න කලින් මේක use කරනවා:

    az aks install-cli

### ImagePullBackOff with platform mismatch

Pod එකේ මේ error එක පේනවා නම්:

    no match for platform in manifest

Pipeline එක images build කරන්න මේ platform එක use කරනවද බලන්න:

    linux/amd64

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

### Backend readiness probe fails

Backend health endpoint එක MySQL connectivity check කරනවා.

MySQL ready නැත්නම් backend pod එක Ready වෙන්න ටිකක් වෙලා යන්න පුළුවන්.

Check කරන්න:

    kubectl get pods -n practitioner-azure-devops
    kubectl logs deployment/mysql -n practitioner-azure-devops
    kubectl logs deployment/node-backend -n practitioner-azure-devops

### Rollout timeout

Rollout timeout වුණොත් pods සහ events inspect කරන්න:

    kubectl get pods -n practitioner-azure-devops -o wide
    kubectl describe pod -n practitioner-azure-devops -l app=node-backend
    kubectl describe pod -n practitioner-azure-devops -l app=node-frontend
    kubectl get events -n practitioner-azure-devops --sort-by=.lastTimestamp | tail -30

## Cleanup

AKS resources delete කරන්න:

    kubectl delete namespace practitioner-azure-devops --ignore-not-found

මෙයින් මෙම lab එකෙන් create කළ MySQL, backend, frontend, services, ConfigMaps, Secrets, සහ PVC resources remove වෙනවා.

මෙම lab එකෙන් create කළ ACR repositories delete කරන්න:

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository node-backend \
      --yes

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository node-frontend \
      --yes

Files මෙම lab එකට විතරක් copy කළා නම්, ඒවා app repository clone එකෙන් remove කරන්න:

    cd "$APP_REPO_DIR"

    rm -rf k8s azure-pipelines.yml
    rm -f backend/Dockerfile
    rm -f frontend/Dockerfile
    rm -f frontend/nginx.conf

Pipeline එක active තබාගන්න අවශ්‍ය නැත්නම්, cleanup change එක ඔයාගේ app repository එකට commit සහ push කරන්න:

    git add -A backend/Dockerfile frontend/Dockerfile frontend/nginx.conf k8s azure-pipelines.yml
    git commit -m "Remove Azure DevOps AKS deployment lab files"
    git push

Lab templates මෙතනින් delete කරන්න එපා:

    labs/practitioner/05-azure-devops-to-aks/

## Security cleanup

Testing ඉවර වුණාම Azure DevOps pipeline variables තුළ use කළ temporary service principal secrets remove හෝ rotate කරන්න.

Secrets Git වලට commit කරන්න එපා.

Long-lived credentials local notes හෝ screenshots වල store කරන්න එපා.

Production සඳහා prefer කරන්න:

- Least privilege permissions
- Short-lived credentials
- Secret rotation
- OIDC or federated credentials where possible
- Pipeline variable groups with restricted access
- Protected branches
- Environment approvals

## Important note

මෙය learning lab එකක්.

මෙම lab එක Azure service principal secret authentication use කරනවා, මොකද beginnersලාට ඒක තේරුම් ගන්න ලේසි.

Production-style Azure DevOps pipelines සඳහා least privilege identity, protected variables, protected branches, environment approvals, සහ short-lived credentials prefer කරන්න.
