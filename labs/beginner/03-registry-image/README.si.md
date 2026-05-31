# Beginner Lab 03 - Deploy Image from a Container Registry

මෙම lab එකෙන් container registry එකකින් image එකක් pull කරලා AKS cluster එකට deploy කරන විදිය ඉගෙන ගන්නවා.

Lab 01 සහ Lab 02 වල අපි public NGINX image එකක් use කළා. මෙම lab එකේදී image source එක registry එකක් ලෙස හිතලා, ACR හෝ external registry image එකක් deploy කරන pattern එක practice කරනවා.

Registry image deployment වලදී වැදගත් දේවල් දෙකක් තියෙනවා:

- Image reference එක හරිද?
- Cluster එකට ඒ image එක pull කරන්න permission තියෙනවද?

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Container registry image reference එකක් use කරන විදිය
- ACR image එකක් AKS වලට deploy කරන pattern එක
- Public external registry image එකක් deploy කරන pattern එක
- Private external registry සඳහා image pull secret idea එක
- ImagePullBackOff troubleshoot කරන විදිය
- Registry image deployment එක verify කරන විදිය

## Registry options

මෙම lab එක registry options තුනක් ගැන explain කරනවා.

### Option A - ACR enabled

AKS cluster එක Azure Container Registry එකට attach කරලා තිබේ නම්, AKS kubelet identity එකට ACR images pull කරන්න permission තියෙනවා.

Example image:

    myacr.azurecr.io/demo-web:v1

AcrPull correctly configured නම්, AKS එකට imagePullSecret නැතුව ACR එකෙන් image pull කරන්න පුළුවන්.

මෙම option එක Azure AKS + ACR environments වල recommended learning path එක.

### Option B - Public external registry

Image එක public registry එකක තියෙනවා නම් pull secret අවශ්‍ය නැහැ.

Examples:

    nginx:1.27-alpine
    docker.io/library/nginx:1.27-alpine
    ghcr.io/example-org/example-app:v1

මෙම option එක simple test cases වලට හොඳයි.

### Option C - Private external registry

Image එක private external registry එකක තියෙනවා නම් Kubernetes image pull secret එකක් අවශ්‍යයි.

Example command:

    kubectl create secret docker-registry registry-secret \
      --docker-server=<registry-server> \
      --docker-username=<username> \
      --docker-password=<password> \
      --docker-email=<email> \
      -n beginner-registry

ඊට පස්සේ Deployment එකට මේක add කරන්න:

    imagePullSecrets:
      - name: registry-secret

මෙම lab එකේ default manifests public image / simple registry image pattern එකට focus වෙනවා.

## Before you deploy

මෙම file එක open කරන්න:

    manifests/deployment.yaml

Image value එක replace කරන්න:

    image: nginx:1.27-alpine

අවශ්‍ය නම් ඔබගේ own registry image එකක් use කරන්න.

Examples:

    image: myacr.azurecr.io/demo-web:v1
    image: docker.io/myuser/demo-web:v1
    image: ghcr.io/myorg/demo-web:v1

First test එකට public NGINX image එක keep කරන්න පුළුවන්.

Private external registry එකක් use කරනවා නම්, image pull secret එක create කරලා Deployment එක update කරන්න.

## Deploy the lab

Namespace එක apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/namespace.yaml

Deployment සහ Service apply කරන්න:

    kubectl apply -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/deployment.yaml
    kubectl apply -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/service.yaml

Namespace එක වෙනම apply කරන එක safe. Namespace එක create වෙලා ඉවර වෙන්න කලින් Deployment apply වුණොත් `namespace not found` error එකක් එන්න පුළුවන්.

## Verify resources

Pods බලන්න:

    kubectl get pods -n beginner-registry

Service බලන්න:

    kubectl get svc -n beginner-registry

Rollout status බලන්න:

    kubectl rollout status deployment/registry-demo -n beginner-registry

Expected:

    Pod STATUS එක Running වෙන්න ඕන.
    Deployment rollout successful වෙන්න ඕන.
    registry-demo service එක පේන්න ඕන.

## Access the app locally

Service එක local machine එකට port-forward කරන්න:

    kubectl port-forward svc/registry-demo -n beginner-registry 8081:80

Browser එකෙන් open කරන්න:

    http://localhost:8081

Expected:

    App page එක load වෙන්න ඕන.

Port-forward stop කරන්න:

    Ctrl + C

## Troubleshooting

### ImagePullBackOff

Pods බලන්න:

    kubectl get pods -n beginner-registry

Pod details බලන්න:

    kubectl describe pod -n beginner-registry <pod-name>

ImagePullBackOff කියන්නේ Kubernetes image එක pull කරන්න බැරි වුණා කියන එක.

Common reasons:

- Image name වැරදියි
- Tag එක වැරදියි
- Registry login server වැරදියි
- Image private නමුත් pull secret නැහැ
- ACR permission නැහැ

### ACR image cannot be pulled

ACR repository list කරන්න:

    az acr repository list --name <acr-name> --output table

ACR image tags බලන්න:

    az acr repository show-tags --name <acr-name> --repository <repository-name> --output table

Check කරන්න:

- Repository name එක හරිද?
- Tag එක තියෙනවද?
- AKS cluster එකට ACR pull permission තියෙනවද?
- Image reference එක `<acr-login-server>/<repository>:<tag>` format එකේද?

### Private external image cannot be pulled

Private external registry එකකට secret එක තියෙනවද බලන්න:

    kubectl get secret -n beginner-registry

Check කරන්න:

- Secret එක correct namespace එකේද?
- Deployment එකේ `imagePullSecrets` section එක තියෙනවද?
- Registry username/password හරිද?
- Registry server URL හරිද?

## Cleanup

Service delete කරන්න:

    kubectl delete -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/service.yaml

Deployment delete කරන්න:

    kubectl delete -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/deployment.yaml

Namespace delete කරන්න:

    kubectl delete -f terraform-azure-aks/labs/beginner/03-registry-image/manifests/namespace.yaml

Verify:

    kubectl get ns beginner-registry

Namespace not found නම් cleanup complete.

