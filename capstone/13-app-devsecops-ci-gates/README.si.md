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

## Final verified state

Stage 13 final verified state:

    GitHub Actions:
      DevSecOps workflow success

    Gitleaks:
      Passed

    Trivy filesystem scan:
      Passed for ./src/store-front

    Docker image:
      store-front:stage13-v1 built and pushed

    Trivy image scan:
      0 vulnerabilities detected in final runtime image

    GitOps:
      Deploy store-front stage13-v1 to dev commit pushed

    Argo CD:
      Revision matched GitOps HEAD
      Synced / Healthy

    AKS:
      store-front runs stage13-v1
      pod 1/1 Running

    Gateway:
      HTTP 200

## Production learning points

### 1. DevSecOps gates must block deployment

Stage 13 first failed at Gitleaks.
Then failed at Trivy filesystem scan.

That is good.

A security gate should stop unsafe or unclear changes before deploy.

### 2. Findings need investigation

Not every finding means delete files immediately.

You must ask:

    Is it a real secret?
    Is it a sample file?
    Is it used by deployment?
    Is it in current source or old history?
    Is it relevant to this component?

### 3. Monorepo scans need correct scope

Root scan can be useful for full-repo security jobs.

But component deployment pipeline should scan the component it deploys.

For store-front:

    ./src/store-front

### 4. Source scan and image scan are different

Source scan checks source/dependencies/config.

Image scan checks final container runtime artifact.

Both are useful.

### 5. GitOps update and cluster sync are separate

GitOps commit means desired state changed.

Argo CD sync means cluster applied that desired state.

Always verify both.

## Troubleshooting

### Issue 1 - Gitleaks detects Kubernetes Secret YAML

Check finding:

    RuleID
    File
    Line
    Fingerprint

Do not paste secret values into chat or tickets.

If real secret:

    rotate/revoke it
    remove it from repo
    move it to secure secret store

If known sample manifest:

    document reason
    use narrow allowlist

### Issue 2 - Trivy filesystem scan fails on unrelated services

Check scan scope.

If pipeline deploys store-front only:

    scan-ref should be ./src/store-front

Do not block store-front deployment because of unrelated service dependency unless this is a full monorepo security workflow.

### Issue 3 - Image scan fails

This is more serious for deployment.

Image scan checks the actual image that will run.

Options:

    update base image
    update packages
    rebuild image
    use patched dependency versions

### Issue 4 - GitOps commit pushed but cluster still old image

Check Argo CD revision:

    kubectl get application capstone-store-dev -n argocd \
      -o jsonpath='{.status.sync.revision}{"\n"}'

Compare with:

    git rev-parse HEAD

If revision is behind, wait or hard refresh:

    kubectl annotate application capstone-store-dev -n argocd \
      argocd.argoproj.io/refresh=hard \
      --overwrite

### Issue 5 - gh run command fails in wrong repo

GitHub Actions run is in app repo.

Run app workflow commands from:

    aks-capstone-store-app

GitOps verification commands run from:

    aks-capstone-gitops

## Learner summary

Stage 13 is where the pipeline becomes a real DevSecOps pipeline.

Before this stage:

    Build and deploy worked

After this stage:

    Build and deploy happen only after security gates pass

Final flow:

    Secret scan
        -> dependency/source scan
        -> build image
        -> image scan
        -> push image
        -> update GitOps
        -> Argo CD deploys Dev

Next stage:

    Stage 14 - GitOps manifest validation pipeline
