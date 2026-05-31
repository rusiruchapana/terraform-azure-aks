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

This lab uses two namespaces:

    argocd
      Argo CD control plane

    professional-gitops-demo
      Demo application namespace

The GitOps application source is:

    https://github.com/andrewferdinandus/terraform-azure-aks.git

The application path is:

    labs/professional/01-argocd-gitops/manifests

Argo CD reads this path and applies the Kubernetes manifests to the cluster.

## What this lab requires

You need:

- Azure CLI
- kubectl
- Existing AKS cluster
- Access to the AKS cluster
- Public GitHub repo with this lab committed and pushed
- Browser access to the local Argo CD port-forward URL

Check Kubernetes access:

    kubectl get nodes

Check current context:

    kubectl config current-context

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
    APP_NAMESPACE="professional-gitops-demo"
    REPO_URL="https://github.com/andrewferdinandus/terraform-azure-aks.git"
    APP_PATH="labs/professional/01-argocd-gitops/manifests"

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

It points to:

    repoURL: https://github.com/andrewferdinandus/terraform-azure-aks.git
    targetRevision: main
    path: labs/professional/01-argocd-gitops/manifests

The Application manifest excludes itself from the app sync path:

    exclude: argocd-application.yaml

This prevents Argo CD from trying to apply the Application manifest into the demo app namespace.


## Create the Argo CD Application

Apply the Argo CD Application:

    kubectl apply -f labs/professional/01-argocd-gitops/manifests/argocd-application.yaml

Verify the Application resource:

    kubectl get applications -n "$ARGOCD_NAMESPACE"

Check the demo namespace:

    kubectl get ns "$APP_NAMESPACE"

Check the demo workload:

    kubectl get pods -n "$APP_NAMESPACE"
    kubectl get svc -n "$APP_NAMESPACE"

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

    kubectl scale deployment gitops-nginx -n "$APP_NAMESPACE" --replicas=1

Check pods:

    kubectl get pods -n "$APP_NAMESPACE"

Because self-heal is enabled, Argo CD should reconcile the deployment back to the Git desired state:

    replicas: 2

Verify again:

    kubectl get deployment gitops-nginx -n "$APP_NAMESPACE"

## Understand GitOps changes

Argo CD watch කරන්නේ මෙතන configure කරලා තියෙන Git source එක:

    manifests/argocd-application.yaml

මෙම lab එකේ source එක `repoURL` එකේ තියෙන published repository URL එක.

මෙම lab එකට learnersලා GitHub එකට කිසිම දෙයක් push කරන්න අවශ්‍ය නැහැ.

ඔයාගේ machine එකේ local file edits practice සඳහා useful. හැබැයි ඒ edits configured Git source එකෙන් available නැත්නම් Argo CD ඒවා දකින්නේ නැහැ.

මෙම lab එකේ reconciliation concept එක තේරුම් ගන්න ඉහත self-heal test එක use කරන්න:

    Manual cluster change
      |
      v
    Argo CD detects drift
      |
      v
    Argo CD restores the Git desired state

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
