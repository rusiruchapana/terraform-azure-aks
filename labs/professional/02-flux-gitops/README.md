# Professional Lab 02 - Flux GitOps

This lab shows how to install Flux on AKS and use GitOps to deploy a Kubernetes application from Git.

Flux watches a Git repository and reconciles the cluster to match the desired state stored in Git.

This is a standalone professional GitOps lab.

The flow is:

    GitHub repository
      |
      v
    Flux GitRepository
      |
      v
    Flux Kustomization
      |
      v
    AKS cluster
      |
      v
    Demo Kubernetes workload

## Lab goal

By the end of this lab, you should have:

- Flux installed in the `flux-system` namespace
- A Flux GitRepository named `professional-gitops-demo`
- A Flux Kustomization named `professional-gitops-demo`
- A demo app synced from a public Git repository
- The demo app running in the `gitops-sample-dev` namespace
- Flux reconciliation tested
- Basic drift correction tested

This lab uses a public sample app repository so learners do not need to push changes to GitHub.

## What you will learn

You will learn:

- What Flux does in a GitOps workflow
- How Flux differs from direct `kubectl apply`
- How to install Flux on AKS
- How to create a Flux GitRepository source
- How to create a Flux Kustomization
- How Flux syncs manifests from Git to AKS
- How Flux reconciliation works
- How to inspect Flux status
- How to test drift correction
- How to clean up Flux and demo app resources

## Architecture

This lab uses two repositories:

    terraform-azure-aks
      Learning platform and lab guide repository

    aks-gitops-sample-app
      Sample application repository used by Flux

Flux runs inside the AKS cluster.

Flux reads Kubernetes manifests from the sample app repository:

    https://github.com/andrewferdinandus/aks-gitops-sample-app.git

Path:

    k8s/overlays/dev

The flow is:

    aks-gitops-sample-app
      |
      v
    Flux source-controller
      |
      v
    Flux kustomize-controller
      |
      v
    AKS namespace: gitops-sample-dev
      |
      v
    dev-gitops-sample-app

Learners do not push anything to GitHub for this lab.

Flux only reads the sample app manifests from the public sample repository.

## What this lab requires

You need:

- kubectl
- Flux CLI
- Existing AKS cluster
- AKS cluster access
- A terminal
- A web browser is optional
- Internet access from your laptop to install Flux CLI
- Internet access from the cluster to pull container images
- Access from Flux to the public sample Git repository

This lab does not require:

- Docker Desktop
- Azure Container Registry
- A CI/CD platform
- Pushing changes to GitHub
- Argo CD

## Install required local tools

### kubectl

Install kubectl:

    https://kubernetes.io/docs/tasks/tools/

Verify kubectl:

    kubectl version --client

### Flux CLI

Install Flux CLI:

    https://fluxcd.io/flux/installation/

Verify Flux CLI:

    flux --version

## Check local tools and AKS access

Before continuing, verify that kubectl can reach your AKS cluster:

    kubectl get nodes

Check current context:

    kubectl config current-context

Verify Flux prerequisites:

    flux check --pre

Expected:

    Nodes should show Ready status.
    Flux prerequisite check should pass.

## Lab files

This lab includes:

    manifests/
      Kubernetes namespace manifest for the demo app namespace

    flux/
      Flux GitRepository and Kustomization resources

Files:

    manifests/namespace.yaml
    flux/gitrepository.yaml
    flux/kustomization.yaml

## Set lab variables

Set these values for your environment:

    FLUX_NAMESPACE="flux-system"
    APP_NAMESPACE="gitops-sample-dev"
    REPO_URL="https://github.com/andrewferdinandus/aks-gitops-sample-app.git"
    APP_PATH="./k8s/overlays/dev"

Verify:

    echo "$FLUX_NAMESPACE"
    echo "$APP_NAMESPACE"
    echo "$REPO_URL"
    echo "$APP_PATH"

## Install Flux

Install Flux components into the cluster:

    flux install

Verify Flux pods:

    kubectl get pods -n "$FLUX_NAMESPACE"

Check Flux status:

    flux check

Expected:

    Flux controllers should be Running.
    `flux check` should pass.

## Create the demo app namespace

Create the namespace that Flux will deploy the demo app into:

    kubectl apply -f labs/professional/02-flux-gitops/manifests/namespace.yaml

Verify:

    kubectl get namespace "$APP_NAMESPACE"

## Review the Flux GitRepository

The GitRepository is defined in:

    flux/gitrepository.yaml

It points to the public sample application repository:

    url: https://github.com/andrewferdinandus/aks-gitops-sample-app.git
    branch: main

The GitRepository tells Flux where to fetch desired state from.

## Review the Flux Kustomization

The Kustomization is defined in:

    flux/kustomization.yaml

It points to:

    path: ./k8s/overlays/dev

It uses the GitRepository source:

    professional-gitops-demo

It deploys into:

    gitops-sample-dev

This keeps the learning platform repository separate from the sample application repository.

## Create the Flux GitRepository

Apply the GitRepository:

    kubectl apply -f labs/professional/02-flux-gitops/flux/gitrepository.yaml

Verify:

    flux get sources git -n "$FLUX_NAMESPACE"

You should see:

    professional-gitops-demo

## Create the Flux Kustomization

Apply the Kustomization:

    kubectl apply -f labs/professional/02-flux-gitops/flux/kustomization.yaml

Verify:

    flux get kustomizations -n "$FLUX_NAMESPACE"

You should see:

    professional-gitops-demo

Force a reconcile if needed:

    flux reconcile source git professional-gitops-demo -n "$FLUX_NAMESPACE"
    flux reconcile kustomization professional-gitops-demo -n "$FLUX_NAMESPACE"

## Verify the synced app

Check the app namespace:

    kubectl get ns "$APP_NAMESPACE"

Check the app workload:

    kubectl get pods -n "$APP_NAMESPACE"
    kubectl get svc -n "$APP_NAMESPACE"
    kubectl get deployment -n "$APP_NAMESPACE"

Expected result:

    dev-gitops-sample-app pods Running
    dev-gitops-sample-app service created

Check Flux status:

    flux get sources git -n "$FLUX_NAMESPACE"
    flux get kustomizations -n "$FLUX_NAMESPACE"

Expected:

    GitRepository is Ready
    Kustomization is Ready

## Test reconciliation

Scale the deployment manually:

    kubectl scale deployment dev-gitops-sample-app -n "$APP_NAMESPACE" --replicas=1

Check the deployment:

    kubectl get deployment dev-gitops-sample-app -n "$APP_NAMESPACE"

Force Flux reconciliation:

    flux reconcile kustomization professional-gitops-demo -n "$FLUX_NAMESPACE"

Verify again:

    kubectl get deployment dev-gitops-sample-app -n "$APP_NAMESPACE"

Flux should reconcile the deployment back to the Git desired state.

## Understand GitOps changes

Flux watches the Git source configured in:

    flux/gitrepository.yaml
    flux/kustomization.yaml

In this lab, that source is:

    https://github.com/andrewferdinandus/aks-gitops-sample-app.git

Local file edits on your laptop are useful for practice, but Flux will not see those edits unless they are available from the configured Git source.

For this lab, use the reconciliation test above to understand GitOps without pushing any changes.

The important concept is:

    Git desired state
      |
      v
    Flux reconciliation
      |
      v
    Kubernetes cluster state

## Troubleshooting

### Flux controllers are not running

Check Flux pods:

    kubectl get pods -n "$FLUX_NAMESPACE"

Check Flux status:

    flux check

### GitRepository is not Ready

Check GitRepository status:

    flux get sources git -n "$FLUX_NAMESPACE"

Describe the GitRepository:

    kubectl describe gitrepository professional-gitops-demo -n "$FLUX_NAMESPACE"

Check source-controller logs:

    kubectl logs deployment/source-controller -n "$FLUX_NAMESPACE" --tail=100

Common causes:

- Repo URL is wrong
- Branch name is wrong
- Cluster cannot reach GitHub
- Public repo access issue

### Kustomization is not Ready

Check Kustomization status:

    flux get kustomizations -n "$FLUX_NAMESPACE"

Describe the Kustomization:

    kubectl describe kustomization professional-gitops-demo -n "$FLUX_NAMESPACE"

Check kustomize-controller logs:

    kubectl logs deployment/kustomize-controller -n "$FLUX_NAMESPACE" --tail=100

Common causes:

- Path is wrong
- Kustomize build fails
- Destination namespace is missing
- RBAC issue
- Manifest validation issue

### App pods are not Running

Check app resources:

    kubectl get all -n "$APP_NAMESPACE"

Describe the pod:

    kubectl describe pod -n "$APP_NAMESPACE" <pod-name>

Check logs:

    kubectl logs -n "$APP_NAMESPACE" <pod-name>

## Cleanup

Delete the Flux Kustomization:

    kubectl delete kustomization professional-gitops-demo -n "$FLUX_NAMESPACE" --ignore-not-found

Delete the Flux GitRepository:

    kubectl delete gitrepository professional-gitops-demo -n "$FLUX_NAMESPACE" --ignore-not-found

Delete the demo namespace:

    kubectl delete namespace "$APP_NAMESPACE" --ignore-not-found

Uninstall Flux:

    flux uninstall --silent

The `flux-system` namespace may stay in `Terminating` state briefly while Kubernetes removes Flux resources.

Verify cleanup:

    kubectl get ns flux-system 2>/dev/null || echo "flux-system removed"
    kubectl get ns gitops-sample-dev 2>/dev/null || echo "gitops-sample-dev removed"
    kubectl get crd | grep -E 'gitrepositories|kustomizations' || echo "Flux CRDs removed"

This removes Flux and the demo application.

This does not remove:

- AKS cluster
- Monitoring stack
- Key Vault
- ACR
- Other lab resources

If you plan to compare Flux and Argo CD, you can reinstall either tool later.

## What you completed

You completed:

- Flux installation on AKS
- Flux GitRepository source definition
- Flux Kustomization definition
- Git-based application sync
- Flux reconciliation test
- Cleanup path

This prepares you for:

    Professional Lab 03 - dev to qa to prod promotion

## Important note

This is a professional GitOps lab.

Flux runs inside the cluster and reconciles from the Git repository configured in the GitRepository and Kustomization resources.

Local file edits on your laptop are not seen by Flux unless those edits are committed and available in the configured Git source.

For this lab, the configured Git source is the public sample app repository.
