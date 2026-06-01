# Professional Lab 03 - dev to qa to prod promotion

This lab shows how to promote application desired state from dev to qa to prod using Argo CD.

This is a professional GitOps lab.

The goal is to understand environment promotion through Git, not direct `kubectl apply`.

The flow is:

    Git repository
      |
      v
    Argo CD Applications
      |
      +--> promotion-demo-dev
      +--> promotion-demo-qa
      +--> promotion-demo-prod
      |
      v
    AKS namespaces
      |
      +--> promotion-dev
      +--> promotion-qa
      +--> promotion-prod

## Lab goal

By the end of this lab, you should have:

- Three GitOps desired-state folders for dev, qa, and prod
- Three Argo CD Applications
- Three AKS namespaces
- A demo app running in each environment
- dev promoted from v1 to v2
- qa promoted from v1 to v2
- prod promoted from v1 to v2
- Argo CD UI visibility for all environments
- Argo CD self-heal tested

## What you will learn

You will learn:

- How GitOps promotion works
- How dev, qa, and prod desired state can be separated
- How Argo CD tracks multiple applications
- How to promote a change environment by environment
- Why local file changes are not enough for GitOps
- How Argo CD sync and self-heal work
- How to verify promotion using kubectl and browser access
- How to clean up the promotion lab

## Architecture

This lab uses this repository as the GitOps source.

The desired state is stored under:

    gitops/apps/dev/promotion-demo
    gitops/apps/qa/promotion-demo
    gitops/apps/prod/promotion-demo

The Argo CD Application manifests are stored under:

    labs/professional/03-dev-qa-prod-promotion/argocd

Each Argo CD Application points to one environment path:

    promotion-demo-dev  -> gitops/apps/dev/promotion-demo
    promotion-demo-qa   -> gitops/apps/qa/promotion-demo
    promotion-demo-prod -> gitops/apps/prod/promotion-demo

Each environment deploys:

- Namespace
- ConfigMap
- Deployment
- Service

The app is a simple NGINX workload that serves an environment-specific HTML page from a ConfigMap.

## What this lab requires

You need:

- kubectl
- Git
- Existing AKS cluster access
- Existing Argo CD installation
- Access to the Argo CD UI
- This repository available through a Git URL that Argo CD can read

This lab does not require:

- Docker Desktop
- Azure Container Registry
- CI/CD pipeline
- Flux

## Install required local tools

### kubectl

Verify kubectl:

    kubectl version --client

### Git

Verify Git:

    git --version

## Check local tools and AKS access

Verify AKS access:

    kubectl get nodes

Check current context:

    kubectl config current-context

Verify Argo CD namespace:

    kubectl get ns argocd

Verify Argo CD pods:

    kubectl get pods -n argocd

Verify Argo CD Application CRD:

    kubectl get crd applications.argoproj.io

## Lab files

This lab uses:

    gitops/apps/dev/promotion-demo/
    gitops/apps/qa/promotion-demo/
    gitops/apps/prod/promotion-demo/

    labs/professional/03-dev-qa-prod-promotion/argocd/

Files:

    namespace.yaml
    configmap.yaml
    deployment.yaml
    service.yaml
    kustomization.yaml

    application-dev.yaml
    application-qa.yaml
    application-prod.yaml

## Set lab variables

Set your repository URL.

Use the Git URL that Argo CD can read.

Example:

    REPO_URL="https://github.com/<your-user-or-org>/<your-repo>.git"

If this repository is your current remote:

    REPO_URL="$(git config --get remote.origin.url)"

Verify:

    echo "$REPO_URL"

Set application names:

    APP_DEV="promotion-demo-dev"
    APP_QA="promotion-demo-qa"
    APP_PROD="promotion-demo-prod"

Set namespaces:

    NS_DEV="promotion-dev"
    NS_QA="promotion-qa"
    NS_PROD="promotion-prod"

## Verify starter desired state

Check the starter version values:

    grep -RInE 'Environment:|Version:' \
      gitops/apps/dev/promotion-demo/configmap.yaml \
      gitops/apps/qa/promotion-demo/configmap.yaml \
      gitops/apps/prod/promotion-demo/configmap.yaml

Expected starter state:

    dev  = v1
    qa   = v1
    prod = v1

## Commit and publish desired state

Argo CD reads from Git.

Local files are not enough.

Before applying the Argo CD Applications, make sure the desired-state files are committed and available in the Git repository configured in `REPO_URL`.

Check status:

    git status --short

Commit if needed:

    git add gitops/apps labs/professional/03-dev-qa-prod-promotion
    git commit -m "Add Argo CD promotion demo desired state"
    git push

## Create Argo CD Applications

Apply the dev Application:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/03-dev-qa-prod-promotion/argocd/application-dev.yaml \
      | kubectl apply -f -

Apply the qa Application:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/03-dev-qa-prod-promotion/argocd/application-qa.yaml \
      | kubectl apply -f -

Apply the prod Application:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/03-dev-qa-prod-promotion/argocd/application-prod.yaml \
      | kubectl apply -f -

Verify:

    kubectl get applications -n argocd

Expected:

    promotion-demo-dev    Synced    Healthy
    promotion-demo-qa     Synced    Healthy
    promotion-demo-prod   Synced    Healthy

## Verify Kubernetes resources

Check namespaces:

    kubectl get ns promotion-dev promotion-qa promotion-prod

Check pods:

    kubectl get pods -n promotion-dev
    kubectl get pods -n promotion-qa
    kubectl get pods -n promotion-prod

Check services:

    kubectl get svc -n promotion-dev
    kubectl get svc -n promotion-qa
    kubectl get svc -n promotion-prod

Expected:

- dev has 1 pod
- qa has 2 pods
- prod has 2 pods
- each namespace has a `promotion-demo` ClusterIP service

## Access Argo CD UI

Port-forward Argo CD:

    kubectl port-forward svc/argocd-server -n argocd 8080:443

Open:

    https://localhost:8080

Username:

    admin

Get the initial admin password if needed:

    kubectl -n argocd get secret argocd-initial-admin-secret \
      -o jsonpath="{.data.password}" | base64 -d
    echo

In the UI, verify that you can see:

- promotion-demo-dev
- promotion-demo-qa
- promotion-demo-prod

Do not expose Argo CD publicly for this lab.

Port-forward is used because it is safer and simpler for local learning.

## Verify app pages

Port-forward dev:

    kubectl port-forward svc/promotion-demo -n promotion-dev 8081:80

Open:

    http://localhost:8081

Expected:

    Environment: dev
    Version: v1

Port-forward qa:

    kubectl port-forward svc/promotion-demo -n promotion-qa 8082:80

Open:

    http://localhost:8082

Expected:

    Environment: qa
    Version: v1

Port-forward prod:

    kubectl port-forward svc/promotion-demo -n promotion-prod 8083:80

Open:

    http://localhost:8083

Expected:

    Environment: prod
    Version: v1

If the browser shows old content, restart the port-forward and hard refresh the browser.

## Promote dev to v2

Update only the HTML version in the dev ConfigMap.

Do not use a broad sed replacement, because it can accidentally change `apiVersion: v1`.

Use this safe edit:

    python3 - <<'PY'
from pathlib import Path

p = Path("gitops/apps/dev/promotion-demo/configmap.yaml")
text = p.read_text()
text = text.replace("<p>Version: v1</p>", "<p>Version: v2</p>")
p.write_text(text)
PY

Verify:

    grep -nE 'apiVersion|Environment:|Version:' \
      gitops/apps/dev/promotion-demo/configmap.yaml

Commit and push:

    git add gitops/apps/dev/promotion-demo/configmap.yaml
    git commit -m "Promote demo dev environment to v2"
    git push

Refresh dev Application:

    kubectl annotate application promotion-demo-dev -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify:

    kubectl get applications -n argocd

Check dev ConfigMap:

    kubectl get configmap promotion-demo-content -n promotion-dev \
      -o jsonpath='{.data.index\.html}'
    echo

Expected:

    Environment: dev
    Version: v2

At this point:

    dev  = v2
    qa   = v1
    prod = v1

## Promote qa to v2

Update only the HTML version in the qa ConfigMap:

    python3 - <<'PY'
from pathlib import Path

p = Path("gitops/apps/qa/promotion-demo/configmap.yaml")
text = p.read_text()
text = text.replace("<p>Version: v1</p>", "<p>Version: v2</p>")
p.write_text(text)
PY

Verify:

    grep -nE 'apiVersion|Environment:|Version:' \
      gitops/apps/qa/promotion-demo/configmap.yaml

Commit and push:

    git add gitops/apps/qa/promotion-demo/configmap.yaml
    git commit -m "Promote demo qa environment to v2"
    git push

Refresh qa Application:

    kubectl annotate application promotion-demo-qa -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify qa:

    kubectl get configmap promotion-demo-content -n promotion-qa \
      -o jsonpath='{.data.index\.html}'
    echo

Verify prod is still v1:

    kubectl get configmap promotion-demo-content -n promotion-prod \
      -o jsonpath='{.data.index\.html}'
    echo

At this point:

    dev  = v2
    qa   = v2
    prod = v1

## Promote prod to v2

Update only the HTML version in the prod ConfigMap:

    python3 - <<'PY'
from pathlib import Path

p = Path("gitops/apps/prod/promotion-demo/configmap.yaml")
text = p.read_text()
text = text.replace("<p>Version: v1</p>", "<p>Version: v2</p>")
p.write_text(text)
PY

Verify:

    grep -nE 'apiVersion|Environment:|Version:' \
      gitops/apps/prod/promotion-demo/configmap.yaml

Commit and push:

    git add gitops/apps/prod/promotion-demo/configmap.yaml
    git commit -m "Promote demo prod environment to v2"
    git push

Refresh prod Application:

    kubectl annotate application promotion-demo-prod -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify final state:

    kubectl get applications -n argocd

    kubectl get configmap promotion-demo-content -n promotion-dev \
      -o jsonpath='{.data.index\.html}'
    echo

    kubectl get configmap promotion-demo-content -n promotion-qa \
      -o jsonpath='{.data.index\.html}'
    echo

    kubectl get configmap promotion-demo-content -n promotion-prod \
      -o jsonpath='{.data.index\.html}'
    echo

Expected final state:

    dev  = v2
    qa   = v2
    prod = v2

## Test self-heal

Prod desired state has 2 replicas.

Manually change prod replicas:

    kubectl scale deployment promotion-demo -n promotion-prod --replicas=1

Check:

    kubectl get deployment promotion-demo -n promotion-prod

Wait 30 to 60 seconds, then check again:

    kubectl get deployment promotion-demo -n promotion-prod
    kubectl get applications -n argocd

Expected:

    promotion-demo returns to 2 replicas
    promotion-demo-prod is Synced and Healthy

This proves Argo CD self-heal corrected manual drift.

## Troubleshooting

### Application is OutOfSync

Refresh the Application:

    kubectl annotate application promotion-demo-dev -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Or use the Argo CD UI:

    Application -> SYNC -> SYNCHRONIZE

### Argo CD cannot find the repo path

Check the path in the Application manifest:

    gitops/apps/dev/promotion-demo
    gitops/apps/qa/promotion-demo
    gitops/apps/prod/promotion-demo

Make sure the files are committed and available in the Git repository configured in `REPO_URL`.

### Browser shows old version

Restart the port-forward.

Hard refresh the browser.

You can also verify directly from Kubernetes:

    kubectl get configmap promotion-demo-content -n promotion-dev \
      -o jsonpath='{.data.index\.html}'
    echo

### ConfigMap apiVersion error

If you see an error like:

    The Kubernetes API could not find version "v2" of /ConfigMap

You accidentally changed:

    apiVersion: v1

to:

    apiVersion accidentally changed to the wrong value

Fix it back to:

    apiVersion: v1

Only change the HTML line:

    <p>Version: v1</p>

## Cleanup

Delete Argo CD Applications:

    kubectl delete application promotion-demo-dev -n argocd --ignore-not-found
    kubectl delete application promotion-demo-qa -n argocd --ignore-not-found
    kubectl delete application promotion-demo-prod -n argocd --ignore-not-found

Delete promotion namespaces:

    kubectl delete namespace promotion-dev --ignore-not-found
    kubectl delete namespace promotion-qa --ignore-not-found
    kubectl delete namespace promotion-prod --ignore-not-found

Verify:

    kubectl get applications -n argocd
    kubectl get ns promotion-dev promotion-qa promotion-prod 2>/dev/null || echo "promotion namespaces removed"

This cleanup does not remove Argo CD.

## What you completed

You completed:

- dev, qa, and prod desired-state structure
- Three Argo CD Applications
- Promotion from dev to qa to prod
- Argo CD UI verification
- Browser verification
- Git-driven environment promotion
- Argo CD self-heal test
- Cleanup

This prepares you for:

    Professional Lab 04 - Blue/Green Deployment

## Important note

This lab is a promotion pattern.

The important concept is not the sample NGINX app.

The important concept is:

    Git desired state
      |
      v
    Argo CD sync
      |
      v
    Environment-specific cluster state

For real production use, combine this pattern with pull requests, approvals, security checks, monitoring, rollback plans, and change management.
