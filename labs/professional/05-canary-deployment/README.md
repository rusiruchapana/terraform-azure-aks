# Professional Lab 05 - Canary Deployment

This lab shows how to release a new application version gradually using Argo CD, Gateway API, and HTTPRoute weighted traffic.

Unlike blue/green deployment, canary deployment does not move all traffic at once. A small percentage of traffic goes to the new version first. If it looks good, traffic is increased gradually. If something goes wrong, traffic can be rolled back to the stable version.

## What this lab does

This lab deploys:

- a stable application version
- a canary application version
- a visual traffic viewer
- an HTTPRoute that controls traffic weights
- an Argo CD Application that syncs the desired state from Git

You will test these stages:

- 90% stable / 10% canary
- 50% stable / 50% canary
- 0% stable / 100% canary
- 100% stable / 0% canary rollback

## What you will learn

You will learn:

- what canary deployment means
- why stable and canary versions run at the same time
- how Gateway API HTTPRoute weights control traffic distribution
- what Argo CD does during a canary rollout
- how to observe canary traffic visually in a browser
- how to promote canary traffic
- how to roll back to stable traffic

## Architecture

This lab uses two repositories.

Platform and lab repository:

    terraform-azure-aks

This repository contains:

    labs/professional/05-canary-deployment/argocd/application.yaml
    labs/professional/05-canary-deployment/README.md
    labs/professional/05-canary-deployment/README.si.md

Sample application GitOps repository:

    aks-gitops-sample-app

The sample repository contains the desired state:

    k8s/canary

The canary desired state contains:

    namespace.yaml
    configmap-stable.yaml
    configmap-canary.yaml
    configmap-viewer.yaml
    deployment-stable.yaml
    deployment-canary.yaml
    deployment-viewer.yaml
    service-stable.yaml
    service-canary.yaml
    service-viewer.yaml
    httproute.yaml
    kustomization.yaml

## Components

Stable app:

    Deployment: canary-stable
    Service: canary-stable
    Track: stable
    Version: v1

Canary app:

    Deployment: canary-v2
    Service: canary-v2
    Track: canary
    Version: v2

Traffic viewer:

    Deployment: canary-viewer
    Service: canary-viewer
    Browser path: /canary-viewer/

Gateway route:

    HTTPRoute: canary-demo
    Gateway: platform-gateway/public-gateway

The HTTPRoute has two routes:

    /canary-viewer -> canary-viewer service
    /              -> weighted stable/canary backends

## What this lab requires

This lab requires:

- AKS cluster access
- kubectl
- Git
- Argo CD installed
- Gateway API installed
- shared Gateway available as `platform-gateway/public-gateway`
- your fork of `aks-gitops-sample-app`

Verify Argo CD:

    kubectl get ns argocd
    kubectl get pods -n argocd
    kubectl get crd applications.argoproj.io

Verify Gateway API:

    kubectl get gateway -A
    kubectl get gateway public-gateway -n platform-gateway

Expected:

    PROGRAMMED=True

## Set lab variables

Set your sample repository URL:

    REPO_URL="https://github.com/<your-user-or-org>/aks-gitops-sample-app.git"

Set your platform repository directory:

    PLATFORM_REPO_DIR="/Users/andrewferdinandus/projcts/terraform-azure-aks"

Set your sample repository directory:

    SAMPLE_REPO_DIR="/Users/andrewferdinandus/projcts/aks-gitops-sample-app"

Set your Gateway IP:

    GATEWAY_IP="<your-gateway-external-ip>"

Example:

    GATEWAY_IP="104.43.75.139"

Verify:

    echo "$REPO_URL"
    echo "$PLATFORM_REPO_DIR"
    echo "$SAMPLE_REPO_DIR"
    echo "$GATEWAY_IP"

## Verify canary desired state

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Check files:

    find k8s/canary -maxdepth 2 -type f | sort

Check route weights:

    grep -nE 'name: canary-stable|name: canary-v2|weight:|value:' \
      k8s/canary/httproute.yaml

The recommended starter state is:

    canary-stable weight: 90
    canary-v2 weight: 10

Check the visual viewer configuration:

    grep -RInE 'canary-viewer|canary-viewer-content|mountPath|replacePrefixMatch' \
      k8s/canary

Important expected detail:

    canary-viewer content is mounted to /usr/share/nginx/html/index.html

This is required because the viewer service serves from nginx root.

## Deploy with Argo CD

Run this from the platform repository:

    cd "$PLATFORM_REPO_DIR"

Apply the Argo CD Application:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/05-canary-deployment/argocd/application.yaml \
      | kubectl apply -f -

Refresh:

    kubectl annotate application canary-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify:

    kubectl get applications -n argocd
    kubectl get pods -n canary-demo --show-labels
    kubectl get svc -n canary-demo
    kubectl get httproute -n canary-demo

Expected:

    canary-demo Synced Healthy

Expected pods:

    canary-stable
    canary-v2
    canary-viewer

Expected services:

    canary-stable
    canary-v2
    canary-viewer

## Open the visual traffic viewer

Open:

    http://<gateway-ip>/canary-viewer/

Example:

    http://104.43.75.139/canary-viewer/

The viewer sends repeated requests to the active Gateway route and counts which backend responds.

Use:

    Run 50 requests

The viewer shows:

- total requests
- stable response count and percentage
- canary response count and percentage
- last response

## Stage 1 - 90/10 canary

In this stage, most traffic goes to stable and a small amount goes to canary.

Expected weights:

    canary-stable weight: 90
    canary-v2 weight: 10

Verify:

    kubectl describe httproute canary-demo -n canary-demo | grep -E 'Name:|Weight:|Value:' -A1

Open the viewer:

    http://<gateway-ip>/canary-viewer/

Click:

    Run 50 requests

Expected result:

    most responses are stable
    a small number of responses are canary

Example tested result:

    Stable responses: 43 (86%)
    Canary responses: 7 (14%)

Weighted routing is approximate. Small test runs will not always be exactly 90/10.

## Stage 2 - Increase canary to 50/50

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Update HTTPRoute weights:

    python3 -c 'from pathlib import Path; p=Path("k8s/canary/httproute.yaml"); text=p.read_text(); text=text.replace("weight: 90", "weight: 50"); text=text.replace("weight: 10", "weight: 50"); p.write_text(text)'

Verify:

    grep -nE 'name: canary-stable|name: canary-v2|weight:' \
      k8s/canary/httproute.yaml

Commit and push:

    git add k8s/canary/httproute.yaml
    git commit -m "Increase canary demo traffic to fifty percent"
    git push

Refresh Argo CD:

    kubectl annotate application canary-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify:

    kubectl describe httproute canary-demo -n canary-demo | grep -E 'Name:|Weight:|Value:' -A1

Open the viewer again and click:

    Run 50 requests

Expected result:

    stable and canary responses are close

Example tested result:

    Stable responses: 21 (42%)
    Canary responses: 29 (58%)

A CLI test also produced:

    25 Track: stable
    25 Track: canary

## Stage 3 - Promote canary to 100%

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Set stable to 0 and canary to 100 in `k8s/canary/httproute.yaml`:

    canary-stable weight: 0
    canary-v2 weight: 100

Commit and push:

    git add k8s/canary/httproute.yaml
    git commit -m "Promote canary demo traffic to version two"
    git push

Refresh Argo CD:

    kubectl annotate application canary-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Open the viewer and click:

    Run 50 requests

Expected result:

    Stable responses: 0
    Canary responses: 50

CLI tested result:

    30 Track: canary

## Stage 4 - Roll back to stable

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Set stable to 100 and canary to 0 in `k8s/canary/httproute.yaml`:

    canary-stable weight: 100
    canary-v2 weight: 0

Commit and push:

    git add k8s/canary/httproute.yaml
    git commit -m "Rollback canary demo traffic to stable"
    git push

Refresh Argo CD:

    kubectl annotate application canary-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Open the viewer and click:

    Run 50 requests

Expected result:

    Stable responses: 50
    Canary responses: 0

CLI tested result:

    30 Track: stable

## Reset starter state

Before committing the final lab state, reset the route back to the recommended starter state:

    canary-stable weight: 90
    canary-v2 weight: 10

Verify:

    grep -nE 'name: canary-stable|name: canary-v2|weight:' \
      k8s/canary/httproute.yaml

Commit and push if needed:

    git add k8s/canary/httproute.yaml
    git commit -m "Reset canary demo starter traffic split"
    git push

## Troubleshooting

### Browser shows default nginx instead of the viewer

Check the viewer deployment mount:

    kubectl describe deployment canary-viewer -n canary-demo | grep -A20 -E 'Mounts|Volumes'

The viewer ConfigMap must be mounted to:

    /usr/share/nginx/html/index.html

Check inside the pod:

    POD=$(kubectl get pod -n canary-demo -l app=canary-viewer -o jsonpath='{.items[0].metadata.name}')
    kubectl exec -n canary-demo "$POD" -- cat /usr/share/nginx/html/index.html | grep 'Canary Traffic Viewer'

### Gateway returns 404 for a path

The backend nginx app serves `/`.

The weighted app route should use:

    value: /

If you use a path such as `/canary` without rewrite, nginx receives `/canary` and can return 404.

### Viewer route does not work

Check the HTTPRoute:

    kubectl describe httproute canary-demo -n canary-demo

The viewer rule should use:

    value: /canary-viewer
    URLRewrite ReplacePrefixMatch /

### Argo CD shows Unknown

Describe the Application:

    kubectl describe application canary-demo -n argocd

Common causes:

- YAML syntax error
- kustomize build error
- repo changes not pushed
- invalid HTTPRoute field

## Cleanup

Delete the Argo CD Application:

    kubectl delete application canary-demo -n argocd --ignore-not-found

Delete the namespace:

    kubectl delete namespace canary-demo --ignore-not-found

Verify:

    kubectl get applications -n argocd
    kubectl get ns canary-demo 2>/dev/null || echo "canary-demo namespace removed"
    kubectl get httproute -A

## What you completed

You completed:

- stable and canary deployments running side by side
- HTTPRoute weighted traffic routing
- Argo CD managed canary rollout
- browser-based traffic visualizer
- 90/10 canary test
- 50/50 canary test
- 100% canary promotion
- rollback to stable
- cleanup path

This prepares you for:

    Professional Lab 06 - Incident Troubleshooting
