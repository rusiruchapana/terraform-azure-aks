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

## GitOps token secret එක set කිරීම

App repo workflow එකට GitOps repo එකට commit push කරන්න permission ඕන.

ඒ permission එක GitHub secret එකක් විදිහට save කරනවා.

Secret name එක:

    GITOPS_REPO_TOKEN

App repo එකේ සිට run කරන්න:

    gh secret set GITOPS_REPO_TOKEN

Prompt එක ආවම GitOps repo එකට write permission තියෙන token එක paste කරන්න.

Verify කරන්න:

    gh secret list

Expected result එකේ මේ secret එක පේන්න ඕන:

    GITOPS_REPO_TOKEN

Security note:

    මේ token එකට GitOps repo එකට විතරක් access දෙන්න.
    Contents read/write permission විතරක් දෙන්න.
    Full account access දෙන්න එපා.

## GitOps variables set කිරීම

Stage 12 workflow එකට GitOps repo details variables විදිහට දෙන්න ඕන.

App repo එකේ සිට run කරන්න:

    gh variable set GITOPS_REPO --body "<github-owner>/<gitops-repo>"
    gh variable set GITOPS_BRANCH --body "main"
    gh variable set GITOPS_STORE_FRONT_FILE --body "apps/capstone-store/base/aks-store-quickstart.yaml"

Verify කරන්න:

    gh variable list

Expected variables:

    ACR_LOGIN_SERVER
    ACR_NAME
    GITOPS_BRANCH
    GITOPS_REPO
    GITOPS_STORE_FRONT_FILE

මේ variables වල meaning එක:

    GITOPS_REPO:
      update කරන්න ඕන GitOps repo එක

    GITOPS_BRANCH:
      GitOps repo branch එක

    GITOPS_STORE_FRONT_FILE:
      store-front image line එක තියෙන manifest file එක

## Current GitOps path ගැන වැදගත් note එක

මේ stage එකේදී workflow එක update කරන්නේ:

    apps/capstone-store/base/aks-store-quickstart.yaml

දැනට Dev deployment එකට මේක ප්‍රමාණවත්.

නමුත් later Dev, QA, Prod promotion properly build කරනකොට GitOps repo structure එක මෙහෙම improve කරන්න පුළුවන්:

    apps/capstone-store/base
    apps/capstone-store/overlays/dev
    apps/capstone-store/overlays/qa
    apps/capstone-store/overlays/prod

එතකොට Dev update එක dev overlay එකට යනවා.
QA promotion එක qa overlay එකට යනවා.
Prod promotion එක prod overlay එකට යනවා.

Stage 12 goal එක Dev deployment automation prove කිරීමයි.

## Workflow file එක

App repo එකේ workflow file path එක:

    .github/workflows/build-and-deploy-store-front-dev.yml

Workflow name එක:

    Build store-front and deploy Dev via GitOps

Trigger එක:

    workflow_dispatch

ඒ කියන්නේ workflow එක manual trigger කරන්න පුළුවන්.

Input එක:

    image_tag

Example tag එක:

    stage12-v1

## Workflow එක කරන වැඩ

මේ workflow එක මේ steps කරයි:

    App source checkout කිරීම
    Azure OIDC login කිරීම
    ACR login කිරීම
    Docker Buildx setup කිරීම
    store-front image build කිරීම
    image එක ACR එකට push කිරීම
    ACR tag verify කිරීම
    GitOps repo checkout කිරීම
    Dev image tag update කිරීම
    GitOps repo එකට commit and push කිරීම

## linux/amd64 තවමත් වැදගත් ඇයි?

Stage 10 වලදී අපි real issue එකක් දැක්කා:

    no match for platform in manifest

ඒක image architecture mismatch issue එකක්.

ඒ නිසා Stage 12 workflow එකේත් image build කරන්නේ:

    linux/amd64

මේකෙන් AKS Linux nodes වල image pull/run issue එක avoid වෙනවා.

## Stage 12 workflow එක run කිරීම

GitHub UI එකෙන් run කරන්න:

    Repository
        -> Actions
        -> Build store-front and deploy Dev via GitOps
        -> Run workflow
        -> image_tag = stage12-v1

GitHub CLI එකෙන් run කරන්න:

    gh workflow run "Build store-front and deploy Dev via GitOps" -f image_tag=stage12-v1

Running workflow එක watch කරන්න:

    gh run watch

Recent workflow runs බලන්න:

    gh run list --limit 5

## Successful workflow result එක

Success run එකකදී මේ steps pass වෙන්න ඕන:

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

GitHub Actions warning එකක් පේන්න පුළුවන්:

    Node.js 20 actions are deprecated

මේක failure එකක් නෙවෙයි.

Workflow එක success නම් Stage 12 block වෙන්නේ නැහැ.

Future improvement එකක් ලෙස actions versions update කරන්න පුළුවන්.

## ACR image tag verify කිරීම

Workflow success වුණාට පස්සේ ACR tags check කරන්න:

    az acr repository show-tags \
      --name <your-acr-name> \
      --repository store-front \
      -o table

Expected tags:

    stage10-v1
    stage11-v1
    stage12-v1

Meaning:

    stage10-v1:
      local machine එකෙන් manual build/push කළ image එක

    stage11-v1:
      GitHub Actions build/push කළ image එක

    stage12-v1:
      GitHub Actions build/push කරලා GitOps update කළ image එක

## GitOps repo update verify කිරීම

GitOps repo එකට යන්න:

    cd <local-path>/aks-capstone-gitops

Latest changes pull කරන්න:

    git pull

store-front image line එක check කරන්න:

    grep -n "store-front" -A 40 apps/capstone-store/base/aks-store-quickstart.yaml | grep "image:"

Expected:

    image: <your-acr-login-server>/store-front:stage12-v1

Recent Git commits check කරන්න:

    git log --oneline -5

Expected commit message එකක්:

    Deploy store-front stage12-v1 to dev

මේකෙන් confirm වෙනවා app repo pipeline එක GitOps repo එකට commit push කරලා තියෙනවා කියලා.

## Argo CD status verify කිරීම

Argo CD application එක check කරන්න:

    kubectl get application capstone-store-dev -n argocd

Expected:

    capstone-store-dev   Synced   Healthy

සමහර වෙලාවට GitOps commit එක push වුණාට පස්සේ ටික වෙලාවක්:

    OutOfSync
    Progressing

වගේ පේන්න පුළුවන්.

ටිකක් wait කරලා නැවත check කරන්න.

## AKS rollout verify කිරීම

store-front deployment rollout status බලන්න:

    kubectl rollout status deployment/store-front -n capstone-dev

Expected:

    deployment "store-front" successfully rolled out

Deployment image එක check කරන්න:

    kubectl get deployment store-front -n capstone-dev -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

Expected:

    <your-acr-login-server>/store-front:stage12-v1

Pod status බලන්න:

    kubectl get pods -n capstone-dev -l app=store-front -o wide

Expected:

    store-front pod එක 1/1 Running

## Gateway public IP හොයාගැනීම

Gateway public IP එක guess කරන්න එපා.

මුලින් LoadBalancer services බලන්න:

    kubectl get svc -A | grep LoadBalancer

නැත්නම් gateway/nginx related services බලන්න:

    kubectl get svc -A | grep -E 'LoadBalancer|gateway|nginx'

External IP තියෙන LoadBalancer service එක identify කරන්න.

Pattern එක:

    <gateway-namespace>   <gateway-service-name>   LoadBalancer   <cluster-ip>   <gateway-public-ip>

Gateway IP එක variable එකකට දාන්න:

    export GATEWAY_PUBLIC_IP="<gateway-public-ip>"

Gateway test කරන්න:

    curl -I http://$GATEWAY_PUBLIC_IP

Expected:

    HTTP/1.1 200 OK

## Gateway lesson එක

NGINX Gateway Fabric controller service එක ClusterIP විය හැක.

Actual public traffic entry service එක වෙන namespace එකක LoadBalancer service එකක් විය හැක.

ඒ නිසා:

    service name එක assume කරන්න එපා
    LoadBalancer service එක හොයාගන්න
    external IP එකෙන් test කරන්න

## Final verified state

Stage 12 final state එක:

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

### 1. CI workflow එක kubectl apply නොකරයි

Better production pattern එක:

    CI updates GitOps repo
    Argo CD deploys

මෙයින් deployment desired state එක Git repo එකේ audit කරන්න පුළුවන්.

### 2. GitOps repo එක deployment source of truth එකයි

GitOps repo එකේ image tag එක වෙනස් වුණාම Argo CD ඒ desired state එක cluster එකට apply කරනවා.

Example:

    GitOps repo says:
      store-front:stage12-v1

    Argo CD makes AKS run:
      store-front:stage12-v1

### 3. App repo සහ GitOps repo වෙන වෙනම තියෙනවා

App repo එක image build කරනවා.

GitOps repo එක run වෙන්න ඕන image version එක declare කරනවා.

මේ separation එක production වල common pattern එකක්.

### 4. Single main branch එකෙන් multiple environments manage කරන්න පුළුවන්

GitOps repo එකේ one main branch + environment folders pattern එක use කරන්න පුළුවන්.

Future structure:

    overlays/dev
    overlays/qa
    overlays/prod

Argo CD apps තුනක් same branch එකේ different paths watch කරන්න පුළුවන්.

### 5. Build once, promote same image

Future promotion flow එකේ QA/Prod වලට image rebuild කරන්න හොඳ නැහැ.

Good pattern:

    Build image once
    Deploy same image to Dev
    Promote same image to QA
    Promote same image to Prod

## Troubleshooting

### Issue 1 - GitOps repo checkout fails

Possible reasons:

    GITOPS_REPO_TOKEN missing
    Token එකට GitOps repo access නැහැ
    Token එකට Contents read/write permission නැහැ

Check:

    gh secret list

Fix:

    Fine-grained token එකක් create කරන්න.
    GitOps repo එකට access දෙන්න.
    Contents read/write permission දෙන්න.
    GITOPS_REPO_TOKEN ලෙස save කරන්න.

### Issue 2 - GitOps file path wrong

Symptoms:

    sed: file not found
    grep cannot find image line

Check variables:

    gh variable list

Expected:

    GITOPS_STORE_FRONT_FILE

Fix:

    Correct manifest path එක variable එකට set කරන්න.

### Issue 3 - No GitOps changes to commit

Reason:

    GitOps repo එකේ already same image tag එක තියෙන්න පුළුවන්.

මෙය හැමවිටම error එකක් නෙවෙයි.

Workflow එක no diff නම් safely exit වෙන්න පුළුවන්.

### Issue 4 - Argo CD update නොවීම

Check:

    kubectl get application capstone-store-dev -n argocd

GitOps latest commit check කරන්න:

    git log --oneline -5

Possible reasons:

    Argo CD refresh වීමට තව වෙලාවක් ගන්නවා
    wrong GitOps path
    wrong Argo CD application source path

### Issue 5 - store-front තවම old image එක use කිරීම

Check:

    kubectl get deployment store-front -n capstone-dev -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

If old image remains:

    GitOps repo image tag check කරන්න
    Argo CD sync status check කරන්න
    Argo CD application source path check කරන්න

### Issue 6 - Pod ImagePullBackOff

Check:

    kubectl describe pod <pod-name> -n capstone-dev

Possible reasons:

    AKS cannot pull from ACR
    Image tag does not exist
    Wrong image architecture

Fix:

    ACR tag exists ද check කරන්න
    AKS AcrPull permission check කරන්න
    linux/amd64 image build කරන්න

## Learner summary

Stage 12 එකෙන් CI/CD flow එක real විදිහට connect වුණා.

Key lesson:

    GitHub Actions Kubernetes cluster එකට direct deploy කරන්නේ නැහැ.
    GitHub Actions image build කරලා GitOps repo එක update කරනවා.
    Argo CD GitOps repo එක watch කරලා Dev environment එක deploy කරනවා.

Final flow:

    App source code
        -> CI image build
        -> ACR
        -> GitOps image tag update
        -> Argo CD
        -> AKS Dev deployment

Next stage:

    Stage 13 - App CI pipeline එකට DevSecOps checks add කිරීම
