# Stage 10 - ACR Image Build, Push, and GitOps Deploy Foundation

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි GitHub Actions CI/CD වලට යන්න කලින් manual image build and push flow එක ඉගෙන ගන්නවා.

අපි කළ flow එක:

    App source code
        -> Docker image build
        -> Azure Container Registry tag
        -> Push image to ACR
        -> GitOps manifest update
        -> Argo CD deploy
        -> AKS pull image from ACR
        -> store-front pod Running

මේ stage එක CI/CD වලට කලින් වැදගත් foundation එකක්.

## මේ stage එක වැදගත් ඇයි?

GitHub Actions workflow එකක් ලියන්න කලින් learner ට manual flow එක තේරෙන්න ඕන.

CI/CD automation කියන්නේ manual steps automate කරන එක.

Manual flow එක නොතේරෙනකොට GitHub Actions fail වුණාම troubleshoot කරන්න අමාරුයි.

මේ stage එකෙන් learner ට තේරෙන්නේ:

    Docker image එක build වෙන්නේ කොහොමද
    ACR එකට image push කරන්නේ කොහොමද
    AKS cluster එක ACR image pull කරන්නේ කොහොමද
    GitOps manifest image tag update කළාම Argo CD deploy කරන්නේ කොහොමද
    ImagePullBackOff troubleshoot කරන්නේ කොහොමද

## Current repositories

App source repo:

    aks-capstone-store-app

GitOps repo:

    aks-capstone-gitops

Platform/Terraform guide repo:

    terraform-azure-aks

## Current Azure resources

ACR:

    acrakscapstoneae9954.azurecr.io

AKS cluster:

    aks-capstone-ae-001

Resource group:

    rg-aks-capstone-ae-001

Namespace:

    capstone-dev

## Stage 10 target component

මේ stage එකේදී මුලින් build කළ component එක:

    store-front

Reason:

    store-front කියන්නේ customer-facing UI component එක.
    ඒක Gateway හරහා browser/curl වලින් verify කරන්න ලේසි.
    CI/CD learning වලට පළවෙනි component එකක් ලෙස හොඳයි.

## Step 1 - App repo එකට යන්න

    cd <your-local-path>/aks-capstone-store-app

Check git status:

    git status

Expected:

    nothing to commit, working tree clean

## Step 2 - Dockerfiles check කිරීම

    find src -maxdepth 2 -type f -name 'Dockerfile' -print

Observed Dockerfiles:

    src/store-front/Dockerfile
    src/product-service/Dockerfile
    src/ai-service/Dockerfile
    src/makeline-service/Dockerfile
    src/virtual-customer/Dockerfile
    src/store-admin/Dockerfile
    src/order-service/Dockerfile
    src/virtual-worker/Dockerfile

මේකෙන් confirm වෙනවා app source repo එකේ components build කරන්න Dockerfiles තියෙනවා කියලා.

## Step 3 - ACR variables set කිරීම

    export ACR_NAME="acrakscapstoneae9954"
    export ACR_LOGIN_SERVER="acrakscapstoneae9954.azurecr.io"
    export IMAGE_NAME="store-front"
    export IMAGE_TAG="stage10-v1"

Verify:

    echo $ACR_NAME
    echo $ACR_LOGIN_SERVER
    echo $IMAGE_NAME
    echo $IMAGE_TAG

## Step 4 - Azure account and ACR check

Azure subscription check:

    az account show -o table

ACR check:

    az acr show --name $ACR_NAME -o table

Observed ACR:

    NAME                  RESOURCE GROUP          LOCATION       SKU    LOGIN SERVER
    acrakscapstoneae9954  rg-aks-capstone-ae-001  australiaeast  Basic  acrakscapstoneae9954.azurecr.io

Important note:

    ACR admin user disabled වුණත් problem එකක් නැහැ.
    az acr login use කරලා Azure identity හරහා login වෙන්න පුළුවන්.

## Step 5 - ACR login

    az acr login --name $ACR_NAME

Expected:

    Login Succeeded

## Step 6 - First local Docker build

මුලින් normal Docker build එකක් කළා.

    docker build -t $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG ./src/store-front

Then push:

    docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG

ACR verify:

    az acr repository list --name $ACR_NAME -o table

    az acr repository show-tags --name $ACR_NAME --repository store-front -o table

Observed:

    Repository:
      store-front

    Tag:
      stage10-v1

මේකෙන් confirm වුණා image එක ACR එකට push වෙලා තියෙනවා.

## Step 7 - AKS can pull from ACR ද බලන්න

    az aks check-acr \
      --resource-group rg-aks-capstone-ae-001 \
      --name aks-capstone-ae-001 \
      --acr acrakscapstoneae9954.azurecr.io

මෙහි goal එක:

    AKS cluster එකට ACR image pull කරන්න permission තියෙනවද බලන එක.

If permission issue එකක් තියෙනවා නම් fix:

    az aks update \
      --resource-group rg-aks-capstone-ae-001 \
      --name aks-capstone-ae-001 \
      --attach-acr acrakscapstoneae9954

Production meaning:

    Image registry එක private නම් AKS kubelet identity එකට AcrPull permission අවශ්‍යයි.

## Step 8 - GitOps manifest image update කිරීම

GitOps repo එකට යන්න:

    cd <your-local-path>/aks-capstone-gitops

Original image:

    ghcr.io/azure-samples/aks-store-demo/store-front:2.1.0

New ACR image:

    acrakscapstoneae9954.azurecr.io/store-front:stage10-v1

Replace command:

    sed -i '' 's|ghcr.io/azure-samples/aks-store-demo/store-front:2.1.0|acrakscapstoneae9954.azurecr.io/store-front:stage10-v1|g' apps/capstone-store/base/aks-store-quickstart.yaml

Verify:

    grep -n "image:" apps/capstone-store/base/aks-store-quickstart.yaml

Expected store-front line:

    image: acrakscapstoneae9954.azurecr.io/store-front:stage10-v1

## Step 9 - Kustomize render and dry-run

    cd <your-local-path>/aks-capstone-gitops/apps/capstone-store/base

Render check:

    kubectl kustomize . | grep -n "acrakscapstoneae9954.azurecr.io/store-front:stage10-v1"

Server dry-run:

    kubectl apply -k . --dry-run=server

If dry-run success, commit and push:

    cd <your-local-path>/aks-capstone-gitops

    git status

    git add apps/capstone-store/base/aks-store-quickstart.yaml

    git commit -m "Deploy store-front image from ACR"

    git push

## Step 10 - Argo CD sync check

    kubectl get application capstone-store-dev -n argocd

Expected:

    capstone-store-dev   Synced   Healthy

Argo CD revision check:

    kubectl get application capstone-store-dev -n argocd -o jsonpath='{.status.sync.revision}{"\n"}'

Git local commit check:

    git rev-parse HEAD

These two should match after Argo CD syncs the latest commit.

## Issue encountered - ImagePullBackOff

After GitOps update, new store-front pod tried to pull ACR image but failed.

Observed pod status:

    store-front-77bc5bb447-j27qc   0/1   ErrImagePull
    store-front-77bc5bb447-j27qc   0/1   ImagePullBackOff

Old pod was still running:

    store-front-f5b957944-t9fhz    1/1   Running

This is normal during failed rolling update:

    Kubernetes keeps old working pod running
    New pod fails
    Service continues serving old pod
    Rollout does not fully complete

## Troubleshooting ImagePullBackOff

Describe the failed pod:

    kubectl describe pod <pod-name> -n capstone-dev

Observed error included:

    Failed to pull image
    no match for platform in manifest
    401 Unauthorized
    ImagePullBackOff

This gave us two possible problems:

    ACR permission issue
    Image platform mismatch

## Fix 1 - Attach ACR to AKS

Run:

    az aks update \
      --resource-group rg-aks-capstone-ae-001 \
      --name aks-capstone-ae-001 \
      --attach-acr acrakscapstoneae9954

Meaning:

    AKS kubelet identity gets AcrPull permission on ACR.

This fixes private registry authorization issues.

## Fix 2 - Rebuild image as linux/amd64

The project was built from a MacBook.

On Apple Silicon or some Docker Desktop setups, Docker may build arm64 image by default.

AKS Linux nodes usually need linux/amd64 image.

Symptom:

    no match for platform in manifest

Fix:

    docker buildx build --platform linux/amd64

Commands:

    cd <your-local-path>/aks-capstone-store-app

    export ACR_NAME="acrakscapstoneae9954"
    export ACR_LOGIN_SERVER="acrakscapstoneae9954.azurecr.io"
    export IMAGE_NAME="store-front"
    export IMAGE_TAG="stage10-v1"

Create or use buildx builder:

    docker buildx create --use --name capstone-builder 2>/dev/null || docker buildx use capstone-builder

    docker buildx inspect --bootstrap

Build and push linux/amd64 image:

    docker buildx build \
      --platform linux/amd64 \
      -t $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG \
      ./src/store-front \
      --push

Verify ACR tag:

    az acr repository show-tags --name $ACR_NAME --repository store-front -o table

Expected:

    stage10-v1

## Recover failed rollout

Delete old failed/running store-front pods and let Deployment recreate them:

    kubectl delete pod -n capstone-dev -l app=store-front

Check rollout:

    kubectl rollout status deployment/store-front -n capstone-dev

Expected:

    deployment "store-front" successfully rolled out

Verify deployment image:

    kubectl get deployment store-front -n capstone-dev -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

Expected:

    acrakscapstoneae9954.azurecr.io/store-front:stage10-v1

Verify pod:

    kubectl get pods -n capstone-dev -l app=store-front -o wide

Observed success:

    store-front-77bc5bb447-bmhgn   1/1   Running

Node:

    aks-apps-31498379-vmss000000

## Gateway test

    curl -I http://<gateway-public-ip>

Expected:

    HTTP/1.1 200 OK

## Final verified state

Stage 10 final state:

    ACR repository:
      store-front

    ACR tag:
      stage10-v1

    AKS deployment image:
      acrakscapstoneae9954.azurecr.io/store-front:stage10-v1

    store-front pod:
      Running

    Argo CD:
      capstone-store-dev Synced / Healthy

    Gateway:
      HTTP 200

## Production learning points

### 1. Docker push success does not mean AKS deploy success

Image can exist in registry, but Kubernetes may still fail to pull it.

Possible reasons:

    Missing AcrPull permission
    Wrong image name
    Wrong tag
    Wrong CPU architecture
    Registry authentication issue

### 2. Private registry requires permission

AKS needs permission to pull private ACR images.

Fix:

    az aks update --attach-acr

Production equivalent:

    Managed identity should have AcrPull role on ACR.

### 3. Mac builds can create wrong architecture images

If image is built as arm64 and AKS node needs amd64, pod can fail with:

    no match for platform in manifest

Fix:

    docker buildx build --platform linux/amd64

### 4. GitOps controls deployment

We did not directly kubectl edit the deployment.

Correct flow:

    Update GitOps repo
        -> commit
        -> push
        -> Argo CD sync
        -> AKS rollout

### 5. Failed rollout does not always break production immediately

Kubernetes kept the old store-front pod running while the new pod failed.

This is important production behavior.

It reduces downtime during failed rolling updates.

## How this prepares us for GitHub Actions

Stage 10 manual flow becomes Stage 11 automation.

Manual Stage 10:

    docker buildx build
    docker push
    update GitOps image tag
    git commit
    git push

Future Stage 11 GitHub Actions:

    on code push
        -> build linux/amd64 image
        -> push to ACR
        -> update GitOps repo image tag
        -> Argo CD deploys

Important GitHub Actions setting:

    platforms: linux/amd64

## Troubleshooting summary

### ImagePullBackOff

Check:

    kubectl describe pod <pod-name> -n capstone-dev

Look for:

    unauthorized
    authentication required
    manifest unknown
    no match for platform

### ACR tag missing

Check:

    az acr repository show-tags --name acrakscapstoneae9954 --repository store-front -o table

### Deployment still using old image

Check:

    kubectl get deployment store-front -n capstone-dev -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

Possible reasons:

    GitOps change not committed
    GitOps change not pushed
    Argo CD not synced
    Wrong manifest path

### Argo CD revision mismatch

Check:

    kubectl get application capstone-store-dev -n argocd -o jsonpath='{.status.sync.revision}{"\n"}'

    git rev-parse HEAD

These should match.

## Learner summary

මේ stage එකෙන් අපි CI/CD වල foundation එක practical විදිහට prove කළා.

Key lesson:

    CI/CD කියන්නේ magic එකක් නෙවෙයි.
    Source code එක image එකක් වෙනවා.
    Image එක registry එකට යනවා.
    GitOps repo එක deployment version එක කියනවා.
    Argo CD ඒ desired state එක AKS එකට apply කරනවා.

මේ flow එක manual විදිහට තේරුණාම GitHub Actions automation එක ගොඩක් ලේසි වෙනවා.
