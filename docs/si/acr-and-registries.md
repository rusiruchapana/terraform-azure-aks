# ACR සහ Image Registries

මෙම document එකෙන් AKS DevOps Practice Platform එකේ container image registries use කරන ආකාරය පැහැදිලි කරනවා.

## Container registry කියන්නේ මොකක්ද?

Container registry එකක් container images store කරන තැනක්.

Kubernetes registry එකකින් images pull කරලා pods ලෙස run කරනවා.

Common registries:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- Quay
- GitLab Container Registry
- වෙනත් private registries

## මෙම platform එකේ registry design එක

මෙම platform එක registry-agnostic.

ඒ කියන්නේ usersලාට මේවගෙන් කැමති registry එකක් use කරන්න පුළුවන්:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- GitLab Container Registry
- Quay
- වෙනත් public හෝ private registry

Azure Container Registry optional.

## Azure Container Registry

Azure Container Registry කියන්නේ Azure වල private container registry service එකක්.

මේවාට useful:

- Images AKS වලට close තියාගන්න
- Azure-native authentication use කරන්න
- Private image storage
- Enterprise-style image workflows practice කරන්න

## ACR enable කිරීම

terraform.tfvars එකේ:

    enable_acr = true

Enabled නම් Terraform create කරනවා:

- Azure Container Registry
- AKS සඳහා AcrPull role assignment

## ACR disable කිරීම

terraform.tfvars එකේ:

    enable_acr = false

Disabled නම් Terraform ACR create කරන්නේ නැහැ.

හැබැයි public images deploy කරන්න තවම පුළුවන්:

- Docker Hub
- GHCR
- Quay

## ACR settings

Common ACR variables:

    enable_acr
    acr_name
    acr_sku
    acr_admin_enabled

Example:

    enable_acr        = true
    acr_name          = "replacewithuniqueacr001"
    acr_sku           = "Basic"
    acr_admin_enabled = false

## ACR name globally unique වෙන්න ඕන

ACR names Azure තුළ globally unique වෙන්න ඕන.

Lowercase letters සහ numbers use කරන්න.

Example:

    <your-acr-name>

Uppercase letters හෝ special characters use කරන්න එපා.

## ACR SKU

Common SKU options:

- Basic
- Standard
- Premium

Learning සඳහා Basic සාමාන්‍යයෙන් enough.

Example:

    acr_sku = "Basic"

Production-style environments වලදී requirements අනුව Standard හෝ Premium use කරන්න පුළුවන්.

## ACR admin user

Recommended:

    acr_admin_enabled = false

ඇයි?

Admin user username/password authentication use කරනවා.

AKS සඳහා හොඳ pattern එක managed identity + AcrPull.

## AcrPull role assignment

ACR enabled නම් AKS ට ACR images pull කරන්න permission ඕන.

Terraform AcrPull role assignment create කරනවා.

High-level flow:

    AKS kubelet identity
              |
              v
    AcrPull role on ACR
              |
              v
    Pull private images from ACR

මේකෙන් Kubernetes secrets වල ACR username/password store කරන්න අවශ්‍ය නැහැ.

## Images ACR එකට push කිරීම

ACR login:

    az acr login --name <acr-name>

Image build:

    docker build -t <acr-login-server>/my-app:v1 .

Image push:

    docker push <acr-login-server>/my-app:v1

Example login server:

    <your-acr-login-server>

## ACR image AKS එකට deploy කිරීම

Example image reference:

    <your-acr-login-server>/my-app:v1

Kubernetes Deployment example:

    image: <your-acr-login-server>/my-app:v1

AcrPull properly configured නම් ACR සඳහා imagePullSecret අවශ්‍ය නැහැ.

## Docker Hub public images use කිරීම

Docker Hub public images deploy කරන්න පුළුවන්.

Example:

    image: nginx:latest

මේකට ACR අවශ්‍ය නැහැ.

## GitHub Container Registry use කිරීම

Public GHCR image example:

    image: ghcr.io/example-org/example-app:v1

Private GHCR images සඳහා imagePullSecret ඕන.

## GitLab Container Registry use කිරීම

GitLab Container Registry එකත් use කරන්න පුළුවන්.

Public images secret නැතුව work වෙන්න පුළුවන්.

Private GitLab registry images සඳහා imagePullSecret ඕන.

## Private external registries use කිරීම

ACR නොවන private registry එකක් සඳහා Kubernetes imagePullSecret create කරන්න.

Example:

    kubectl create secret docker-registry my-registry-secret \
      --docker-server=<registry-server> \
      --docker-username=<username> \
      --docker-password=<password> \
      --docker-email=<email> \
      -n <namespace>

Deployment එකේ reference කරන්න:

    imagePullSecrets:
      - name: my-registry-secret

## ACR vs external registries

ACR use කරන්න හොඳ අවස්ථා:

- Azure-native integration ඕන නම්
- Managed identity-based image pulls ඕන නම්
- Private images AKS ට close තියාගන්න ඕන නම්
- Azure enterprise patterns practice කරන්න ඕන නම්

External registries use කරන්න හොඳ අවස්ථා:

- Organization එක Docker Hub, GHCR, GitLab හෝ වෙන registry already use කරනවා නම්
- Registry-agnostic labs ඕන නම්
- imagePullSecret workflows practice කරන්න ඕන නම්

## Recommended learning path

Beginner:

1. Docker Hub public image deploy කරන්න
2. ACR enable කරන්න
3. Image build කරලා ACR එකට push කරන්න
4. ACR image AKS එකට deploy කරන්න

Practitioner:

1. Private external registry එකකින් deploy කරන්න
2. imagePullSecret use කරන්න
3. ImagePullBackOff troubleshoot කරන්න
4. ACR vs external registry flows compare කරන්න

Professional:

1. CI/CD වල image build සහ push automate කරන්න
2. Immutable image tags use කරන්න
3. dev, qa, prod අතර images promote කරන්න
4. Image scanning සහ policy checks add කරන්න

## Common errors

### ImagePullBackOff

මෙයින් අදහස් වෙන්නේ Kubernetes ට image එක pull කරන්න බැරි වෙලා.

Check කරන්න:

    kubectl describe pod <pod-name> -n <namespace>

Common causes:

- Image name වැරදියි
- Image tag වැරදියි
- Private registry credentials නැහැ
- AcrPull role missing
- Registry unavailable
- Docker Hub rate limits

### ACR access denied

Possible causes:

- AKS kubelet identity එකට AcrPull නැහැ
- Wrong ACR login server
- Image එක exist වෙන්නේ නැහැ
- Wrong tag

ACR repository list check කරන්න:

    az acr repository list --name <acr-name> --output table

Tags check කරන්න:

    az acr repository show-tags --name <acr-name> --repository <repository-name> --output table

## Best practices

- Real environments සඳහා latest වෙනුවට unique image tags use කරන්න
- acr_admin_enabled false තියාගන්න
- AKS to ACR access සඳහා AcrPull use කරන්න
- External private registries සඳහා පමණක් imagePullSecret use කරන්න
- dev, qa, prod image promotion patterns use කරන්න
- Production deployment කලින් images scan කරන්න
