# Beginner Lab 03 - Deploy Image from a Container Registry

මෙම lab එකෙන් container registry එකකින් container image එකක් AKS වලට deploy කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone beginner lab එකක්.

Default manifest එක public NGINX image එකක් use කරනවා, ඒ නිසා first run එක simple.

ඔයාට image එක වෙනස් කරලා මේ registry types use කරන්න පුළුවන්:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- GitLab Container Registry
- Quay
- වෙනත් private registry එකක්

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `beginner-registry` කියන Kubernetes namespace එකක්
- `registry-demo` කියන Deployment එකක්
- `registry-demo` කියන Service එකක්
- Registry image එකකින් create වුණු running pod එකක්
- `kubectl port-forward` use කරලා laptop එකෙන් access කළ හැකි application එකක්

Local test URL එක:

    http://localhost:8081

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Kubernetes container images reference කරන විදිය
- Registry එකකින් image එකක් deploy කරන විදිය
- Public සහ private registries අතර වෙනස
- AKS Azure Container Registry එකෙන් images pull කරන විදිය
- `imagePullSecret` අවශ්‍ය වෙන්නේ කවදාද
- `ImagePullBackOff` troubleshoot කරන විදිය
- ACR image tags verify කරන විදිය
- Lab resources safely clean up කරන විදිය

## Lab architecture

Default flow එක:

    AKS cluster
      |
      v
    Namespace: beginner-registry
      |
      v
    Deployment: registry-demo
      |
      v
    Image: nginx:1.27-alpine
      |
      v
    Pod: registry-demo
      |
      v
    Service: registry-demo
      |
      v
    kubectl port-forward
      |
      v
    http://localhost:8081

ACR use කරනවා නම් flow එක:

    AKS kubelet identity
      |
      | AcrPull permission
      v
    Azure Container Registry
      |
      v
    Container image

Private external registry එකක් use කරනවා නම් සාමාන්‍යයෙන් අවශ්‍ය වෙන්නේ:

    Kubernetes imagePullSecret
      |
      v
    Private registry credentials

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- kubectl
- AKS cluster access
- Terminal එකක්
- Web browser එකක්

Default public image path එකට අවශ්‍ය නැහැ:

- Docker Desktop
- Azure Container Registry
- Registry credentials

ACR image එකකට අවශ්‍යයි:

- Existing ACR
- ACR එකට already pushed image එකක්
- AKS වලට ACR pull permission

Private external registry එකකට අවශ්‍යයි:

- Registry server name
- Registry username හෝ token
- Registry password හෝ token
- Kubernetes imagePullSecret

## Install required local tools

### kubectl

kubectl install කරන්න:

    https://kubernetes.io/docs/tasks/tools/

kubectl verify කරන්න:

    kubectl version --client

### Azure CLI for ACR option

Azure CLI අවශ්‍ය වෙන්නේ ACR option එක test කරනවා නම් පමණයි.

Azure CLI install කරන්න:

    https://learn.microsoft.com/cli/azure/install-azure-cli

Azure CLI verify කරන්න:

    az version

## Check local tools and AKS access

Continue කරන්න කලින් kubectl ට AKS cluster එකට connect වෙන්න පුළුවන්ද verify කරන්න:

    kubectl get nodes

Expected:

    Nodes Ready status එකෙන් පෙන්විය යුතුයි.

ACR use කරනවා නම් Azure access verify කරන්න:

    az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table

## Files in this lab

මෙම lab එකේ files:

    manifests/
      Namespace, deployment, සහ service සඳහා Kubernetes manifests

Files:

    manifests/namespace.yaml
    manifests/deployment.yaml
    manifests/service.yaml

Default image එක:

    nginx:1.27-alpine

Deployment එකේ private external registries සඳහා commented `imagePullSecrets` example එකක් ද තියෙනවා.

## Important node selector note

Deployment එකේ මේ node selector එක තියෙනවා:

    nodeSelector:
      workload: user

ඒ කියන්නේ pod එක schedule වෙන්නේ මේ label එක තියෙන nodes වලට විතරයි:

    workload=user

ඔයාගේ nodes වල ඒ label එක තියෙනවද check කරන්න:

    kubectl get nodes --show-labels | grep "workload=user" || true

ඔයාගේ cluster එකේ මේ label එක නැත්නම්, worker node එකකට label එක add කරන්න හෝ manifest එකෙන් `nodeSelector` remove කරන්න.

මෙම lab එකට node එකක් label කරන්න:

    kubectl get nodes

Node name එකක් තෝරලා run කරන්න:

    kubectl label node <node-name> workload=user --overwrite

## Registry options

### Option A - Public image

මෙය simplest option එක.

Default manifest එකේ දැනටමත් මේ image එක තියෙනවා:

    image: nginx:1.27-alpine

Public images සාමාන්‍යයෙන් `imagePullSecret` අවශ්‍ය කරන්නේ නැහැ.

### Option B - Azure Container Registry

ඔයාගේ image එක ACR තුළ තියෙනවා නම් මෙම option එක use කරන්න.

Image format එක:

    <acr-login-server>/<repository>:<tag>

Example:

    myacr.azurecr.io/demo-web:v1

ACR registries list කරන්න:

    az acr list --query "[].{name:name, resourceGroup:resourceGroup, loginServer:loginServer}" -o table

Repositories list කරන්න:

    az acr repository list \
      --name <acr-name> \
      --output table

Image tags list කරන්න:

    az acr repository show-tags \
      --name <acr-name> \
      --repository <repository-name> \
      --output table

AKS වලට ACR එකෙන් pull කරන්න පුළුවන්ද check කරන්න:

    az aks check-acr \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --acr <acr-name>

අවශ්‍ය නම් ACR එක AKS එකට attach කරන්න:

    az aks update \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --attach-acr <acr-name>

ACR pull permission correctly configured නම්, AKS එකට `imagePullSecret` නැතුව ACR එකෙන් image pull කරන්න පුළුවන්.

### Option C - Private external registry

ඔයාගේ image එක ACR වලින් පිට private registry එකක තියෙනවා නම් මෙම option එක use කරන්න.

Private external registries සාමාන්‍යයෙන් `imagePullSecret` අවශ්‍ය කරනවා.

Deployment එක තියෙන namespace එකේම secret එක create කරන්න:

    kubectl create secret docker-registry registry-secret \
      --docker-server=<registry-server> \
      --docker-username=<username> \
      --docker-password=<password-or-token> \
      --docker-email=<email> \
      -n beginner-registry

ඊට පස්සේ `manifests/deployment.yaml` file එකේ මේ section එක uncomment කරන්න:

    imagePullSecrets:
      - name: registry-secret

Secret එක තියෙන්න ඕන:

    beginner-registry

## Before you deploy

මෙම file එක open කරන්න:

    labs/beginner/03-registry-image/manifests/deployment.yaml

First test එකට මෙය keep කරන්න පුළුවන්:

    image: nginx:1.27-alpine

ඔයාගේ own registry image එක test කරන්න image value එක replace කරන්න.

Examples:

    image: myacr.azurecr.io/demo-web:v1
    image: docker.io/myuser/demo-web:v1
    image: ghcr.io/myorg/demo-web:v1

Private external registry එකක් use කරනවා නම්, මුලින් `registry-secret` create කරලා `imagePullSecrets` uncomment කරන්න.

## Deploy the lab

මෙම commands repository root එකේ සිට run කරන්න.

මුලින් namespace එක apply කරන්න:

    kubectl apply -f labs/beginner/03-registry-image/manifests/namespace.yaml

Private external registry එකක් use කරනවා නම්, image pull secret එක දැන් create කරන්න.

App resources apply කරන්න:

    kubectl apply -f labs/beginner/03-registry-image/manifests/deployment.yaml
    kubectl apply -f labs/beginner/03-registry-image/manifests/service.yaml

## Verify resources

Namespace එක check කරන්න:

    kubectl get namespace beginner-registry

Pods check කරන්න:

    kubectl get pods -n beginner-registry -o wide

Rollout check කරන්න:

    kubectl rollout status deployment/registry-demo -n beginner-registry --timeout=180s

Service එක check කරන්න:

    kubectl get svc registry-demo -n beginner-registry

Expected:

    namespace exists
    pod status is Running
    deployment rollout is successful
    service type is ClusterIP

## Access the app locally

Port-forward use කරන්න:

    kubectl port-forward svc/registry-demo -n beginner-registry 8081:80

Browser එකෙන් මේ URL එක open කරන්න:

    http://localhost:8081

Default NGINX image එක keep කළා නම් default NGINX welcome page එක පේන්න ඕන.

තවත් terminal එකකින් curl use කරලා test කරන්නත් පුළුවන්:

    curl http://localhost:8081

Port-forward stop කරන්න:

    Ctrl+C

## Troubleshooting

### ImagePullBackOff

Pods check කරන්න:

    kubectl get pods -n beginner-registry

Pod describe කරන්න:

    kubectl describe pod -n beginner-registry <pod-name>

Common causes:

- Image name වැරදියි
- Image tag වැරදියි
- Registry login server වැරදියි
- Registry authentication අවශ්‍යයි
- `imagePullSecret` missing
- ACR `AcrPull` permission missing
- Image registry එකේ නැහැ

### ACR image cannot be pulled

Image එක තියෙනවද verify කරන්න:

    az acr repository list --name <acr-name> --output table

    az acr repository show-tags \
      --name <acr-name> \
      --repository <repository-name> \
      --output table

AKS to ACR access check කරන්න:

    az aks check-acr \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --acr <acr-name>

අවශ්‍ය නම් ACR attach කරන්න:

    az aks update \
      --resource-group <resource-group> \
      --name <aks-cluster-name> \
      --attach-acr <acr-name>

Image format එක මේ වගේ වෙන්න ඕන:

    <acr-login-server>/<repository>:<tag>

### Private external image cannot be pulled

Secret එක තියෙනවද check කරන්න:

    kubectl get secret registry-secret -n beginner-registry

Deployment එක secret එක use කරනවද check කරන්න:

    kubectl get deployment registry-demo -n beginner-registry -o yaml | grep -A3 imagePullSecrets

Check කරන්න:

- Secret එක Deployment එකේ namespace එකේම තියෙනවද
- Deployment එක secret එක reference කරනවද
- Registry username/password/token correct ද
- Registry server name correct ද

### Pod is Pending

Pod එක Pending නම්, node selector එක node labels සමඟ match වෙනවද check කරන්න:

    kubectl get nodes --show-labels | grep "workload=user" || true

ඒ label එක තියෙන node එකක් නැත්නම්, node එකකට label එක add කරන්න හෝ Deployment manifest එකෙන් node selector remove කරන්න.

## Cleanup

Lab namespace එක delete කරන්න:

    kubectl delete namespace beginner-registry --ignore-not-found

මෙයින් මෙම namespace එකේ Deployment, Pod, Service, සහ create කළ `registry-secret` remove වෙනවා.

`workload=user` label එක මෙම lab එකට විතරක් add කළා නම් සහ remove කරන්න ඕන නම් run කරන්න:

    kubectl label node <node-name> workload-

## Important note

මෙය beginner lab එකක්.

මුලින් public image එකෙන් start කරන්න.

Basic deployment එක වැඩ කළාට පස්සේ ACR හෝ වෙනත් registry image එකකට image value එක change කරලා image pull permissions Kubernetes deployments වලට බලපාන විදිය ඉගෙන ගන්න.
