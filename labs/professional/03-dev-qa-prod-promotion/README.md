# Professional Lab 03 - dev to qa to prod promotion

This lab shows how to promote application desired state from dev to qa to prod using Argo CD.

This is a professional GitOps lab.

The goal is to understand environment promotion through Git, not direct `kubectl apply`.

## Lab goal

By the end of this lab, you will have:

- A fork of the sample GitOps application repository
- dev, qa, and prod desired-state folders in the sample repository
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
- Why app desired state belongs in an application GitOps repository
- How dev, qa, and prod desired state can be separated
- How Argo CD tracks multiple Applications
- How to promote a change environment by environment
- Why local file changes are not enough for GitOps
- How Argo CD sync and self-heal work
- How to verify promotion using kubectl and browser access

## Architecture

This lab uses two repositories.

Platform and lab repository:

    terraform-azure-aks

This repository contains:

    labs/professional/03-dev-qa-prod-promotion/README.md
    labs/professional/03-dev-qa-prod-promotion/README.si.md
    labs/professional/03-dev-qa-prod-promotion/argocd/application-dev.yaml
    labs/professional/03-dev-qa-prod-promotion/argocd/application-qa.yaml
    labs/professional/03-dev-qa-prod-promotion/argocd/application-prod.yaml

Sample application GitOps repository:

    aks-gitops-sample-app

The sample repository contains the application desired state:

    k8s/promotion/dev
    k8s/promotion/qa
    k8s/promotion/prod

Each Argo CD Application points to one environment path:

    promotion-demo-dev  -> k8s/promotion/dev
    promotion-demo-qa   -> k8s/promotion/qa
    promotion-demo-prod -> k8s/promotion/prod

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
- A fork of the sample app repository

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

## Fork the sample app repository

This lab uses this sample application GitOps repository:

    https://github.com/andrewferdinandus/aks-gitops-sample-app

Fork this repository into your own GitHub account or organization.

Example fork URL:

    https://github.com/<your-user-or-org>/aks-gitops-sample-app.git

Why use a fork?

Argo CD reads desired state from Git. In this lab, you will promote the app from dev to qa to prod by editing files under:

    k8s/promotion/dev
    k8s/promotion/qa
    k8s/promotion/prod

You need write access to push those changes. A fork gives you your own copy of the sample repository.

## Clone your fork

Go to your projects folder:

    cd /Users/andrewferdinandus/projcts

Clone your fork:

    git clone https://github.com/<your-user-or-org>/aks-gitops-sample-app.git

Enter the sample app repository:

    cd aks-gitops-sample-app

Set the sample repo directory:

    SAMPLE_REPO_DIR="$(pwd)"

Verify:

    echo "$SAMPLE_REPO_DIR"

## Set lab variables

Set your sample app repository URL.

Use your fork:

    REPO_URL="https://github.com/<your-user-or-org>/aks-gitops-sample-app.git"

Verify:

    echo "$REPO_URL"

Set the platform repo directory:

    PLATFORM_REPO_DIR="/Users/andrewferdinandus/projcts/terraform-azure-aks"

Verify:

    echo "$PLATFORM_REPO_DIR"

## Verify starter desired state

Run this from the sample app repository:

    cd "$SAMPLE_REPO_DIR"

Check starter version values:

    grep -RInE 'Environment:|Version:' \
      k8s/promotion/dev/configmap.yaml \
      k8s/promotion/qa/configmap.yaml \
      k8s/promotion/prod/configmap.yaml

Expected starter state:

    dev  = v1
    qa   = v1
    prod = v1

Check Git status:

    git status --short

If you changed or added files in the sample app repository, commit and push them:

    git add k8s/promotion
    git commit -m "Add promotion demo desired state"
    git push

## Create Argo CD Applications

Run these commands from the platform repository:

    cd "$PLATFORM_REPO_DIR"

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

Run this from the sample app repository:

    cd "$SAMPLE_REPO_DIR"

Update only the HTML version in the dev ConfigMap:

    python3 -c 'from pathlib import Path; p=Path("k8s/promotion/dev/configmap.yaml"); text=p.read_text(); p.write_text(text.replace("<p>Version: v1</p>", "<p>Version: v2</p>"))'

Verify:

    grep -nE 'apiVersion|Environment:|Version:' \
      k8s/promotion/dev/configmap.yaml

Commit and push:

    git add k8s/promotion/dev/configmap.yaml
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

Run this from the sample app repository:

    cd "$SAMPLE_REPO_DIR"

Update only the HTML version in the qa ConfigMap:

    python3 -c 'from pathlib import Path; p=Path("k8s/promotion/qa/configmap.yaml"); text=p.read_text(); p.write_text(text.replace("<p>Version: v1</p>", "<p>Version: v2</p>"))'

Verify:

    grep -nE 'apiVersion|Environment:|Version:' \
      k8s/promotion/qa/configmap.yaml

Commit and push:

    git add k8s/promotion/qa/configmap.yaml
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

Run this from the sample app repository:

    cd "$SAMPLE_REPO_DIR"

Update only the HTML version in the prod ConfigMap:

    python3 -c 'from pathlib import Path; p=Path("k8s/promotion/prod/configmap.yaml"); text=p.read_text(); p.write_text(text.replace("<p>Version: v1</p>", "<p>Version: v2</p>"))'

Verify:

    grep -nE 'apiVersion|Environment:|Version:' \
      k8s/promotion/prod/configmap.yaml

Commit and push:

    git add k8s/promotion/prod/configmap.yaml
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

    k8s/promotion/dev
    k8s/promotion/qa
    k8s/promotion/prod

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

You accidentally changed the Kubernetes API version line.

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
