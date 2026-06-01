# Professional Lab 01 - Argo CD GitOps

This lab shows how to install Argo CD on AKS and use GitOps to deploy a Kubernetes application from Git.

Argo CD watches a Git repository and reconciles the cluster to match the desired state stored in Git.

The flow is:

    GitHub repository
      |
      v
    Argo CD Application
      |
      v
    AKS cluster
      |
      v
    Demo Kubernetes workload

## Lab goal

By the end of this lab, you should have:

- Argo CD installed in the `argocd` namespace
- Local access to the Argo CD UI through port-forward
- An Argo CD Application named `professional-gitops-demo`
- A demo app synced from a public Git repository
- The demo app running in the `gitops-sample-dev` namespace
- Automated sync and self-heal tested

This lab uses a public sample app repository so learners do not need to push changes to GitHub.

## What you will learn

You will learn:

- What GitOps means in practice
- How to install Argo CD on AKS
- How to access the Argo CD UI locally
- How to get the initial Argo CD admin password
- How to define a Kubernetes application in Git
- How to create an Argo CD Application
- How Argo CD syncs manifests from Git to AKS
- How automated sync and self-heal work
- How to clean up Argo CD and demo app resources

## Architecture

This lab uses two repositories:

    terraform-azure-aks
      Learning platform and lab guide repository

    aks-gitops-sample-app
      Sample application repository used by Argo CD

Argo CD runs inside the AKS cluster. It cannot read files directly from your laptop.

For this lab, Argo CD reads Kubernetes manifests from the sample app repository:

    https://github.com/andrewferdinandus/aks-gitops-sample-app.git

Path:

    k8s/overlays/dev

The flow is:

    aks-gitops-sample-app
      |
      v
    Argo CD
      |
      v
    AKS namespace: gitops-sample-dev
      |
      v
    dev-gitops-sample-app

Learners do not push anything to GitHub for this lab. Argo CD only reads the sample app manifests from the public sample repository.


## What this lab requires

You need:

- kubectl
- Existing AKS cluster
- Access to the AKS cluster
- A terminal
- A web browser
- Internet access from your laptop to download the Argo CD install manifest
- Internet access from the cluster to pull container images
- Access from Argo CD to the public sample Git repository

This lab does not require:

- Docker Desktop
- Azure Container Registry
- A CI/CD platform
- Pushing changes to GitHub

## Install required local tools

### kubectl

Install kubectl:

    https://kubernetes.io/docs/tasks/tools/

Verify kubectl:

    kubectl version --client

## Check local tools and AKS access

Before continuing, verify that kubectl can reach your AKS cluster:

    kubectl get nodes

Check current context:

    kubectl config current-context

Expected:

    Nodes should show Ready status.

## Lab files

This lab includes:

    manifests/
      Kubernetes manifests for the demo app and Argo CD Application

    scripts/
      Optional helper scripts can be added later

Files:

    manifests/namespace.yaml
    manifests/app.yaml
    manifests/argocd-application.yaml

## Set lab variables

Set these values for your environment:

    ARGOCD_NAMESPACE="argocd"
    APP_NAMESPACE="gitops-sample-dev"
    REPO_URL="https://github.com/andrewferdinandus/aks-gitops-sample-app.git"
    APP_PATH="k8s/overlays/dev"

## Install Argo CD

Create the Argo CD namespace:

    kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

Install Argo CD using the official install manifest:

    kubectl apply -n "$ARGOCD_NAMESPACE" \
      --server-side \
      --force-conflicts \
      -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Wait for Argo CD components:

    kubectl rollout status deployment/argocd-server -n "$ARGOCD_NAMESPACE"
    kubectl rollout status deployment/argocd-repo-server -n "$ARGOCD_NAMESPACE"
    kubectl rollout status deployment/argocd-applicationset-controller -n "$ARGOCD_NAMESPACE"
    kubectl rollout status statefulset/argocd-application-controller -n "$ARGOCD_NAMESPACE"

Verify:

    kubectl get pods -n "$ARGOCD_NAMESPACE"
    kubectl get svc -n "$ARGOCD_NAMESPACE"

## Access Argo CD locally

Get the initial admin password:

    kubectl get secret argocd-initial-admin-secret \
      -n "$ARGOCD_NAMESPACE" \
      -o jsonpath="{.data.password}" | base64 --decode; echo

Port-forward the Argo CD server:

    kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" 8080:443

Open Argo CD:

    https://localhost:8080

Login:

    Username: admin
    Password: use the password from the secret command

A browser certificate warning is expected for this local lab.

Stop port-forward with:

    Ctrl+C

## Review the demo app manifests

The demo app namespace is defined in:

    manifests/namespace.yaml

The demo workload is defined in:

    manifests/app.yaml

The demo workload deploys:

- NGINX Deployment
- ClusterIP Service
- Namespace named professional-gitops-demo

Do not apply these demo app manifests manually in the main lab flow. Argo CD should apply them from Git.

## Review the Argo CD Application

The Argo CD Application is defined in:

    manifests/argocd-application.yaml

It points to the separate sample application repository:

    repoURL: https://github.com/andrewferdinandus/aks-gitops-sample-app.git
    targetRevision: main
    path: k8s/overlays/dev

The destination namespace is:

    gitops-sample-dev

This keeps the learning platform repository separate from the sample application repository.


## Create the Argo CD Application

Apply the Argo CD Application:

    kubectl apply -f labs/professional/01-argocd-gitops/manifests/argocd-application.yaml

Verify the Application resource:

    kubectl get applications -n "$ARGOCD_NAMESPACE"

Check the sample app namespace:

    kubectl get ns "$APP_NAMESPACE"

Check the sample app workload:

    kubectl get pods -n "$APP_NAMESPACE"
    kubectl get svc -n "$APP_NAMESPACE"

Expected result:

    professional-gitops-demo   Synced   Healthy
    dev-gitops-sample-app pods Running
    dev-gitops-sample-app service created


## Verify in the Argo CD UI

Port-forward Argo CD again if needed:

    kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" 8080:443

Open:

    https://localhost:8080

You should see:

    professional-gitops-demo

The application should become:

    Synced
    Healthy

If it is OutOfSync, click Sync or wait for automated sync.

## Test self-heal

Scale the deployment manually:

    kubectl scale deployment dev-gitops-sample-app -n "$APP_NAMESPACE" --replicas=1

Check pods:

    kubectl get pods -n "$APP_NAMESPACE"

Because self-heal is enabled, Argo CD should reconcile the deployment back to the Git desired state:

    replicas: 2

Verify again:

    kubectl get deployment dev-gitops-sample-app -n "$APP_NAMESPACE"

## Understand GitOps changes

Argo CD watches the Git source configured in:

    manifests/argocd-application.yaml

In this lab, that source is:

    https://github.com/andrewferdinandus/aks-gitops-sample-app.git

Local file edits on your laptop are useful for practice, but Argo CD will not see those edits unless they are available from the configured Git source.

For this lab, use the self-heal test above to understand reconciliation without pushing any changes.

The important concept is:

    Git desired state
      |
      v
    Argo CD reconciliation
      |
      v
    Kubernetes cluster state


## Troubleshooting

Check Argo CD pods:

    kubectl get pods -n "$ARGOCD_NAMESPACE"

Check the Argo CD Application:

    kubectl describe application professional-gitops-demo -n "$ARGOCD_NAMESPACE"

Check app resources:

    kubectl get all -n "$APP_NAMESPACE"

Check Argo CD server logs:

    kubectl logs deployment/argocd-server -n "$ARGOCD_NAMESPACE" --tail=100

Check repo server logs:

    kubectl logs deployment/argocd-repo-server -n "$ARGOCD_NAMESPACE" --tail=100

If the app does not sync, check:

- Repo URL
- Branch name
- Manifest path
- Public repo access
- Application destination namespace
- ServiceAccount/RBAC permissions

## Cleanup

Delete the Argo CD Application:

    kubectl delete application professional-gitops-demo -n "$ARGOCD_NAMESPACE" --ignore-not-found

Delete the demo namespace:

    kubectl delete namespace "$APP_NAMESPACE" --ignore-not-found

Delete Argo CD:

    kubectl delete namespace "$ARGOCD_NAMESPACE" --ignore-not-found

This removes Argo CD and the demo application.

This does not remove:

- AKS cluster
- Monitoring stack
- Key Vault
- ACR
- Other lab resources

If you plan to continue to the Flux GitOps lab immediately, you can still clean up Argo CD to avoid tool overlap.

## What you completed

You completed:

- Argo CD installation on AKS
- Argo CD UI access
- GitOps application definition
- Git-based application sync
- Self-heal test
- GitOps change test
- Cleanup path

This prepares you for:

    Professional Lab 02 - Flux GitOps

## Important note

This is a professional GitOps lab.

Argo CD runs inside the cluster and reconciles from the Git repository configured in the Application resource.

Local file edits on your laptop are not seen by Argo CD unless those edits are committed and available in the configured Git source.

For this lab, the configured Git source is the public sample app repository.
