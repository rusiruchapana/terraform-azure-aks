# Stage 15 - End-to-end Dev Release Verification Workflow

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි Dev release එක end-to-end verify කරන GitHub Actions workflow එකක් add කරනවා.

මෙම workflow එක release deploy කරන්නේ නැහැ.

මෙම workflow එක කරන්නේ release එක ඇත්තටම correct විදිහට Dev environment එකට ගිහින්ද කියලා verify කිරීමයි.

Verification flow එක:

    ACR image exists ද?
    GitOps repo image tag correct ද?
    GitOps validation workflow passed ද?
    Argo CD Synced / Healthy ද?
    AKS deployment expected image එක run කරනවද?
    Pod Running ද?
    Gateway HTTP 200 return කරනවද?

## මේ stage එක වැදගත් ඇයි?

Stage 11 සිට Stage 14 දක්වා pipelines repo කිහිපයක තියෙනවා.

App repo pipeline:

    build image
    scan image
    push to ACR
    update GitOps repo

GitOps repo pipeline:

    validate YAML
    render Kustomize
    validate Kubernetes manifests

Argo CD:

    GitOps desired state cluster එකට sync කරනවා

AKS:

    workload run කරනවා

Gateway:

    user traffic receive කරනවා

මේවා වෙන වෙනම බලන එක beginner කෙනෙක්ට confuse වෙන්න පුළුවන්.

Stage 15 workflow එකෙන් userට එක pipeline එකකින් final release status එක බලන්න පුළුවන්.

## Repositories involved

App repo:

    aks-capstone-store-app

මෙහි Stage 15 verification workflow එක තියෙනවා.

GitOps repo:

    aks-capstone-gitops

මෙහි Kubernetes desired state සහ GitOps validation workflow තියෙනවා.

Terraform/platform repo:

    terraform-azure-aks

මෙහි Stage guide එක තියෙනවා.

## Stage 15 workflow එක app repo එකේ තියෙන්නේ ඇයි?

User app release එක trigger කරන්නේ app repo එකෙන්.

ඒ නිසා final release verification workflow එක app repo එකේ තිබුණාම learnerට ලේසියි.

App repo එකෙන්ම userට බලන්න පුළුවන්:

    app image build වුණාද
    GitOps update වුණාද
    GitOps validation pass ද
    Argo CD sync ද
    AKS deployment correct ද
    Gateway reachable ද

## Stage 15 workflow file

Workflow file path:

    .github/workflows/verify-dev-release.yml

Workflow name:

    Verify Dev release end-to-end

Input:

    image_tag

Example:

    stage13-v1

## Required GitHub secrets

App repo එකේ මේ secrets තිබිය යුතුයි:

    AZURE_CLIENT_ID
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    GITOPS_REPO_TOKEN

Meaning:

    AZURE_CLIENT_ID:
      GitHub Actions Azure OIDC identity

    AZURE_TENANT_ID:
      Azure tenant ID

    AZURE_SUBSCRIPTION_ID:
      Azure subscription ID

    GITOPS_REPO_TOKEN:
      GitOps repo read access සඳහා token එක

## Required GitHub variables

App repo එකේ මේ variables තිබිය යුතුයි:

    ACR_NAME
    ACR_LOGIN_SERVER
    GITOPS_REPO
    GITOPS_BRANCH
    GITOPS_STORE_FRONT_FILE
    AKS_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    ARGOCD_NAMESPACE
    ARGOCD_APP_NAME
    APP_NAMESPACE
    APP_DEPLOYMENT
    APP_LABEL_SELECTOR
    GATEWAY_URL

Example meanings:

    ACR_NAME:
      Azure Container Registry name

    ACR_LOGIN_SERVER:
      ACR login server

    GITOPS_REPO:
      GitOps repo owner/name

    GITOPS_BRANCH:
      GitOps branch

    GITOPS_STORE_FRONT_FILE:
      store-front image tag තියෙන GitOps manifest file path

    AKS_RESOURCE_GROUP:
      AKS cluster resource group

    AKS_CLUSTER_NAME:
      AKS cluster name

    ARGOCD_NAMESPACE:
      Argo CD namespace

    ARGOCD_APP_NAME:
      Argo CD Application name

    APP_NAMESPACE:
      application namespace

    APP_DEPLOYMENT:
      Kubernetes Deployment name

    APP_LABEL_SELECTOR:
      pod label selector

    GATEWAY_URL:
      Gateway public URL

Public guide එකේ live IP hardcode කරන්න එපා.

Use:

    http://<gateway-public-ip>

## Variables set කිරීම

App repo එකේ සිට variables set කරන්න.

Example:

    gh variable set AKS_RESOURCE_GROUP --body "<aks-resource-group>"
    gh variable set AKS_CLUSTER_NAME --body "<aks-cluster-name>"

    gh variable set ARGOCD_NAMESPACE --body "argocd"
    gh variable set ARGOCD_APP_NAME --body "capstone-store-dev"

    gh variable set APP_NAMESPACE --body "capstone-dev"
    gh variable set APP_DEPLOYMENT --body "store-front"
    gh variable set APP_LABEL_SELECTOR --body "app=store-front"

    gh variable set GATEWAY_URL --body "http://<gateway-public-ip>"

Verify කරන්න:

    gh variable list

## Azure permissions required

Stage 15 workflow එක Azure login කරලා ACR සහ AKS verify කරනවා.

ACR image tag check කරන්න existing ACR permission අවශ්‍යයි.

AKS credentials ගන්න මේ permission අවශ්‍යයි:

    Microsoft.ContainerService/managedClusters/listClusterUserCredential/action

මේ සඳහා GitHub OIDC identity එකට AKS cluster scope එකේ role එකක් දුන්නා:

    Azure Kubernetes Service Cluster User Role

Command concept:

    AKS_ID="$(az aks show \
      --resource-group <aks-resource-group> \
      --name <aks-cluster-name> \
      --query id \
      -o tsv)"

    az role assignment create \
      --assignee "$AZURE_CLIENT_ID" \
      --role "Azure Kubernetes Service Cluster User Role" \
      --scope "$AKS_ID"

## Kubernetes read permission

Stage 15 workflow එක kubectl commands run කරනවා.

Examples:

    kubectl get application
    kubectl get deployment
    kubectl get pods
    kubectl rollout status

මේ සඳහා read-only Kubernetes/AKS permission අවශ්‍ය විය හැක.

මෙම project එකේ GitHub identity එකට AKS cluster scope එකේ read role එකක් දුන්නා:

    Azure Kubernetes Service RBAC Reader

Command concept:

    az role assignment create \
      --assignee "$AZURE_CLIENT_ID" \
      --role "Azure Kubernetes Service RBAC Reader" \
      --scope "$AKS_ID"

Security note:

    Verification workflow එකට admin permission දෙන්න එපා.
    Read-only permission ප්‍රමාණවත් නම් read-only permission විතරක් දෙන්න.

## Workflow steps

Stage 15 workflow එකේ steps:

    Checkout app repo
    Azure login with OIDC
    Verify image tag exists in ACR
    Checkout GitOps repo
    Verify GitOps image tag
    Verify latest GitOps validation workflow passed
    Get AKS credentials
    Verify Argo CD application is synced and healthy
    Verify AKS deployment image
    Verify rollout and pod status
    Verify Gateway HTTP response
    Release verification summary

## Step 1 - Verify image tag exists in ACR

මෙම step එක ACR එකේ expected image tag එක තියෙනවද බලනවා.

Example expected image:

    <acr-login-server>/store-front:stage13-v1

Why important:

    Image ACR එකේ නැත්නම් AKS deploy කරන්න බැහැ.

## Step 2 - Verify GitOps image tag

මෙම step එක GitOps repo checkout කරලා manifest file එකේ expected image tag එක තියෙනවද බලනවා.

Expected line:

    image: <acr-login-server>/store-front:stage13-v1

Why important:

    ACR image තියෙනවා කියලා GitOps desired state update වෙලා කියලා assume කරන්න බැහැ.
    GitOps repo image tag එක separately verify කරන්න ඕන.

## Step 3 - Verify latest GitOps validation workflow passed

මෙම step එක GitOps repo එකේ latest validation workflow run එක success ද බලනවා.

Validation workflow:

    validate-gitops-manifests.yml

Why important:

    GitOps repo update වුණත් manifests valid ද කියලා confirm කරන්න ඕන.

## Step 4 - Get AKS credentials

මෙම step එක AKS cluster credentials ලබා ගන්නවා.

Command concept:

    az aks get-credentials

මුල් run එකේ මෙතන fail වුණා.

Reason:

    GitHub OIDC identity එකට listClusterUserCredential permission නැහැ.

Fix:

    Azure Kubernetes Service Cluster User Role

## Step 5 - Verify Argo CD Synced and Healthy

මෙම step එක Argo CD Application status check කරනවා.

Expected:

    Sync status: Synced
    Health status: Healthy

මුල් run එකේ Argo CD status:

    Synced
    Progressing

ඒ නිසා workflow fail වුණා.

Reason:

    Argo CD සහ Kubernetes rollout asynchronous.
    Health status immediate Healthy වෙන්න අවශ්‍ය නැහැ.

Fix:

    wait/retry loop එකක් add කළා

Workflow දැන් Argo CD application එක Synced and Healthy වෙනකල් wait කරනවා.

## Step 6 - Verify AKS deployment image

මෙම step එක AKS Deployment එකේ actual image එක expected image එකට match වෙනවද බලනවා.

Expected:

    <acr-login-server>/store-front:stage13-v1

Why important:

    Argo CD Synced කියලා deployment image correct කියලා assume කරන්න එපා.
    Actual Kubernetes deployment image verify කරන්න ඕන.

## Step 7 - Verify rollout and pod status

මෙම step එක deployment rollout complete ද බලනවා.

Checks:

    kubectl rollout status
    pod Running ද?
    at least one Running pod තියෙනවද?

Why important:

    Deployment object image correct වුණත් pod Running නැත්නම් release healthy නැහැ.

## Step 8 - Verify Gateway HTTP response

මෙම step එක Gateway URL එකට HTTP request එකක් යවනවා.

Expected:

    HTTP 200

Why important:

    Pod Running වුණාට user traffic වැඩ කරනවාද කියලා Gateway test එකෙන් confirm වෙනවා.

## Workflow run කිරීම

App repo එකේ සිට run කරන්න:

    gh workflow run "Verify Dev release end-to-end" \
      -f image_tag=stage13-v1

Watch කරන්න:

    gh run watch

## Successful run result

Stage 15 final run result:

    Verify image tag exists in ACR                  Passed
    Verify GitOps image tag                         Passed
    Verify latest GitOps validation workflow passed Passed
    Get AKS credentials                             Passed
    Verify Argo CD application is synced and healthy Passed
    Verify AKS deployment image                     Passed
    Verify rollout and pod status                   Passed
    Verify Gateway HTTP response                    Passed
    Release verification summary                    Passed

Workflow status:

    Success

## Real issues handled

### Issue 1 - AKS credentials permission missing

Error:

    AuthorizationFailed
    listClusterUserCredential/action permission missing

Fix:

    Azure Kubernetes Service Cluster User Role

Lesson:

    ACR push permission සහ AKS credential permission වෙනස්.
    Image build pipeline permission verification pipeline permission එකට සමාන නැහැ.

### Issue 2 - Argo CD health was Progressing

Observed:

    Sync status: Synced
    Health status: Progressing

Fix:

    wait/retry loop

Lesson:

    Argo CD and Kubernetes rollout asynchronous.
    Verification workflow එකට wait logic ඕන.

### Issue 3 - Need Kubernetes read access

Verification workflow එක kubectl read commands run කරනවා.

Fix:

    Azure Kubernetes Service RBAC Reader

Lesson:

    End-to-end verification workflow එකට cluster admin permission අවශ්‍ය නැහැ.
    Read-only access ප්‍රමාණවත්.

## Final verified state - අවසාන verified තත්ත්වය

Stage 15 final state:

    App repo verification workflow created

Workflow name:

    Verify Dev release end-to-end

Workflow result:

    Success

Verified release tag:

    stage13-v1

Verified path:

    ACR
      -> GitOps repo
      -> GitOps validation workflow
      -> Argo CD
      -> AKS deployment
      -> Pod
      -> Gateway

Final result:

    Dev release end-to-end verified

## Production learning points - production පාඩම්

### 1. Deployment success සහ release success එකම දෙයක් නෙවෙයි

Image build වුණා කියලා release success කියලා කියන්න බැහැ.

GitOps update වුණා කියලා release success කියන්න බැහැ.

Argo CD Synced වුණා කියලාත් user traffic success කියලා කියන්න බැහැ.

Release success verify කරන්න end-to-end checks ඕන.

### 2. Verification pipeline user visibility වැඩි කරනවා

Repos කිහිපයක pipelines තිබුණාම learner/user confuse වෙන්න පුළුවන්.

Stage 15 workflow එකෙන් එක තැනකින් බලන්න පුළුවන්:

    image exists
    GitOps updated
    GitOps validation passed
    Argo CD healthy
    AKS correct image
    Pod running
    Gateway working

### 3. Verification workflow deploy නොකරයි

මෙම workflow එක deploy command run කරන්නේ නැහැ.

එය release එක verify කරනවා.

මෙය safe pattern එකක්.

### 4. Least privilege important

Verification workflow එකට අවශ්‍ය permissions:

    ACR read
    GitOps repo read
    AKS credentials read
    Kubernetes read

Admin/Owner permission අවශ්‍ය නැහැ.

### 5. Wait/retry logic අවශ්‍යයි

Cloud-native systems asynchronous.

Argo CD, Kubernetes rollout, pod health status immediate update නොවෙන්න පුළුවන්.

ඒ නිසා verification workflow එකට retry/wait logic දාන්න ඕන.

## Troubleshooting - ගැටළු විසඳීම

### Issue 1 - ACR image tag not found

Check:

    az acr repository show-tags \
      --name <acr-name> \
      --repository store-front \
      -o table

Possible causes:

    image build failed
    wrong image_tag input
    wrong ACR_NAME variable

### Issue 2 - GitOps image tag mismatch

Check GitOps file:

    apps/capstone-store/base/aks-store-quickstart.yaml

Possible causes:

    GitOps update workflow failed
    wrong GITOPS_STORE_FRONT_FILE variable
    wrong image_tag input

### Issue 3 - GitOps validation workflow not successful

Check GitOps repo Actions:

    Validate GitOps manifests

Possible causes:

    YAML syntax issue
    Kustomize render issue
    kubeconform validation issue

### Issue 4 - az aks get-credentials fails

Error may mention:

    listClusterUserCredential/action

Fix:

    Azure Kubernetes Service Cluster User Role

### Issue 5 - kubectl get application fails

Possible causes:

    Kubernetes RBAC read permission missing
    wrong ARGOCD_NAMESPACE
    wrong ARGOCD_APP_NAME

Fix:

    verify variables
    grant read-only Kubernetes permission

### Issue 6 - Argo CD remains Progressing

Possible causes:

    Deployment rollout still happening
    pod not healthy
    readiness issue
    image pull issue

Check:

    kubectl get application <app-name> -n <argocd-namespace>
    kubectl get pods -n <app-namespace>
    kubectl describe pod <pod-name> -n <app-namespace>

### Issue 7 - Gateway HTTP check fails

Possible causes:

    wrong GATEWAY_URL
    Gateway service external IP changed
    HTTPRoute issue
    backend service issue
    pod not ready

Check:

    kubectl get svc -A | grep LoadBalancer
    kubectl get httproute -A
    kubectl get endpointslice -n <app-namespace>

## Learner summary - ඉගෙනගන්න ප්‍රධාන අදහස

Stage 15 එකෙන් release verification එක learner-friendly වුණා.

Before Stage 15:

    App pipeline වෙනම බලන්න ඕන
    GitOps pipeline වෙනම බලන්න ඕන
    Argo CD / AKS / Gateway manually verify කරන්න ඕන

After Stage 15:

    one workflow එකකින් end-to-end release status බලන්න පුළුවන්

Final verification flow:

    ACR image
        -> GitOps desired state
        -> GitOps validation
        -> Argo CD health
        -> AKS deployment
        -> Running pod
        -> Gateway HTTP 200

Next stage:

    Stage 16 - Dev to QA to Prod promotion workflow
