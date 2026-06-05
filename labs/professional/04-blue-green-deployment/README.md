# Professional Lab 04 - Blue/Green Deployment

This lab shows how to run blue and green versions of an application side by side, switch active user traffic from blue to green, and roll back from green to blue using Argo CD and GitOps.

This is a professional release strategy lab.

The goal is not only to run commands. The goal is to understand what each component does:

- Git stores the desired state
- Argo CD watches Git and reconciles the cluster
- Kubernetes Deployments run blue and green versions
- Kubernetes Services route traffic
- The browser shows what users would experience

## Lab goal

By the end of this lab, you will have:

- A blue version running as the stable app version
- A green version running as the new candidate version
- An active Service that sends user traffic to blue or green
- A blue preview Service that always shows blue
- A green preview Service that always shows green
- Argo CD managing the blue/green desired state from Git
- A tested switch from blue to green
- A tested rollback from green to blue
- A tested Argo CD self-heal/drift correction flow

## What you will learn

You will learn:

- What blue/green deployment means
- Why blue and green run at the same time
- How preview Services help validate both versions before switching traffic
- How a Kubernetes Service selector controls active traffic
- What Argo CD does during a GitOps release switch
- Why the real switch should happen through Git, not direct kubectl patch
- How to verify the active release in the browser
- How to roll back quickly
- How Argo CD self-heal corrects manual drift

## Architecture

This lab uses two repositories.

Platform and lab repository:

    terraform-azure-aks

This repository contains:

    labs/professional/04-blue-green-deployment/README.md
    labs/professional/04-blue-green-deployment/README.si.md
    labs/professional/04-blue-green-deployment/argocd/application.yaml

Sample application GitOps repository:

    aks-gitops-sample-app

The sample repository contains the application desired state:

    k8s/blue-green

The desired state contains:

    namespace.yaml
    configmap-blue.yaml
    configmap-green.yaml
    deployment-blue.yaml
    deployment-green.yaml
    service-active.yaml
    service-blue-preview.yaml
    service-green-preview.yaml
    kustomization.yaml

## How the model works

Blue is the current stable version:

    bluegreen-blue
    version: blue
    page: blue v1

Green is the new candidate version:

    bluegreen-green
    version: green
    page: green v2

The active Service is the user-facing service:

    bluegreen-demo

At the start, the active Service points to blue:

    selector:
      app: bluegreen-demo
      version: blue

After the release switch, the active Service points to green:

    selector:
      app: bluegreen-demo
      version: green

Rollback switches the active Service back to blue.

## Why preview Services exist

This lab uses three Services:

    bluegreen-demo
    bluegreen-blue-preview
    bluegreen-green-preview

The active Service represents user traffic:

    bluegreen-demo

The blue preview Service always points to blue:

    bluegreen-blue-preview

The green preview Service always points to green:

    bluegreen-green-preview

This gives a clear browser experience:

    Active app     -> what users currently see
    Blue preview   -> stable blue version
    Green preview  -> candidate green version

Before the switch:

    Active app     -> blue v1
    Blue preview   -> blue v1
    Green preview  -> green v2

After switching to green:

    Active app     -> green v2
    Blue preview   -> blue v1
    Green preview  -> green v2

After rollback:

    Active app     -> blue v1
    Blue preview   -> blue v1
    Green preview  -> green v2

## What Argo CD does in this lab

Argo CD watches the sample GitOps repository.

When you change this file in Git:

    k8s/blue-green/service-active.yaml

Argo CD detects the Git change and updates the Kubernetes Service in the cluster.

The release switch happens through this flow:

    Git change
      |
      v
    Argo CD detects the change
      |
      v
    Argo CD updates Kubernetes Service
      |
      v
    Kubernetes Service sends traffic to selected pods
      |
      v
    Browser shows the active version

Do not use `kubectl patch` for the real release switch.

Use Git for the real blue/green switch.

Use `kubectl patch` only later to test Argo CD self-heal.

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

## Fork and clone the sample app repository

This lab uses this sample application GitOps repository:

    https://github.com/andrewferdinandus/aks-gitops-sample-app

Fork this repository into your own GitHub account or organization.

Example fork URL:

    https://github.com/<your-user-or-org>/aks-gitops-sample-app.git

Clone your fork:

    cd <local-path>
    git clone https://github.com/<your-user-or-org>/aks-gitops-sample-app.git
    cd aks-gitops-sample-app

Set the sample repository directory:

    SAMPLE_REPO_DIR="$(pwd)"

Verify:

    echo "$SAMPLE_REPO_DIR"

Set your sample repository URL:

    REPO_URL="https://github.com/<your-user-or-org>/aks-gitops-sample-app.git"

Verify:

    echo "$REPO_URL"

Set the platform repository directory:

    PLATFORM_REPO_DIR="<local-path>/terraform-azure-aks"

Verify:

    echo "$PLATFORM_REPO_DIR"

## Verify blue/green desired state

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Check files:

    find k8s/blue-green -maxdepth 2 -type f | sort

Check the active Service selector:

    grep -nE 'selector:|app: bluegreen-demo|version:' \
      k8s/blue-green/service-active.yaml

Expected starter state:

    version: blue

Check the important blue/green values:

    grep -RInE 'bluegreen-demo|bluegreen-blue-preview|bluegreen-green-preview|version: blue|version: green|Active color|Version:' \
      k8s/blue-green

Expected:

- blue content says `Active color: blue` and `Version: v1`
- green content says `Active color: green` and `Version: v2`
- active Service starts with `version: blue`
- blue preview Service uses `version: blue`
- green preview Service uses `version: green`

Check Git status:

    git status --short

If you changed or added files in the sample repository, commit and push them:

    git add k8s/blue-green
    git commit -m "Add blue green deployment demo desired state"
    git push

## Create the Argo CD Application

Run this from the platform repository:

    cd "$PLATFORM_REPO_DIR"

Apply the Argo CD Application:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/04-blue-green-deployment/argocd/application.yaml \
      | kubectl apply -f -

Verify:

    kubectl get applications -n argocd

Expected:

    bluegreen-demo   Synced   Healthy

## Verify Kubernetes resources

Check namespace:

    kubectl get ns bluegreen-demo

Check pods and labels:

    kubectl get pods -n bluegreen-demo --show-labels

Expected:

- blue pods have `version=blue`
- green pods have `version=green`

Check services:

    kubectl get svc -n bluegreen-demo

Expected Services:

    bluegreen-demo
    bluegreen-blue-preview
    bluegreen-green-preview

Check the active Service selector:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

Expected:

    selector:
      app: bluegreen-demo
      version: blue

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

In the UI, open:

    bluegreen-demo

Observe:

- Application status
- Kubernetes resources
- Service resource
- Blue Deployment
- Green Deployment

The Argo CD UI helps you see what GitOps is managing.

## Open the active and preview apps

Open three separate terminals for port-forwarding.

Active app:

    kubectl port-forward svc/bluegreen-demo -n bluegreen-demo 8084:80

Blue preview:

    kubectl port-forward svc/bluegreen-blue-preview -n bluegreen-demo 8085:80

Green preview:

    kubectl port-forward svc/bluegreen-green-preview -n bluegreen-demo 8086:80

Open these URLs:

    http://localhost:8084/?view=active
    http://localhost:8085/?view=blue-preview
    http://localhost:8086/?view=green-preview

Expected initial browser experience:

    8084 active        -> blue v1
    8085 blue preview  -> blue v1
    8086 green preview -> green v2

CLI verification:

    curl -s http://localhost:8084 | grep -E 'Active color|Version'
    curl -s http://localhost:8085 | grep -E 'Active color|Version'
    curl -s http://localhost:8086 | grep -E 'Active color|Version'

This proves green is already deployed and previewable, but active user traffic is still on blue.

## Switch active traffic to green

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Change the active Service selector from blue to green:

    python3 -c 'from pathlib import Path; p=Path("k8s/blue-green/service-active.yaml"); text=p.read_text(); p.write_text(text.replace("version: blue", "version: green"))'

Verify:

    grep -nE 'selector:|app: bluegreen-demo|version:' \
      k8s/blue-green/service-active.yaml

Commit and push:

    git add k8s/blue-green/service-active.yaml
    git commit -m "Switch blue green active traffic to green"
    git push

Refresh Argo CD:

    kubectl annotate application bluegreen-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify Argo CD:

    kubectl get applications -n argocd

Verify the active Service selector:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

Expected:

    selector:
      app: bluegreen-demo
      version: green

Restart the active port-forward.

Stop the `8084` port-forward with `Ctrl+C`, then start it again:

    kubectl port-forward svc/bluegreen-demo -n bluegreen-demo 8084:80

Verify browser or curl again:

    curl -s http://localhost:8084 | grep -E 'Active color|Version'
    curl -s http://localhost:8085 | grep -E 'Active color|Version'
    curl -s http://localhost:8086 | grep -E 'Active color|Version'

Expected after switch:

    8084 active        -> green v2
    8085 blue preview  -> blue v1
    8086 green preview -> green v2

## Important port-forward note

After changing the Service selector, restart the active port-forward.

`kubectl port-forward svc/...` may keep forwarding to the pod selected when the port-forward session started.

The real cluster source of truth is the Service selector.

In production, user traffic would normally go through Gateway, Ingress, LoadBalancer, or a service mesh instead of local port-forwarding.

## Roll back active traffic to blue

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Change the active Service selector from green back to blue:

    python3 -c 'from pathlib import Path; p=Path("k8s/blue-green/service-active.yaml"); text=p.read_text(); p.write_text(text.replace("version: green", "version: blue"))'

Verify:

    grep -nE 'selector:|app: bluegreen-demo|version:' \
      k8s/blue-green/service-active.yaml

Commit and push:

    git add k8s/blue-green/service-active.yaml
    git commit -m "Rollback blue green active traffic to blue"
    git push

Refresh Argo CD:

    kubectl annotate application bluegreen-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify the active Service selector:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

Expected:

    selector:
      app: bluegreen-demo
      version: blue

Restart the active port-forward:

    kubectl port-forward svc/bluegreen-demo -n bluegreen-demo 8084:80

Verify:

    curl -s http://localhost:8084 | grep -E 'Active color|Version'
    curl -s http://localhost:8085 | grep -E 'Active color|Version'
    curl -s http://localhost:8086 | grep -E 'Active color|Version'

Expected after rollback:

    8084 active        -> blue v1
    8085 blue preview  -> blue v1
    8086 green preview -> green v2

This proves rollback is fast because blue never went away.

## Test Argo CD self-heal

The desired active state is now blue.

Manually change the cluster Service to green:

    kubectl patch svc bluegreen-demo -n bluegreen-demo \
      --type merge \
      -p '{"spec":{"selector":{"app":"bluegreen-demo","version":"green"}}}'

Check the temporary drift:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

Wait 30 to 60 seconds.

Check again:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector
    kubectl get applications -n argocd

Expected:

    selector:
      app: bluegreen-demo
      version: blue

    bluegreen-demo   Synced   Healthy

This proves Argo CD corrected manual drift and restored the Git desired state.

## Troubleshooting

### Application is OutOfSync

Refresh the Application:

    kubectl annotate application bluegreen-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Or use the Argo CD UI:

    Application -> SYNC -> SYNCHRONIZE

### Active app still shows the old color

Restart the active port-forward on port `8084`.

Then refresh the browser or use curl:

    curl -s http://localhost:8084 | grep -E 'Active color|Version'

### Service selector is not changing

Check the active Service in Git:

    grep -nE 'selector:|app: bluegreen-demo|version:' \
      k8s/blue-green/service-active.yaml

Make sure the change was committed and pushed:

    git status --short
    git log --oneline -3

Check the cluster Service:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

### Argo CD cannot find the repo path

Check the Application path:

    k8s/blue-green

Make sure the sample repository has that folder and the changes are pushed.

## Cleanup

Delete the Argo CD Application:

    kubectl delete application bluegreen-demo -n argocd --ignore-not-found

Delete the namespace:

    kubectl delete namespace bluegreen-demo --ignore-not-found

Verify:

    kubectl get applications -n argocd
    kubectl get ns bluegreen-demo 2>/dev/null || echo "bluegreen-demo namespace removed"

Stop all port-forward terminals with `Ctrl+C`.

This cleanup does not remove Argo CD.

## What you completed

You completed:

- Blue and green versions running side by side
- Active Service routing to blue
- Blue preview Service
- Green preview Service
- Git-based blue to green switch
- Argo CD reconciliation
- Browser verification of the active version
- Git-based rollback to blue
- Argo CD self-heal test
- Cleanup path

This prepares you for:

    Professional Lab 05 - Canary Deployment

## Important note

This lab uses a Kubernetes Service selector to teach the blue/green concept clearly.

In production, blue/green can also be implemented using:

- Gateway API route switching
- Ingress switching
- LoadBalancer switching
- Service mesh traffic routing
- Progressive delivery tools

The key idea is the same:

    Keep the old version running.
    Deploy the new version side by side.
    Preview the new version.
    Switch active traffic intentionally.
    Roll back quickly if needed.
