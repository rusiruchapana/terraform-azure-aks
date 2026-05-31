# Practitioner Lab 05 - Azure DevOps to AKS

මෙම lab එකෙන් Azure DevOps Pipelines use කරලා backend සහ frontend container images build කරලා Azure Container Registry එකට push කරලා, full 3-tier application එකක් AKS වලට deploy කරන flow එක ඉගෙන ගන්නවා.

මෙම lab එක real-world sample app එකක් use කරනවා:

    https://github.com/andrewferdinandus/3-tier-nodeapp

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Azure DevOps pipeline stages
- Node.js backend Docker image build කිරීම
- React frontend Docker image build කිරීම
- Images ACR එකට push කිරීම
- MySQL AKS වල deploy කිරීම
- Backend API AKS වල deploy කිරීම
- Frontend AKS වල deploy කිරීම
- Kubernetes Secrets, ConfigMaps, PVCs, Deployments, Services use කිරීම
- Azure DevOps pipeline එකෙන් rollout verify කිරීම
- Frontend හරහා backend API test කිරීම

## Lab scope

මෙම lab එක full 3-tier application එකක් deploy කරනවා:

- MySQL database
- Node.js backend API
- React frontend served by NGINX

Frontend එක NGINX reverse proxy එකක් use කරනවා. ඒ නිසා browser requests `/api` සහ `/health` වලට යනවිට ඒවා cluster එක ඇතුළේ backend service එකට route වෙනවා.

## App source

Application source code එක වෙනම repository එකක තියෙනවා:

    3-tier-nodeapp

Platform repository එකේ තියෙන්නේ lab template සහ reference files.

මෙම separation එක හොඳයි, මොකද platform repo එක infra/labs/documentation සඳහා තියාගෙන app repo එක application code සඳහා තියාගන්න පුළුවන්.

## Required Azure DevOps setup

Azure DevOps project එකක් create කරලා තියෙන්න ඕන.

Recommended project name:

    aks-azure-devops-cicd-lab

ඔබට use කරන්න පුළුවන්:

- Azure Repos Git
- GitHub connected to Azure Pipelines

ඔබ GitHub repo එකක් Azure Repos වලට copy කරලා use කරනවා නම්, GitHub update කළ පසු Azure Repos copy එකත් update කරන්න ඕන. නැත්නම් pipeline එක old code එක build කරන්න පුළුවන්.

## Prepare Azure CI/CD variables

මෙම lab එක AKS වලට deploy කරනවා සහ images registry එකට push කරනවා.

Pipeline run කරන්න කලින් required Azure සහ registry values shared guide එකෙන් සකස් කරන්න:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

මෙම guide එකෙන් Azure login, subscription ID, tenant ID, service principal, ACR login server, සහ registry credentials හදාගන්න විදිය explain කරනවා.

## Required pipeline variables

Azure DevOps pipeline variables add කරන්න:

    Pipelines -> select pipeline -> Edit -> Variables

Variables:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

For this platform example:

    AZURE_RESOURCE_GROUP = rg-aks-dev-001
    AKS_CLUSTER_NAME = aks-dev-001
    REGISTRY_LOGIN_SERVER = acraksdev001andrew.azurecr.io

For ACR using the same service principal:

    REGISTRY_USERNAME = AZURE_CLIENT_ID
    REGISTRY_PASSWORD = AZURE_CLIENT_SECRET

Secret ලෙස mark කරන්න:

    AZURE_CLIENT_SECRET
    REGISTRY_PASSWORD

## Required permissions

Service principal එකට මේ permissions අවශ්‍යයි:

- AKS credentials get කරන්න permission
- ACR එකට push කරන්න `AcrPush` permission

Learning purpose එකට resource group හෝ subscription level `Contributor` use කරන්න පුළුවන්.

Production වලදී least privilege permissions use කරන්න.

## Files in this lab

මෙම lab එකේ files:

    backend/Dockerfile
      Backend image build කරන්න use කරන Dockerfile

    frontend/Dockerfile
      React frontend image build කරන්න use කරන Dockerfile

    frontend/nginx.conf
      Frontend-to-backend traffic සඳහා NGINX reverse proxy configuration

    k8s/
      MySQL, backend, සහ frontend සඳහා Kubernetes manifests

    azure-pipelines/azure-pipelines.yml
      Azure DevOps pipeline template

## Files to copy into the app repository

මෙම files 3-tier app repository root එකට copy කරන්න:

    backend/Dockerfile
    frontend/Dockerfile
    frontend/nginx.conf
    k8s/
    azure-pipelines.yml

Frontend app එක relative backend paths use කරන විදියට update කරන්න:

    const BACKEND_URL = '/api';
    fetch('/health');

App repository structure එක මෙහෙම වෙන්න ඕන:

    backend/
      Dockerfile
      package.json
      package-lock.json
      server.js

    frontend/
      Dockerfile
      nginx.conf
      package.json
      package-lock.json
      src/App.js

    k8s/
      namespace.yaml
      mysql-secret.yaml
      mysql-init-configmap.yaml
      mysql-pvc.yaml
      mysql-deployment.yaml
      mysql-service.yaml
      backend-deployment.yaml
      backend-service.yaml
      frontend-deployment.yaml
      frontend-service.yaml

    azure-pipelines.yml

## Pipeline stages

Pipeline stages:

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

මෙම stage structure එකෙන් Azure DevOps pipeline එක read කරන්න සහ troubleshoot කරන්න ලේසි වෙනවා.

## How it works

Pipeline එක කරන්නේ:

1. Required files validate කරනවා
2. Backend Docker image build කරනවා
3. Frontend Docker image build කරනවා
4. Images දෙකම ACR එකට push කරනවා
5. Azure login වෙනවා
6. AKS credentials ගන්නවා
7. `kubectl` install කරනවා
8. MySQL resources deploy කරනවා
9. Backend resources deploy කරනවා
10. Frontend resources deploy කරනවා
11. Rollouts verify කරනවා

## Local validation

Pipeline එක run කරන්න කලින් app repository එකෙන් backend Docker build locally test කරන්න පුළුවන්:

    docker build -t node-backend-test backend

Container එක locally run කරන්න:

    docker run --rm -p 5002:5000 \
      -e DB_HOST=host.docker.internal \
      -e DB_USER=root \
      -e DB_PASSWORD=password \
      -e DB_NAME=devops_db \
      node-backend-test

Health endpoint test කරන්න:

    curl http://localhost:5002/health

Local database එක available නම් expected output:

    {"status":"UP","database":"CONNECTED"}

මෙම test එකෙන් backend container build/start flow එක verify වෙනවා.

## Verify after pipeline success

Pipeline success වුණාට පස්සේ local machine එකෙන් verify කරන්න:

    kubectl get pods -n practitioner-azure-devops
    kubectl get svc -n practitioner-azure-devops
    kubectl rollout status deployment/mysql -n practitioner-azure-devops
    kubectl rollout status deployment/node-backend -n practitioner-azure-devops
    kubectl rollout status deployment/node-frontend -n practitioner-azure-devops

Frontend service එක port-forward කරන්න:

    kubectl port-forward svc/node-frontend -n practitioner-azure-devops 8087:80

Frontend proxy හරහා health test කරන්න:

    curl http://localhost:8087/health

Frontend proxy හරහා tasks API test කරන්න:

    curl http://localhost:8087/api/tasks

Expected:

    {"status":"UP","database":"CONNECTED"}

Expected:

    DevOps 3-Tier Dashboard page එක load වෙන්න ඕන.
    MySQL DB status Connected වෙන්න ඕන.

## Common issues

### Docker build uses old Dockerfile

Azure DevOps pipeline එක තවම මේ line එක run කරනවා නම්:

    npm ci --omit=dev

නමුත් GitHub repo එකේ Dockerfile එකේ මේක තියෙනවා නම්:

    npm install --omit=dev

එහෙනම් Azure DevOps pipeline එක outdated Azure Repos copy එකක් build කරනවා විය හැකියි.

Fix:

- Latest code Azure Repos එකට push කරන්න
- Or pipeline එක directly GitHub repo එකට connect කරන්න

### kubectl command not found

Azure CLI image එකේ `kubectl` නැති වෙන්න පුළුවන්.

මෙම pipeline එක kubectl commands run කරන්න කලින් මේක use කරනවා:

    az aks install-cli

### Backend readiness probe fails

Backend health endpoint එක MySQL connectivity check කරනවා.

MySQL ready නැත්නම් backend pod එක Ready වෙන්න ටිකක් වෙලා යන්න පුළුවන්.

Check කරන්න:

    kubectl get pods -n practitioner-azure-devops
    kubectl logs deployment/mysql -n practitioner-azure-devops
    kubectl logs deployment/node-backend -n practitioner-azure-devops

Common reasons:

- MySQL pod තවම starting
- Secret value issue
- DB name/user/password mismatch
- Backend environment variables wrong

## Cleanup

Namespace එක delete කරන්න:

    kubectl delete namespace practitioner-azure-devops

මෙයින් MySQL, backend, frontend, services, configmaps, secrets, PVC resources delete වෙනවා.

Optional ACR cleanup:

    az acr repository delete \
      --name <acr-name> \
      --repository node-backend \
      --yes

    az acr repository delete \
      --name <acr-name> \
      --repository node-frontend \
      --yes

## Security cleanup

Testing ඉවර වුණාම Azure DevOps වල use කළ temporary service principal secrets remove හෝ rotate කරන්න.

Secrets Git වලට commit කරන්න එපා.

CI/CD variables වලින් unused secrets remove කරන්න.

## Important note

මෙම lab එක learning-purpose Azure DevOps deployment example එකක්.

Production pipelines වලදී consider කරන්න:

- Azure DevOps service connections
- OIDC / federated credentials where possible
- Least privilege permissions
- Environment approvals
- Secret rotation
- DevSecOps scanning
- GitOps or controlled deployment promotion
