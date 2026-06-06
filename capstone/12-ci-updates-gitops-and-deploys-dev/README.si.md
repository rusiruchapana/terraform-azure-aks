# Stage 12 - CI Updates GitOps Repo and Argo CD Deploys Dev

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි Stage 11 CI workflow එක තව step එකක් ඉදිරියට ගෙනියනවා.

Stage 11 වලදී කළේ:

    GitHub Actions
        -> build store-front image
        -> push image to ACR

Stage 12 වලදී කරන flow එක:

    GitHub Actions
        -> build store-front image
        -> push image to ACR
        -> checkout GitOps repo
        -> update store-front image tag
        -> commit and push GitOps change
        -> Argo CD detects GitOps change
        -> Argo CD deploys Dev environment

මේකෙන් app repo pipeline එක GitOps deployment flow එකට connect වෙනවා.

## මේ stage එක වැදගත් ඇයි?

Production-style CI/CD වලදී GitHub Actions directly Kubernetes cluster එකට kubectl apply කරන එක GitOps pattern එකට ගැලපෙන්නේ නැහැ.

Better pattern එක:

    CI builds artifact
    CI updates GitOps desired state
    Argo CD deploys desired state

ඒ කියන්නේ:

    GitHub Actions:
      image build and GitOps update

    GitOps repo:
      desired deployment version

    Argo CD:
      deployment engine

මෙම separation එක production වලට හොඳයි, මොකද deployment history එක Git වල audit කරන්න පුළුවන්.

## Repositories involved

App source repo:

    aks-capstone-store-app

GitOps repo:

    aks-capstone-gitops

Platform/Terraform guide repo:

    terraform-azure-aks

## Stage 12 scope

මේ stage එකේ scope එක:

    Build store-front image
    Push image to ACR
    Update GitOps repo image tag
    Deploy Dev through Argo CD
    Verify AKS rollout

මේ stage එකේ scope එකට අයිති නැති දේවල්:

    QA promotion
    Prod promotion
    Full DevSecOps gates
    Terraform platform pipeline

ඒවා next stages වලදී add කරනවා.

## Stage 12 flow

Full flow:

    Developer triggers workflow
        -> GitHub Actions builds store-front image
        -> image pushed to ACR
        -> GitHub Actions checks out GitOps repo
        -> GitOps image tag updated
        -> GitOps repo commit pushed
        -> Argo CD detects new commit
        -> Argo CD syncs Dev
        -> AKS pulls new image
        -> store-front pod rolls out
        -> Gateway returns HTTP 200

## Why GitOps repo token is needed

App repo workflow එකට GitOps repo එකට commit push කරන්න permission ඕන.

Default GitHub Actions token එක normally current repo එකට පමණක් write කරන්න පුළුවන්.

මේ stage එකේ app repo workflow එක වෙන repo එකකට write කරනවා:

    from:
      aks-capstone-store-app

    to:
      aks-capstone-gitops

ඒ නිසා GitOps repo එකට write permission තියෙන token එකක් අවශ්‍යයි.

GitHub secret name:

    GITOPS_REPO_TOKEN

Recommended token scope:

    Repository access:
      aks-capstone-gitops only

    Permission:
      Contents: Read and write

Security point:

    Token එකට අවශ්‍ය permission විතරක් දෙන්න.
    Full account access දෙන්න එපා.

## GitHub variables used

Stage 12 workflow එකට මේ GitHub variables අවශ්‍යයි.

    ACR_NAME
    ACR_LOGIN_SERVER
    GITOPS_REPO
    GITOPS_BRANCH
    GITOPS_STORE_FRONT_FILE

Example meanings:

    ACR_NAME:
      Azure Container Registry name

    ACR_LOGIN_SERVER:
      ACR login server from az acr show

    GITOPS_REPO:
      GitOps repo owner/name

    GITOPS_BRANCH:
      GitOps branch to update

    GITOPS_STORE_FRONT_FILE:
      GitOps manifest file where store-front image is defined

## Set GitOps token secret

Run from the app repo:

    gh secret set GITOPS_REPO_TOKEN

Paste the token when prompted.

Verify:

    gh secret list

Expected:

    GITOPS_REPO_TOKEN

## Set GitOps variables

Run from the app repo:

    gh variable set GITOPS_REPO --body "<github-owner>/<gitops-repo>"
    gh variable set GITOPS_BRANCH --body "main"
    gh variable set GITOPS_STORE_FRONT_FILE --body "apps/capstone-store/base/aks-store-quickstart.yaml"

Verify:

    gh variable list

Expected variables:

    ACR_LOGIN_SERVER
    ACR_NAME
    GITOPS_BRANCH
    GITOPS_REPO
    GITOPS_STORE_FRONT_FILE

## Important note about current GitOps path

In this stage, the workflow updates:

    apps/capstone-store/base/aks-store-quickstart.yaml

This is enough for current Dev deployment.

Later, when Dev, QA, and Prod promotion is added properly, the repo can be improved to use environment overlays:

    apps/capstone-store/base
    apps/capstone-store/overlays/dev
    apps/capstone-store/overlays/qa
    apps/capstone-store/overlays/prod

Then promotion will update environment-specific paths.

Current Stage 12 goal is Dev deployment automation first.

## Workflow file

Workflow path in app repo:

    .github/workflows/build-and-deploy-store-front-dev.yml

Workflow name:

    Build store-front and deploy Dev via GitOps

Trigger:

    workflow_dispatch

Input:

    image_tag

Example image tag:

    stage12-v1

## Workflow responsibilities

The workflow does these tasks:

    Checkout app source
    Azure login with OIDC
    Login to ACR
    Set up Docker Buildx
    Build and push store-front image
    Verify image tag in ACR
    Checkout GitOps repo
    Update Dev image tag
    Commit and push GitOps change

## Why linux/amd64 is still important

Stage 10 showed a real issue:

    no match for platform in manifest

To prevent that issue, the workflow builds:

    linux/amd64

This makes the image compatible with AKS Linux nodes.

## Run Stage 12 workflow

Using GitHub UI:

    Repository
        -> Actions
        -> Build store-front and deploy Dev via GitOps
        -> Run workflow
        -> image_tag = stage12-v1

Using GitHub CLI:

    gh workflow run "Build store-front and deploy Dev via GitOps" -f image_tag=stage12-v1

Watch run:

    gh run watch

View latest runs:

    gh run list --limit 5

## Successful workflow result

Expected successful steps:

    Checkout app source
    Azure login with OIDC
    Login to ACR
    Set up Docker Buildx
    Build and push store-front image
    Verify image tag in ACR
    Checkout GitOps repo
    Update Dev image tag in GitOps repo
    Commit and push GitOps change

Observed result:

    Workflow completed with success.

## Node.js 20 deprecation warning

GitHub Actions may show this warning:

    Node.js 20 actions are deprecated

This is a warning, not a failure.

The workflow can still complete successfully.

Future improvement:

    Update GitHub Actions versions when Node.js 24 compatible versions are available.

## Verify ACR image tag

After workflow success, check ACR tags:

    az acr repository show-tags \
      --name <your-acr-name> \
      --repository store-front \
      -o table

Expected:

    stage10-v1
    stage11-v1
    stage12-v1

Meaning:

    stage10-v1:
      manual local build and push

    stage11-v1:
      GitHub Actions build and push

    stage12-v1:
      GitHub Actions build, push, and GitOps update

## Verify GitOps repo update

Go to GitOps repo:

    cd <local-path>/aks-capstone-gitops

Pull latest changes:

    git pull

Check store-front image line:

    grep -n "store-front" -A 40 apps/capstone-store/base/aks-store-quickstart.yaml | grep "image:"

Expected:

    image: <your-acr-login-server>/store-front:stage12-v1

Check recent Git commits:

    git log --oneline -5

Expected commit message:

    Deploy store-front stage12-v1 to dev

## Verify Argo CD status

Check Argo CD application:

    kubectl get application capstone-store-dev -n argocd

Expected:

    capstone-store-dev   Synced   Healthy

If it shows OutOfSync or Progressing, wait for a short time and check again.

## Verify AKS rollout

Check rollout:

    kubectl rollout status deployment/store-front -n capstone-dev

Expected:

    deployment "store-front" successfully rolled out

Check deployment image:

    kubectl get deployment store-front -n capstone-dev -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

Expected:

    <your-acr-login-server>/store-front:stage12-v1

Check pod:

    kubectl get pods -n capstone-dev -l app=store-front -o wide

Expected:

    store-front pod is 1/1 Running

## Find Gateway public IP

Do not guess the Gateway public service name.

First find LoadBalancer services:

    kubectl get svc -A | grep LoadBalancer

Or search gateway-related services:

    kubectl get svc -A | grep -E 'LoadBalancer|gateway|nginx'

Identify the LoadBalancer service that has an external IP.

Example pattern:

    <gateway-namespace>   <gateway-service-name>   LoadBalancer   <cluster-ip>   <gateway-public-ip>

Set variable:

    export GATEWAY_PUBLIC_IP="<gateway-public-ip>"

Test Gateway:

    curl -I http://$GATEWAY_PUBLIC_IP

Expected:

    HTTP/1.1 200 OK

## Important Gateway lesson

NGINX Gateway Fabric controller service can be ClusterIP.

The actual public traffic entry service can be a different LoadBalancer service in another namespace.

Therefore:

    Do not hardcode or assume service name.
    Find the LoadBalancer service first.
    Then test using its external IP.

## Final verified state

Stage 12 final verified state:

    GitHub Actions:
      Build store-front and deploy Dev via GitOps
      Status: Success

    ACR:
      store-front:stage12-v1 exists

    GitOps:
      store-front image updated to stage12-v1

    Argo CD:
      capstone-store-dev Synced / Healthy

    AKS:
      store-front deployment successfully rolled out
      store-front pod 1/1 Running

    Gateway:
      HTTP 200

## Production learning points

### 1. CI should not directly deploy with kubectl

Better pattern:

    CI updates GitOps repo
    Argo CD deploys

This keeps deployment desired state in Git.

### 2. GitOps repo is the deployment source of truth

The cluster should match GitOps repo.

If GitOps repo says:

    store-front:stage12-v1

Argo CD makes the cluster run:

    store-front:stage12-v1

### 3. App repo and GitOps repo are separate

App repo builds the image.

GitOps repo declares which image should run.

This separation is common in production.

### 4. One branch can manage multiple environments

A GitOps repo can use one main branch and separate environment folders.

Example future structure:

    overlays/dev
    overlays/qa
    overlays/prod

Argo CD apps can watch different paths in the same branch.

This avoids unnecessary branch drift.

### 5. Build once, promote the same image

Future promotion flow should not rebuild for QA or Prod.

Good pattern:

    Build store-front:sha-or-version once
    Deploy same image to Dev
    Promote same image to QA
    Promote same image to Prod

## Troubleshooting

### Issue 1 - GitOps repo checkout fails

Possible reasons:

    GITOPS_REPO_TOKEN missing
    Token does not have access to GitOps repo
    Token does not have Contents read/write permission

Check:

    gh secret list

Fix:

    Create fine-grained token with access to GitOps repo.
    Give Contents read/write permission.
    Save as GITOPS_REPO_TOKEN.

### Issue 2 - GitOps file path wrong

Symptom:

    sed: file not found
    grep cannot find image line

Check variable:

    gh variable list

Expected:

    GITOPS_STORE_FRONT_FILE

Fix:

    Set correct manifest path.

### Issue 3 - No GitOps changes to commit

Reason:

    The GitOps repo already has the same image tag.

This is not always an error.

The workflow can exit safely if no diff exists.

### Issue 4 - Argo CD not updated

Check Argo CD:

    kubectl get application capstone-store-dev -n argocd

Check GitOps latest commit:

    git log --oneline -5

Possible reasons:

    Argo CD has not refreshed yet
    Wrong GitOps path
    Wrong Argo CD application source path

### Issue 5 - Store-front still old image

Check deployment image:

    kubectl get deployment store-front -n capstone-dev -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

If old image remains:

    Check GitOps repo image tag
    Check Argo CD sync status
    Check Argo CD application source path

### Issue 6 - Pod ImagePullBackOff

Check pod:

    kubectl describe pod <pod-name> -n capstone-dev

Possible reasons:

    AKS cannot pull from ACR
    Image tag does not exist
    Wrong image architecture

Fixes:

    Verify ACR tag exists
    Verify AKS has AcrPull permission
    Build image with linux/amd64

## Learner summary

Stage 12 is where CI/CD starts to feel real.

Key lesson:

    GitHub Actions does not directly deploy to Kubernetes.
    It builds the image and updates GitOps desired state.
    Argo CD watches GitOps and deploys Dev.

This gives a clean production-style delivery flow:

    App source code
        -> CI image build
        -> ACR
        -> GitOps image tag update
        -> Argo CD
        -> AKS Dev deployment

Next stage:

    Stage 13 - Add DevSecOps checks to the app CI pipeline
