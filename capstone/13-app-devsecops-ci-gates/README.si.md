# Stage 13 - App DevSecOps CI Gates Add කිරීම

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි Stage 12 CI/CD workflow එකට DevSecOps security gates add කරනවා.

Stage 12 flow එක:

    GitHub Actions
        -> build image
        -> push to ACR
        -> update GitOps repo
        -> Argo CD deploys Dev

Stage 13 flow එක:

    GitHub Actions
        -> secret scan
        -> filesystem/dependency scan
        -> build image
        -> image vulnerability scan
        -> push/verify image
        -> update GitOps repo
        -> Argo CD deploys Dev

මේකෙන් unsafe code/image Dev environment එකට deploy වීම නවත්තන්න පුළුවන්.

## මේ stage එක වැදගත් ඇයි?

CI/CD pipeline එකක් image build කරලා deploy කරන එක විතරක් ප්‍රමාණවත් නැහැ.

Production වලදී deploy වීමට පෙර security checks pass වීම වැදගත්.

මෙහිදී අපි add කරන gates:

    Gitleaks:
      source code secrets scan

    Trivy filesystem scan:
      app source/dependency/config vulnerability scan

    Trivy image scan:
      built container image vulnerability scan

## Stage 13 scope

මේ stage එකේ scope එක:

    App repo DevSecOps checks
    store-front component scan
    image build and image scan
    GitOps Dev update
    Argo CD Dev deployment verification

මේ stage එකේ scope එකට අයිති නැති දේවල්:

    Terraform scan
    GitOps manifest validation
    QA promotion
    Prod promotion

Terraform scan එක later platform repo එකේ වෙනම pipeline එකක් ලෙස add කරනවා.

## App repo vs GitOps repo vs Terraform repo

මේ project එක repo කිහිපයකින් යනවා.

App repo:

    aks-capstone-store-app

මෙහිදී app code, Dockerfile, GitHub Actions app CI pipeline තියෙනවා.

GitOps repo:

    aks-capstone-gitops

මෙහිදී Kubernetes desired state තියෙනවා.

Terraform repo:

    terraform-azure-aks

මෙහිදී AKS platform, networking, ACR, Gateway, monitoring වගේ infrastructure docs/config තියෙනවා.

Stage 13 අයිති app repo pipeline එකටයි.

## Workflow file

App repo workflow file:

    .github/workflows/build-and-deploy-store-front-dev.yml

Workflow name:

    Build store-front and deploy Dev via GitOps

Stage 13 වලදී අපි මෙම workflow එකට DevSecOps gates add කළා.

## DevSecOps pipeline order

Final workflow order එක:

    Checkout app source
    Secret scan with Gitleaks
    Filesystem and dependency scan with Trivy
    Azure login with OIDC
    Login to ACR
    Set up Docker Buildx
    Build and push store-front image
    Container image vulnerability scan with Trivy
    Verify image tag in ACR
    Checkout GitOps repo
    Update Dev image tag in GitOps repo
    Commit and push GitOps change

## Gitleaks secret scan

Gitleaks source code එකේ secrets තියෙනවාද කියලා scan කරනවා.

Examples:

    passwords
    API keys
    tokens
    Kubernetes Secret YAML values
    private keys

Secret scan fail වුණොත් pipeline එක build/deploy steps run කරන්නේ නැහැ.

මෙහි production meaning එක:

    Secret leaked code එක image එකක් බවට build වෙන්න කලින්ම pipeline එක stop වෙනවා.

## First issue - Gitleaks failed

Stage 13 මුල් run එකේ Gitleaks failed වුණා.

Detected rule:

    kubernetes-secret-yaml

Detected files:

    aks-store-all-in-one.yaml
    aks-store-ingress-quickstart.yaml

මේ files upstream Microsoft AKS Store Demo sample repo එකෙන් inherited වුණ files.

මෙම files අපේ current capstone GitOps deployment flow එකට use වෙන්නේ නැහැ.

අපේ deployment source of truth එක:

    aks-capstone-gitops repo

## Why we did not blindly delete files

මුලින් files delete කරන එක option එකක් වගේ පේන්න පුළුවන්.

නමුත් ඒක risky.

හේතු:

    Upstream sample repo reference files නැති වෙන්න පුළුවන්
    README/Makefile references break වෙන්න පුළුවන්
    Future learners compare කරන්න use කරන sample files නැති වෙන්න පුළුවන්

ඒ නිසා safer approach එක:

    files keep කරන්න
    capstone deployment එකට use නොවන known sample manifests allowlist කරන්න
    secret scan එක real source code එකට active තියාගන්න

## Gitleaks allowlist config

App repo එකේ `.gitleaks.toml` file එක add කළා.

Purpose එක:

    Known upstream sample Kubernetes Secret manifests ignore කිරීම

Important:

    මේකෙන් full secret scanning disable වෙන්නේ නැහැ.
    Only specific known sample files allowlist වෙනවා.

Example concept:

    allow known upstream sample manifests
    continue scanning all other files

මෙය production වලදී careful decision එකක්.

Real secret එකක් නම් allowlist කරන්න එපා.
Secret rotate/remove කරන්න.

## Current-tree scan

Adapted sample repo එකක old upstream history එකේ sample secrets තිබුණොත් full history scan learning pipeline එක block වෙන්න පුළුවන්.

මේ stage එකේ අපි practical current-source scan එක use කළා:

    detect --source=/repo --no-git --redact --verbose --config=/repo/.gitleaks.toml

Meaning:

    current working tree scan වෙනවා
    secret values redact වෙනවා
    known sample manifest files allowlist වෙනවා

## Trivy filesystem scan

Trivy filesystem scan එක app source/dependency/config issues detect කරනවා.

මුලින් workflow එක repo root එක scan කළා:

    scan-ref: .

මේක monorepo/project repo එකකට problem එකක් වුණා.

## Second issue - Trivy root scan failed

Trivy root scan එක repo එකේ other services වල vulnerabilities detect කළා.

Examples:

    ai-service dependencies
    product-service dependencies
    order-service dependencies

නමුත් Stage 13 pipeline එක build/deploy කරන්නේ:

    store-front only

ඒ නිසා store-front deploy එක වෙන services වල vulnerabilities නිසා block වුණා.

## Fix - Scope filesystem scan to store-front

store-front workflow එකේ filesystem scan එක store-front source path එකට scope කළා.

Updated scan target:

    ./src/store-front

Reason:

    Component-specific pipeline එකක් නම් scan scope එක ඒ component එකට align වෙන්න ඕන.

Final concept:

    store-front pipeline scans store-front source
    product-service pipeline should scan product-service source
    order-service pipeline should scan order-service source

## Trivy image scan

Filesystem scan එක source code side එක බලනවා.

Image scan එක actual built container image එක බලනවා.

Stage 13 image scan target:

    <your-acr-login-server>/store-front:stage13-v1

This is important because final runtime image එකේ vulnerabilities තිබුණොත් deploy block වෙන්න ඕන.

## Multi-stage Docker build lesson

Build log එකේ npm install අතරතුර npm audit warnings තිබුණා.

Example:

    moderate/high/critical npm audit warnings

නමුත් final Trivy image scan result එක:

    Vulnerabilities: 0

Reason එක multi-stage Docker build වෙන්න පුළුවන්.

Typical store-front Docker flow:

    builder stage:
      Node dependencies install කරලා frontend build කරනවා

    runner stage:
      nginx image එකට built static files copy කරනවා

Final runtime image එකේ Node dependencies නැති වෙන්න පුළුවන්.

ඒ නිසා image scan clean වුණා.

Important lesson:

    npm audit warning ignore කරන්න කියන එක නෙවෙයි.
    Source dependency scan සහ final image scan දෙකම වෙනස් purpose තියෙනවා.

## Stage 13 workflow run කිරීම

App repo එකේ සිට run කරන්න:

    gh workflow run "Build store-front and deploy Dev via GitOps" -f image_tag=stage13-v1

Workflow run watch කරන්න:

    gh run watch

Expected gates:

    Secret scan with Gitleaks                  pass
    Filesystem and dependency scan with Trivy  pass
    Build and push store-front image           pass
    Container image vulnerability scan         pass
    GitOps update                              pass

## ACR verification

Workflow success පස්සේ ACR tags බලන්න:

    az acr repository show-tags \
      --name <your-acr-name> \
      --repository store-front \
      -o table

Expected:

    stage10-v1
    stage11-v1
    stage12-v1
    stage13-v1

Meaning:

    stage13-v1 image එක DevSecOps gates pass වුණ පසු build/push වුණ image එකයි.

## GitOps verification

GitOps repo එකට යන්න:

    cd <local-path>/aks-capstone-gitops

Latest changes pull කරන්න:

    git pull

Recent commits බලන්න:

    git log --oneline -5

Expected commit:

    Deploy store-front stage13-v1 to dev

Image line check කරන්න:

    grep -n "store-front" -A 40 apps/capstone-store/base/aks-store-quickstart.yaml | grep "image:"

Expected:

    image: <your-acr-login-server>/store-front:stage13-v1

## Argo CD revision verification

Argo CD application revision එක සහ GitOps repo HEAD එක compare කරන්න.

    kubectl get application capstone-store-dev -n argocd \
      -o jsonpath='{.status.sync.revision}{"\n"}'

    git rev-parse HEAD

Expected:

    Both commit hashes should match.

මෙය වැදගත්, මොකද GitOps repo update වුණා කියලා cluster එක latest revision එක sync කරලා තියෙනවාද කියලා වෙනම verify කරන්න ඕන.

## Argo CD hard refresh lesson

Stage 13 verification අතරතුර Argo CD revision එක latest GitOps commit එකට match නොවුණා.

Hard refresh කළා:

    kubectl annotate application capstone-store-dev -n argocd \
      argocd.argoproj.io/refresh=hard \
      --overwrite

ඊට පස්සේ Argo CD latest revision එක pick කරලා rollout complete කළා.

Production lesson:

    GitOps commit pushed වුණා කියලා immediate cluster update assume කරන්න එපා.
    Argo CD revision, sync status, and deployment image verify කරන්න.

## AKS deployment verification

Argo CD status බලන්න:

    kubectl get application capstone-store-dev -n argocd

Expected:

    Synced
    Healthy

Rollout status බලන්න:

    kubectl rollout status deployment/store-front -n capstone-dev

Expected:

    deployment "store-front" successfully rolled out

Deployment image check කරන්න:

    kubectl get deployment store-front -n capstone-dev \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

Expected:

    <your-acr-login-server>/store-front:stage13-v1

Pod status බලන්න:

    kubectl get pods -n capstone-dev -l app=store-front -o wide

Expected:

    store-front pod 1/1 Running

## Gateway verification

LoadBalancer service එක හොයාගන්න:

    kubectl get svc -A | grep LoadBalancer

Gateway test කරන්න:

    curl -I http://<gateway-public-ip>

Expected:

    HTTP/1.1 200 OK

Guide වල live public IP hardcode කරන්න එපා.

Use placeholder:

    <gateway-public-ip>

## Final verified state - අවසාන verified තත්ත්වය

Stage 13 අවසානයේ verify කළ තත්ත්වය මෙහෙමයි.

GitHub Actions workflow එක:

    DevSecOps workflow success

Gitleaks secret scan එක:

    Passed

Trivy filesystem scan එක:

    ./src/store-front path එකට scoped කරලා pass වුණා

Docker image එක:

    store-front:stage13-v1 build කරලා ACR එකට push වුණා

Trivy image scan එක:

    final runtime image එකේ vulnerabilities 0 ලෙස report වුණා

GitOps repo එක:

    Deploy store-front stage13-v1 to dev commit එක push වුණා

Argo CD:

    GitOps HEAD revision එකට match වුණා
    Synced / Healthy වුණා

AKS:

    store-front deployment එක stage13-v1 image එක run කළා
    pod එක 1/1 Running වුණා

Gateway:

    HTTP 200 response එක ලැබුණා

## Production learning points - production වලට වැදගත් පාඩම්

### 1. DevSecOps gates deployment එක block කරන්න ඕන

Stage 13 මුලින් Gitleaks step එකේදී fail වුණා.

ඊට පස්සේ Trivy filesystem scan එකේදී fail වුණා.

මේක වැරැද්දක් නෙවෙයි. ඒක DevSecOps gate එකේ purpose එක.

Security හෝ quality issue එකක් clear නැත්නම්:

    image build නොවෙන්න ඕන
    image push නොවෙන්න ඕන
    GitOps repo update නොවෙන්න ඕන
    Dev deploy නොවෙන්න ඕන

ඒකෙන් unsafe change එකක් environment එකට යාම නවත්වනවා.

### 2. Finding එකක් ආවම investigate කරන්න ඕන

Security tool එකක් issue එකක් detect කළා කියලා හැම වෙලාවෙම file delete කරන්න හොඳ නැහැ.

මුලින් අහන්න ඕන ප්‍රශ්න:

    මේක real secret එකක්ද?
    මේක sample/demo file එකක්ද?
    මේ file එක actual deployment එකට use වෙනවද?
    මේක current source එකේද, නැත්නම් old git history එකේද?
    මේ issue එක මේ component එකට relevant ද?

Stage 13 වලදී Gitleaks detect කළ files upstream sample Kubernetes Secret YAML files.

ඒ නිසා අපි files blind delete කළේ නැහැ.

අපි කළේ:

    files keep කළා
    known sample manifests narrow allowlist කළා
    secret scan එක අනෙක් files වලට active තියාගත්තා

### 3. Monorepo එකක scan scope එක හරි වෙන්න ඕන

Repo එකේ services කිහිපයක් තියෙනවා නම් root scan එකකින් අනිත් services වල issues detect වෙන්න පුළුවන්.

Stage 13 pipeline එක deploy කළේ:

    store-front

ඒ නිසා blocking filesystem scan එකට use කළ path එක:

    ./src/store-front

මෙහි අදහස:

    store-front pipeline එක store-front source scan කරනවා
    product-service pipeline එක product-service source scan කරන්න ඕන
    order-service pipeline එක order-service source scan කරන්න ඕන

Full repo security scan එකක් වෙනම scheduled workflow එකක් ලෙස add කරන්න පුළුවන්.

### 4. Source scan සහ image scan එකම දෙයක් නෙවෙයි

Trivy filesystem scan එක බලන්නේ:

    source files
    dependency files
    config files

Trivy image scan එක බලන්නේ:

    final container image එක

මේ දෙකම වැදගත්.

Source scan එක development side risk හොයනවා.

Image scan එක runtime artifact එකේ risk හොයනවා.

### 5. Multi-stage Docker build එක නිසා final image clean වෙන්න පුළුවන්

Build log එකේ npm audit warnings තිබුණත් final image scan එක 0 vulnerabilities කියලා පෙන්වන්න පුළුවන්.

හේතුව:

    builder stage එකේ Node dependencies install වෙනවා
    frontend build output එක generate වෙනවා
    runtime stage එකේ nginx image එකට static files copy වෙනවා

Final runtime image එකේ Node dependencies නැති නම්, image scan එක clean වෙන්න පුළුවන්.

නමුත් npm audit warnings ignore කරන්න කියන එක නෙවෙයි.

ඒ නිසා source scan එකත් තියාගන්න ඕන, image scan එකත් තියාගන්න ඕන.

### 6. GitOps update වුණා කියලා cluster update assume කරන්න එපා

GitOps repo එකට commit එක push වුණා කියලා cluster එක ඒ මොහොතේම update වෙලා කියලා assume කරන්න බැහැ.

Separate verification ඕන:

    GitOps repo image line එක check කරන්න
    Argo CD revision එක GitOps HEAD එකට match වෙනවද බලන්න
    Argo CD Synced / Healthy ද බලන්න
    AKS deployment image එක check කරන්න
    pod Running ද බලන්න
    Gateway HTTP 200 ද බලන්න

Stage 13 වලදී Argo CD revision එක initially behind තිබුණා.

Hard refresh කළාට පස්සේ latest GitOps commit එක pick කරලා rollout complete වුණා.

## Troubleshooting - ගැටළු විසඳීම

### Issue 1 - Gitleaks Kubernetes Secret YAML detect කරනවා

Gitleaks output එකෙන් මේ details බලන්න:

    RuleID
    File
    Line
    Fingerprint

Secret value එක chat, ticket, documentation වල paste කරන්න එපා.

If real secret එකක් නම්:

    secret එක rotate/revoke කරන්න
    repo එකෙන් remove කරන්න
    GitHub Secrets / Azure Key Vault වගේ secure place එකකට move කරන්න

If known sample manifest එකක් නම්:

    reason එක document කරන්න
    narrow allowlist එකක් use කරන්න
    full scan disable කරන්න එපා

### Issue 2 - Trivy filesystem scan unrelated services නිසා fail වෙනවා

මෙය monorepo/project repo වල common issue එකක්.

Pipeline එක deploy කරන්නේ store-front නම්:

    scan-ref: ./src/store-front

Root scan එකක් අවශ්‍ය නම් ඒක වෙනම full-repo security workflow එකක් ලෙස තියාගන්න.

### Issue 3 - Trivy image scan fail වෙනවා

Image scan fail වුණොත් ඒක serious.

මොකද ඒ scan එක actual run වෙන container image එක scan කරනවා.

Possible fixes:

    base image update කරන්න
    package versions update කරන්න
    dependency versions patch කරන්න
    image rebuild කරන්න

Image scan fail වෙලා තියෙද්දී GitOps update/deploy යන්න හොඳ නැහැ.

### Issue 4 - GitOps commit push වුණත් cluster එක old image එක run කරනවා

Argo CD revision එක check කරන්න:

    kubectl get application capstone-store-dev -n argocd \
      -o jsonpath='{.status.sync.revision}{"\n"}'

GitOps repo HEAD එක check කරන්න:

    git rev-parse HEAD

මේ දෙක match වෙන්න ඕන.

If Argo CD revision එක behind නම්:

    ටිකක් wait කරන්න

නැත්නම් hard refresh කරන්න:

    kubectl annotate application capstone-store-dev -n argocd \
      argocd.argoproj.io/refresh=hard \
      --overwrite

ඊට පස්සේ rollout verify කරන්න.

### Issue 5 - gh run command wrong repo එකේ run කරනවා

Stage 13 workflow run එක තියෙන්නේ app repo එකේ.

App pipeline commands run කරන්න:

    aks-capstone-store-app

GitOps verification commands run කරන්න:

    aks-capstone-gitops

Terraform guide/documentation commands run කරන්න:

    terraform-azure-aks

Repo එක confuse වුණොත් මේ command එකෙන් current repo බලන්න:

    git remote -v

## Learner summary - ඉගෙනගන්න ප්‍රධාන අදහස

Stage 13 එකෙන් pipeline එක real DevSecOps pipeline එකක් වුණා.

Before Stage 13:

    image build වුණා
    image push වුණා
    GitOps update වුණා
    Dev deploy වුණා

After Stage 13:

    security gates pass වුණොත් විතරයි build/push/deploy වෙන්නේ

Final flow එක:

    Secret scan
        -> dependency/source scan
        -> build image
        -> image scan
        -> push image
        -> update GitOps repo
        -> Argo CD deploys Dev

මේක production-style delivery flow එකක්.

Next stage:

    Stage 14 - GitOps manifest validation pipeline
