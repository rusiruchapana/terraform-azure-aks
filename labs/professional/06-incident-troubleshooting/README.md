# Professional Lab 06 - Incident Troubleshooting

This lab teaches incident troubleshooting on AKS using Argo CD, GitOps, Kubernetes diagnostics, Services, Endpoints, and Gateway API.

You will start with a healthy application, introduce realistic incidents through Git, observe the symptoms, identify the root cause, and fix the issue through Git.

The goal is to learn how to troubleshoot production-style Kubernetes incidents, not just run commands.

## What this lab does

This lab deploys a small NGINX application through Argo CD.

You will test two incidents:

1. Bad image tag
   - Pod enters `ImagePullBackOff`
   - Events show that the image tag does not exist
   - Fix is made through Git

2. Bad Service selector
   - Pods are healthy
   - Service has no endpoints
   - Gateway returns `503 Service Temporarily Unavailable`
   - Fix is made through Git

## What you will learn

You will learn:

- how Argo CD applies both good and bad Git desired state
- how to inspect failed pods
- how to read Kubernetes events
- how to identify `ImagePullBackOff`
- how to inspect Services and Endpoints
- how label selectors connect Services to Pods
- how a healthy Pod can still be unreachable
- how to fix incidents using GitOps instead of direct cluster patching

## Architecture

This lab uses two repositories.

Platform and lab repository:

    terraform-azure-aks

This repository contains:

    labs/professional/06-incident-troubleshooting/argocd/application.yaml
    labs/professional/06-incident-troubleshooting/README.md
    labs/professional/06-incident-troubleshooting/README.si.md

Sample application GitOps repository:

    aks-gitops-sample-app

The sample repository contains:

    k8s/incident

The incident desired state contains:

    namespace.yaml
    configmap.yaml
    deployment.yaml
    service.yaml
    httproute.yaml
    kustomization.yaml

## Components

Application:

    Deployment: incident-demo
    Service: incident-demo
    Namespace: incident-demo

Gateway route:

    HTTPRoute: incident-demo
    Gateway: platform-gateway/public-gateway
    Path: /incident

Argo CD:

    Application: incident-demo
    Source path: k8s/incident

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

    PLATFORM_REPO_DIR="<local-path>/terraform-azure-aks"

Set your sample repository directory:

    SAMPLE_REPO_DIR="<local-path>/aks-gitops-sample-app"

Set your Gateway IP:

    GATEWAY_IP="<your-gateway-external-ip>"

Example:

    GATEWAY_IP="<gateway-public-ip>"

Verify:

    echo "$REPO_URL"
    echo "$PLATFORM_REPO_DIR"
    echo "$SAMPLE_REPO_DIR"
    echo "$GATEWAY_IP"

## Verify healthy desired state

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Check files:

    find k8s/incident -maxdepth 2 -type f | sort

Check the image:

    grep -nE 'image:' k8s/incident/deployment.yaml

Expected:

    image: nginx:1.27-alpine

Check the Service selector:

    grep -nE 'selector:|app:' k8s/incident/service.yaml

Expected:

    selector:
      app: incident-demo

Render the manifests:

    kubectl kustomize k8s/incident >/tmp/incident-rendered.yaml && echo "incident kustomize OK"

## Deploy with Argo CD

Run this from the platform repository:

    cd "$PLATFORM_REPO_DIR"

Apply the Argo CD Application:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/06-incident-troubleshooting/argocd/application.yaml \
      | kubectl apply -f -

Refresh:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify:

    kubectl get applications -n argocd
    kubectl get pods -n incident-demo --show-labels
    kubectl get svc -n incident-demo
    kubectl get httproute -n incident-demo

Expected:

    incident-demo Synced Healthy

Test through Gateway:

    curl -s http://$GATEWAY_IP/incident | grep -E 'Incident|Status|Version'

Expected:

    Incident Troubleshooting Demo
    Status: healthy
    Version: v1

## Incident 1 - Bad image tag

In this incident, the Deployment image tag is changed to a tag that does not exist.

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Inject the incident:

    python3 -c 'from pathlib import Path; p=Path("k8s/incident/deployment.yaml"); text=p.read_text(); p.write_text(text.replace("image: nginx:1.27-alpine", "image: nginx:not-a-real-tag"))'

Verify:

    grep -nE 'image:' k8s/incident/deployment.yaml

Commit and push:

    git add k8s/incident/deployment.yaml
    git commit -m "Inject incident demo bad image tag"
    git push

Refresh Argo CD:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Wait and inspect:

    sleep 30

    kubectl get applications -n argocd
    kubectl get pods -n incident-demo
    kubectl get deployment incident-demo -n incident-demo

Find the bad pod:

    BAD_POD=$(kubectl get pod -n incident-demo -o jsonpath='{.items[?(@.status.containerStatuses[0].state.waiting.reason=="ImagePullBackOff")].metadata.name}' 2>/dev/null)
    echo "$BAD_POD"

Describe the pod events:

    kubectl describe pod -n incident-demo "$BAD_POD" | sed -n '/Events:/,$p'

Expected symptoms:

    ImagePullBackOff
    ErrImagePull
    nginx:not-a-real-tag: not found

## Fix Incident 1

Fix the image tag through Git.

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Fix the image:

    python3 -c 'from pathlib import Path; p=Path("k8s/incident/deployment.yaml"); text=p.read_text(); p.write_text(text.replace("image: nginx:not-a-real-tag", "image: nginx:1.27-alpine"))'

Verify:

    grep -nE 'image:' k8s/incident/deployment.yaml

Commit and push:

    git add k8s/incident/deployment.yaml
    git commit -m "Fix incident demo image tag"
    git push

Refresh Argo CD:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify recovery:

    sleep 40

    kubectl get applications -n argocd
    kubectl get pods -n incident-demo
    kubectl get deployment incident-demo -n incident-demo

    curl -s http://$GATEWAY_IP/incident | grep -E 'Incident|Status|Version'

Expected:

    incident-demo Synced Healthy
    pods Running
    Status: healthy
    Version: v1

## Incident 2 - Bad Service selector

In this incident, Pods stay healthy but the Service selector is wrong.

The app is running, but the Service cannot find matching Pods.

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Replace the Service with a bad selector:

    cat > k8s/incident/service.yaml <<'SERVICE'
    apiVersion: v1
    kind: Service
    metadata:
      name: incident-demo
      namespace: incident-demo
      labels:
        app: incident-demo
    spec:
      type: ClusterIP
      selector:
        app: wrong-incident-demo
      ports:
        - name: http
          port: 80
          targetPort: 80
    SERVICE

Verify:

    grep -nE 'selector:|app:' k8s/incident/service.yaml

Commit and push:

    git add k8s/incident/service.yaml
    git commit -m "Inject incident demo bad service selector"
    git push

Refresh Argo CD:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Wait and inspect:

    sleep 30

    kubectl get pods -n incident-demo --show-labels
    kubectl get svc incident-demo -n incident-demo -o yaml | grep -A5 selector
    kubectl get endpoints incident-demo -n incident-demo
    kubectl get endpointslices -n incident-demo -l kubernetes.io/service-name=incident-demo

Check the Gateway response:

    curl -i http://$GATEWAY_IP/incident | head -30

Expected symptoms:

    Pods are Running with app=incident-demo
    Service selector is app=wrong-incident-demo
    Endpoints are empty
    Gateway returns HTTP 503

This proves that healthy Pods do not guarantee healthy traffic routing.

## Fix Incident 2

Fix the Service selector through Git.

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Restore the correct Service selector:

    cat > k8s/incident/service.yaml <<'SERVICE'
    apiVersion: v1
    kind: Service
    metadata:
      name: incident-demo
      namespace: incident-demo
      labels:
        app: incident-demo
    spec:
      type: ClusterIP
      selector:
        app: incident-demo
      ports:
        - name: http
          port: 80
          targetPort: 80
    SERVICE

Verify:

    grep -nE 'selector:|app:' k8s/incident/service.yaml

Commit and push:

    git add k8s/incident/service.yaml
    git commit -m "Fix incident demo service selector"
    git push

Refresh Argo CD:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify recovery:

    sleep 30

    kubectl get applications -n argocd
    kubectl get pods -n incident-demo --show-labels
    kubectl get svc incident-demo -n incident-demo -o yaml | grep -A5 selector
    kubectl get endpoints incident-demo -n incident-demo

    curl -s http://$GATEWAY_IP/incident | grep -E 'Incident|Status|Version'

Expected:

    endpoints are populated
    Gateway response is healthy
    Status: healthy
    Version: v1

## Troubleshooting checklist

When an app is unhealthy, check in this order:

    kubectl get applications -n argocd
    kubectl get pods -n <namespace>
    kubectl describe pod -n <namespace> <pod-name>
    kubectl get deployment -n <namespace>
    kubectl get svc -n <namespace>
    kubectl get endpoints -n <namespace>
    kubectl get endpointslices -n <namespace>
    kubectl describe httproute -n <namespace> <route-name>

Useful questions:

- Did Argo CD sync the desired Git state?
- Are Pods running?
- Are Pods ready?
- Are there image pull errors?
- Does the Service selector match Pod labels?
- Does the Service have endpoints?
- Is the HTTPRoute accepted?
- Is the Gateway returning an HTTP error?

## Cleanup

Delete the Argo CD Application:

    kubectl delete application incident-demo -n argocd --ignore-not-found

Delete the namespace:

    kubectl delete namespace incident-demo --ignore-not-found

Verify:

    kubectl get applications -n argocd
    kubectl get ns incident-demo 2>/dev/null || echo "incident-demo namespace removed"
    kubectl get httproute -A

## What you completed

You completed:

- deployed a healthy app with Argo CD
- exposed the app through Gateway API
- created a bad image tag incident
- diagnosed `ImagePullBackOff`
- fixed the image through Git
- created a bad Service selector incident
- diagnosed empty endpoints and Gateway 503
- fixed the Service selector through Git
- practiced production-style Kubernetes troubleshooting

This prepares you for:

    Professional Lab 07 - Security Hardening
