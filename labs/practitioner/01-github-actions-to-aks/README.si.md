# Practitioner Lab 01 - GitHub Actions to AKS

මෙම lab එකෙන් GitHub Actions use කරලා small web application image එකක් build කරලා, ඒ image එක Azure Container Registry වලට publish කරලා, AKS වලට deploy කරලා, Kubernetes Service එක හරහා deployed application එක respond වෙනවද verify කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone deployment lab එකක්.

මෙම lab එක use කරන්නේ:

- GitHub Actions run කරන්න පුළුවන් GitHub repository එකක්
- GitHub Actions workflow template එකක්
- Azure Container Registry
- AKS deployment
- Azure සහ registry access සඳහා GitHub repository secrets
- Deployed app එක locally test කරන්න `kubectl port-forward`

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `Build and deploy to AKS` කියන GitHub Actions workflow එකක්
- Azure Container Registry වලට push වුණු container image එකක්
- `practitioner-github-actions` කියන Kubernetes namespace එකක්
- `github-actions-demo` කියන deployment එකක්
- `github-actions-demo` කියන service එකක්
- `kubectl port-forward` හරහා test කළ working web page එකක්

මෙම lab එක application එක publicly expose කරන්නේ නැහැ.

Final application test එක ඔයාගේ laptop එකෙන් AKS තුළ තියෙන Kubernetes Service එකට temporary local tunnel එකක් use කරනවා:

    http://localhost:8084

Expected page text:

    GitHub Actions to AKS Lab
    This app was built and deployed by GitHub Actions.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- AKS deployment සඳහා GitHub Actions workflow එකක් prepare කරන විදිය
- GitHub repository secrets configure කරන විදිය
- GitHub Actions තුළ container image එකක් build කරන විදිය
- Container image එකක් Azure Container Registry වලට publish කරන විදිය
- Push කළ image එක ACR තුළ තියෙනවද verify කරන විදිය
- GitHub Actions තුළින් Azure වලට authenticate වෙන විදිය
- Workflow එකක් තුළ AKS credentials ලබාගන්න විදිය
- GitHub Actions හරහා Kubernetes manifests deploy කරන විදිය
- Kubernetes rollout verify කරන විදිය
- `kubectl port-forward` use කරලා deployed app එක test කරන විදිය
- AKS, ACR, සහ copied workflow resources clean up කරන විදිය

## Lab architecture

Flow එක:

    GitHub repository
      |
      v
    GitHub Actions workflow
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

GitHub Actions workflow එක මේ jobs use කරනවා:

    validate
      |
      v
    build-and-push
      |
      v
    deploy
      |
      v
    verify

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- GitHub account එකක්
- Workflow files add කරන්න සහ repository secrets configure කරන්න පුළුවන් GitHub repository එකක්
- Git
- Azure CLI
- kubectl
- Terminal එකක්
- Web browser එකක්
- AKS cluster එකක්
- Azure Container Registry
- CI/CD credentials සඳහා service principal එකක්

මෙම lab එක image එක build කරන්නේ GitHub-hosted runner එකක.

GitHub Actions workflow එක run කරන්න ඔයාගේ local machine එකේ Docker Desktop අවශ්‍ය නැහැ.

## GitHub repository requirement

GitHub Actions workflows GitHub repository එකක මේ path එක යටතේ තිබිය යුතුයි:

    .github/workflows/

මෙම lab එකට ඔයා own කරන හෝ maintain කරන repository එකක් use කරන්න.

ඔයාට මෙම learning repository එකේ own copy එකක් use කරන්න පුළුවන්.

ඔයා own හෝ maintain නොකරන repository එකකට lab workflow changes push කරන්න එපා.

Workflow template එක lab folder එකේ තියෙනවා:

    labs/practitioner/01-github-actions-to-aks/github-actions/build-deploy-aks.yaml

Lab එක කරන අතරතුර ඒ template එක මෙතනට copy කරනවා:

    .github/workflows/build-deploy-aks.yaml

Lab එක ඉවර වුණාට පස්සේ future pushes වලදී workflow එක run වෙන්න එපා නම් copied workflow එක remove කරන්න.

Lab folder එකේ තියෙන workflow template එක delete කරන්න එපා.

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

Workflow එක run කරන්න කලින් required Azure සහ registry values shared guide එකෙන් සකස් කරන්න:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

GitHub repository secrets සඳහා ඔයාට මේ values අවශ්‍යයි:

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

## Configure GitHub repository secrets

ඔයාගේ GitHub repository එකේ මෙතනට යන්න:

    Settings
    Secrets and variables
    Actions
    New repository secret

මෙම repository secrets create කරන්න:

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

Secret names workflow එකේ names සමඟ exact match වෙන්න ඕන.

Secrets Git වලට commit කරන්න එපා.

## Files in this lab

මෙම lab එකේ files:

    app/
      Static NGINX app files

    k8s/
      Kubernetes manifests

    github-actions/
      GitHub Actions workflow template

Files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    github-actions/build-deploy-aks.yaml

## Copy the workflow template

මෙම commands `terraform-azure-aks` repository root එකේ සිට run කරන්න.

GitHub Actions workflow folder එක create කරන්න:

    mkdir -p .github/workflows

Workflow template එක copy කරන්න:

    cp labs/practitioner/01-github-actions-to-aks/github-actions/build-deploy-aks.yaml \
      .github/workflows/build-deploy-aks.yaml

Copied workflow එක verify කරන්න:

    test -f .github/workflows/build-deploy-aks.yaml

## Review the workflow trigger

Workflow එක manual සහ push-based execution දෙකම support කරනවා:

    workflow_dispatch

සහ:

    push to main

Push trigger එක watch කරන්නේ:

    labs/practitioner/01-github-actions-to-aks/**
    .github/workflows/build-deploy-aks.yaml

ඒ කියන්නේ `main` branch එකේ lab files හෝ workflow file එකට changes push කළාම workflow එක run වෙන්න පුළුවන්.

GitHub Actions tab එකෙන් manually run කරන්නත් පුළුවන්.

## Commit the workflow to your own GitHub repository

GitHub Actions run වෙන්නේ GitHub repository එකකට committed workflows පමණයි.

Copied workflow සහ lab files ඔයාගේම repository එකට commit කරන්න:

    git add .github/workflows/build-deploy-aks.yaml
    git add labs/practitioner/01-github-actions-to-aks

    git commit -m "Add GitHub Actions AKS deployment lab"
    git push

ඔයා own හෝ maintain කරන repository එකකට විතරක් push කරන්න.

මේ lab workflow changes වෙන කෙනෙකුගේ repository එකකට push කරන්න එපා.

## Run the workflow

Browser එකෙන් ඔයාගේ GitHub repository එක open කරන්න.

මෙතනට යන්න:

    Actions
    Build and deploy to AKS

Workflow එක මේ ways දෙකෙන් එකකින් run කරන්න පුළුවන්:

Option 1, manual run:

    Run workflow
    Branch: main
    Run workflow

Option 2, push trigger:

    Workflow හෝ lab files change කරන commit එකක් main branch එකට push කරන්න.

Workflow එක මේ jobs run කරන්න ඕන:

    validate
    build-and-push
    deploy
    verify

## Verify the GitHub Actions run

Workflow run එක open කරලා each job succeeded ද check කරන්න:

    validate
    build-and-push
    deploy
    verify

`build-and-push` job එක image name සහ registry පෙන්වන්න ඕන.

`deploy` job එක namespace, deployment, සහ service apply කරන්න ඕන.

`verify` job එක target namespace එකේ pods සහ services පෙන්වන්න ඕන.

## Image tag

Workflow එක image එක GitHub commit SHA එකෙන් tag කරනවා.

Example:

    myacr.azurecr.io/practitioner-github-actions:<commit-sha>

Local commit SHA එක බලන්න:

    git rev-parse HEAD

Workflow එක GitHub Actions workflow run එකේ commit SHA එක use කරනවා.

## Verify image in Azure Container Registry

Workflow success වුණාට පස්සේ GitHub Actions image එක ACR වලට push කළාද verify කරන්න.

Repositories list කරන්න:

    az acr repository list \
      --name "$ACR_NAME" \
      --output table

Expected repository:

    practitioner-github-actions

Image tags list කරන්න:

    az acr repository show-tags \
      --name "$ACR_NAME" \
      --repository practitioner-github-actions \
      --output table

Expected:

    GitHub Actions commit SHA එකට match වෙන tag එකක් list වෙන්න ඕන.

## Verify deployment in AKS

Workflow success වුණාට පස්සේ Kubernetes resources verify කරන්න:

    kubectl get ns practitioner-github-actions
    kubectl get deployment github-actions-demo -n practitioner-github-actions
    kubectl get pods -n practitioner-github-actions -o wide
    kubectl get svc github-actions-demo -n practitioner-github-actions

Expected:

    namespace exists
    deployment shows available replicas
    pod status is Running
    service exists

Rollout check කරන්න:

    kubectl rollout status deployment/github-actions-demo -n practitioner-github-actions --timeout=180s

## Test the application with port-forward

මෙම lab එක public Azure URL එකක් create කරන්නේ නැහැ.

Kubernetes Service එක `kubectl port-forward` හරහා test කරනවා.

Port-forward එක ඔයාගේ laptop එකෙන් AKS තුළ run වෙන service එකට temporary local connection එකක් create කරනවා.

Service එක port-forward කරන්න:

    kubectl port-forward svc/github-actions-demo -n practitioner-github-actions 8084:80

ඔයාගේ laptop එකෙන් open කරන්න:

    http://localhost:8084

නැත්නම් වෙන terminal එකකින් curl test කරන්න:

    curl http://localhost:8084

Expected page text:

    GitHub Actions to AKS Lab
    This app was built and deployed by GitHub Actions.

Port-forward stop කරන්න `Ctrl+C` press කරන්න.

## Optional local manifest test

GitHub Actions workflow එක run කරන්න කලින් `IMAGE_PLACEHOLDER` එක public image එකකින් replace කරලා Kubernetes manifests locally test කරන්න පුළුවන්.

මෙම test එක Kubernetes manifests validate කරනවා, නමුත් GitHub Actions හෝ ACR image publishing test කරන්නේ නැහැ.

`terraform-azure-aks` repository root එකේ සිට run කරන්න:

    kubectl apply -f labs/practitioner/01-github-actions-to-aks/k8s/namespace.yaml

    sed "s|IMAGE_PLACEHOLDER|nginx:1.27-alpine|g" \
      labs/practitioner/01-github-actions-to-aks/k8s/deployment.yaml \
      | kubectl apply -f -

    kubectl apply -f labs/practitioner/01-github-actions-to-aks/k8s/service.yaml

Verify කරන්න:

    kubectl get pods -n practitioner-github-actions
    kubectl rollout status deployment/github-actions-demo -n practitioner-github-actions

Port-forward කරන්න:

    kubectl port-forward svc/github-actions-demo -n practitioner-github-actions 8084:80

Open කරන්න:

    http://localhost:8084

Port-forward stop කරන්න `Ctrl+C` press කරන්න.

Full workflow එක run කරන්න කලින් optional local manifest test cleanup කරන්න අවශ්‍ය නම්:

    kubectl delete namespace practitioner-github-actions --ignore-not-found

## Troubleshooting

### Workflow does not appear in the Actions tab

Workflow file එක root GitHub Actions folder එකේ තියෙනවද verify කරන්න:

    .github/workflows/build-deploy-aks.yaml

Lab folder එකේ workflow template එක තිබීම පමණක් ප්‍රමාණවත් නැහැ.

GitHub Actions run කරන්නේ මේ path එක යටතේ තියෙන workflow files පමණයි:

    .github/workflows/

### Workflow is not triggered by push

Workflow එක `main` branch එකට push කරන විට run වෙන්නේ මේ paths change වුණොත් පමණයි:

    labs/practitioner/01-github-actions-to-aks/**
    .github/workflows/build-deploy-aks.yaml

මෙහෙම manually run කරන්නත් පුළුවන්:

    Actions
    Build and deploy to AKS
    Run workflow

### Required file validation failed

`validate` job එක fail වුණොත්, lab files ඔයාගේ repository එකේ තියෙනවද verify කරන්න:

    labs/practitioner/01-github-actions-to-aks/app/Dockerfile
    labs/practitioner/01-github-actions-to-aks/k8s/namespace.yaml
    labs/practitioner/01-github-actions-to-aks/k8s/deployment.yaml
    labs/practitioner/01-github-actions-to-aks/k8s/service.yaml

### Docker login or image push failed

Docker login හෝ image push fail වුණොත් GitHub repository secrets verify කරන්න:

    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

Service principal එකට ACR වලට push කරන්න permission තියෙනවද බලන්න.

Learning setup එකකට service principal එකට registry එකේ `AcrPush` permission අවශ්‍ය වෙන්න සාමාන්‍යයි.

### Azure login failed

Azure login fail වුණොත් මේ GitHub repository secrets verify කරන්න:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID

Service principal secret expire වෙලා නැද්දත් බලන්න.

### AKS credentials failed

Workflow එකේ `az aks get-credentials` fail වුණොත් verify කරන්න:

    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME

Service principal එකට AKS cluster details read කරන්න permission තියෙනවදත් බලන්න.

### ImagePullBackOff

Pod එක `ImagePullBackOff` එකේ stuck නම්, AKS එකට ACR වලින් pull කරන්න පුළුවන්ද check කරන්න.

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

    kubectl get pods -n practitioner-github-actions -o wide
    kubectl describe pod -n practitioner-github-actions -l app=github-actions-demo
    kubectl get events -n practitioner-github-actions --sort-by=.lastTimestamp | tail -30

## Cleanup

AKS resources delete කරන්න:

    kubectl delete namespace practitioner-github-actions --ignore-not-found

මෙම lab එකෙන් create කළ ACR repository එක delete කරන්න:

    az acr repository delete \
      --name "$ACR_NAME" \
      --repository practitioner-github-actions \
      --yes

Workflow එක මෙම lab එකට විතරක් copy කළා නම්, root GitHub Actions folder එකෙන් remove කරන්න:

    rm -f .github/workflows/build-deploy-aks.yaml

Workflow template එක මෙතනින් delete කරන්න එපා:

    labs/practitioner/01-github-actions-to-aks/github-actions/

Workflow එක active තබාගන්න අවශ්‍ය නැත්නම්, cleanup change එක ඔයාගේ repository එකට commit සහ push කරන්න:

    git add .github/workflows/build-deploy-aks.yaml
    git commit -m "Remove GitHub Actions AKS lab workflow"
    git push

File එක already removed නම් `git add` වෙනුවට මේක අවශ්‍ය වෙන්න පුළුවන්:

    git add -u .github/workflows/build-deploy-aks.yaml

## Security cleanup

Testing ඉවර වුණාම GitHub repository secrets තුළ use කළ temporary service principal secrets remove හෝ rotate කරන්න.

Secrets Git වලට commit කරන්න එපා.

Long-lived credentials local notes හෝ screenshots වල store කරන්න එපා.

Production සඳහා prefer කරන්න:

- Long-lived client secrets වෙනුවට GitHub OIDC federation
- Least privilege permissions
- Short-lived credentials
- Secret rotation
- Environment protection rules
- Protected environments සඳහා required reviewers

## Important note

මෙය learning lab එකක්.

මෙම lab එක Azure service principal secret authentication use කරනවා, මොකද beginnersලාට ඒක තේරුම් ගන්න ලේසි.

Production-style GitHub Actions workflows සඳහා long-lived client secrets වෙනුවට GitHub OIDC federation prefer කරන්න.
