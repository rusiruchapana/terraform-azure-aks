# Professional Lab 07 - Security Hardening

This lab teaches Kubernetes application security hardening on AKS using Argo CD and GitOps.

You will start with a working but weak baseline deployment. Then you will harden the workload through Git and verify that the application still works while the pod security posture improves.

The goal is to learn a professional security workflow:

    deploy
    inspect
    identify weak defaults
    harden through Git
    verify the app still works
    verify the security settings improved

## What this lab does

This lab deploys an NGINX application in two stages.

Stage 1 - Baseline:

- standard nginx image
- runs as root
- no explicit container securityContext
- no resource requests or limits
- app works, but security posture is weak

Stage 2 - Hardened:

- unprivileged nginx image
- runs as non-root user
- privilege escalation disabled
- Linux capabilities dropped
- read-only root filesystem enabled
- seccomp RuntimeDefault enabled
- resource requests and limits added
- readiness and liveness probes added
- writable paths moved to emptyDir volumes

## What you will learn

You will learn:

- why a working app is not always a secure app
- how to inspect the user a container runs as
- how to identify missing security controls
- how to use `securityContext`
- how to run a container as non-root
- how to prevent privilege escalation
- how to drop Linux capabilities
- how to use a read-only root filesystem
- why resource requests and limits matter
- how to keep the application working after hardening
- how Argo CD applies security changes from Git

## Architecture

This lab uses two repositories.

Platform and lab repository:

    terraform-azure-aks

This repository contains:

    labs/professional/07-security-hardening/argocd/application.yaml
    labs/professional/07-security-hardening/README.md
    labs/professional/07-security-hardening/README.si.md

Sample application GitOps repository:

    aks-gitops-sample-app

The sample repository contains:

    k8s/security-hardening

The desired state contains:

    namespace.yaml
    configmap.yaml
    deployment.yaml
    service.yaml
    httproute.yaml
    kustomization.yaml

## Components

Application:

    Deployment: security-demo
    Service: security-demo
    Namespace: security-demo

Gateway route:

    HTTPRoute: security-demo
    Gateway: platform-gateway/public-gateway
    Path: /security

Argo CD:

    Application: security-demo
    Source path: k8s/security-hardening

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

## Verify desired state

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Check files:

    find k8s/security-hardening -maxdepth 2 -type f | sort

Render the manifests:

    kubectl kustomize k8s/security-hardening >/tmp/security-rendered.yaml && echo "security kustomize OK"

Check important values:

    grep -RInE 'security-demo|nginx|Mode:|runAsNonRoot|allowPrivilegeEscalation|readOnlyRootFilesystem|RuntimeDefault|resources:' \
      k8s/security-hardening

## Deploy with Argo CD

Run this from the platform repository:

    cd "$PLATFORM_REPO_DIR"

Apply the Argo CD Application:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/07-security-hardening/argocd/application.yaml \
      | kubectl apply -f -

Refresh:

    kubectl annotate application security-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify:

    kubectl get applications -n argocd
    kubectl get pods -n security-demo --show-labels
    kubectl get svc -n security-demo
    kubectl get httproute -n security-demo

Expected:

    security-demo Synced Healthy

Test through Gateway:

    curl -s http://$GATEWAY_IP/security | grep -E 'Security|Status|Mode'

## Stage 1 - Baseline inspection

The baseline app works, but it has weak security defaults.

Check the running pod:

    POD=$(kubectl get pod -n security-demo -l app=security-demo -o jsonpath='{.items[0].metadata.name}')
    echo "$POD"

Check which user the container runs as:

    kubectl exec -n security-demo "$POD" -- id

Check for hardening settings:

    kubectl get deployment security-demo -n security-demo -o yaml | grep -E 'securityContext|resources|runAsNonRoot|allowPrivilegeEscalation|readOnlyRootFilesystem|capabilities' -A5 || echo "No explicit hardening found"

Expected baseline result:

    uid=0(root)
    resources: {}
    securityContext: {}

This means the app works, but it is running with weak/default security settings.

## Stage 2 - Harden the deployment

Run this from the sample repository:

    cd "$SAMPLE_REPO_DIR"

Replace the ConfigMap with hardened mode text:

    cat > k8s/security-hardening/configmap.yaml <<'CM'
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: security-demo-content
      namespace: security-demo
    data:
      index.html: |
        <html>
        <body>
          <h1>Security Hardening Demo</h1>
          <p>Status: running</p>
          <p>Mode: hardened</p>
        </body>
        </html>
    CM

Replace the Deployment with a hardened workload:

    cat > k8s/security-hardening/deployment.yaml <<'DEPLOY'
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: security-demo
      namespace: security-demo
      labels:
        app: security-demo
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: security-demo
      template:
        metadata:
          labels:
            app: security-demo
        spec:
          nodeSelector:
            workload: user
          securityContext:
            runAsNonRoot: true
            runAsUser: 101
            runAsGroup: 101
            fsGroup: 101
            seccompProfile:
              type: RuntimeDefault
          containers:
            - name: nginx
              image: nginxinc/nginx-unprivileged:1.27-alpine
              ports:
                - name: http
                  containerPort: 8080
              securityContext:
                allowPrivilegeEscalation: false
                readOnlyRootFilesystem: true
                capabilities:
                  drop:
                    - ALL
              resources:
                requests:
                  cpu: 50m
                  memory: 64Mi
                limits:
                  cpu: 250m
                  memory: 128Mi
              readinessProbe:
                httpGet:
                  path: /
                  port: 8080
                initialDelaySeconds: 5
                periodSeconds: 10
              livenessProbe:
                httpGet:
                  path: /
                  port: 8080
                initialDelaySeconds: 15
                periodSeconds: 20
              volumeMounts:
                - name: content
                  mountPath: /usr/share/nginx/html
                - name: nginx-cache
                  mountPath: /var/cache/nginx
                - name: nginx-run
                  mountPath: /var/run
                - name: nginx-tmp
                  mountPath: /tmp
          volumes:
            - name: content
              configMap:
                name: security-demo-content
            - name: nginx-cache
              emptyDir: {}
            - name: nginx-run
              emptyDir: {}
            - name: nginx-tmp
              emptyDir: {}
    DEPLOY

Replace the Service target port:

    cat > k8s/security-hardening/service.yaml <<'SVC'
    apiVersion: v1
    kind: Service
    metadata:
      name: security-demo
      namespace: security-demo
      labels:
        app: security-demo
    spec:
      type: ClusterIP
      selector:
        app: security-demo
      ports:
        - name: http
          port: 80
          targetPort: 8080
    SVC

Validate:

    kubectl kustomize k8s/security-hardening >/tmp/security-rendered.yaml && echo "security hardened kustomize OK"

Check hardening fields:

    grep -RInE 'nginx-unprivileged|runAsNonRoot|allowPrivilegeEscalation|readOnlyRootFilesystem|RuntimeDefault|drop:|resources:|targetPort: 8080|Mode: hardened' \
      k8s/security-hardening

Commit and push:

    git add k8s/security-hardening
    git commit -m "Harden security demo deployment"
    git push

Refresh Argo CD:

    kubectl annotate application security-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Wait for rollout:

    sleep 45

## Verify the hardened app still works

Check Argo CD and Kubernetes:

    kubectl get applications -n argocd
    kubectl get pods -n security-demo --show-labels
    kubectl get deployment security-demo -n security-demo

Test through Gateway:

    curl -s http://$GATEWAY_IP/security | grep -E 'Security|Status|Mode'

Expected:

    Security Hardening Demo
    Status: running
    Mode: hardened

## Verify security improvement

Get a pod:

    POD=$(kubectl get pod -n security-demo -l app=security-demo -o jsonpath='{.items[0].metadata.name}')
    echo "$POD"

Check the user:

    kubectl exec -n security-demo "$POD" -- id

Expected:

    uid=101(nginx)

Check the deployment security settings:

    kubectl get deployment security-demo -n security-demo -o yaml | grep -E 'securityContext|runAsNonRoot|runAsUser|runAsGroup|fsGroup|seccompProfile|allowPrivilegeEscalation|readOnlyRootFilesystem|capabilities|resources:' -A8

Expected hardening:

    runAsNonRoot: true
    runAsUser: 101
    runAsGroup: 101
    fsGroup: 101
    seccompProfile:
      type: RuntimeDefault
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
      - ALL
    resources:
      requests and limits are present

## Why emptyDir volumes are needed

The hardened container uses:

    readOnlyRootFilesystem: true

That means the container cannot write to its root filesystem.

NGINX needs some writable paths at runtime. This lab provides writable temporary paths using `emptyDir` volumes:

    /var/cache/nginx
    /var/run
    /tmp

This lets the app keep running while the root filesystem remains read-only.

## Troubleshooting

### Hardened pod does not start

Check pod events:

    kubectl get pods -n security-demo
    kubectl describe pod -n security-demo <pod-name> | sed -n '/Events:/,$p'

Common causes:

- wrong container port
- Service targetPort still points to 80 instead of 8080
- missing writable emptyDir path
- app tries to run as root
- read-only filesystem blocks required writes

### App works but Gateway does not

Check the Service:

    kubectl get svc security-demo -n security-demo -o yaml | grep -A8 ports

Expected:

    port: 80
    targetPort: 8080

Check endpoints:

    kubectl get endpoints security-demo -n security-demo

Check route:

    kubectl describe httproute security-demo -n security-demo

### Pod still runs as root

Check the image and pod security context:

    kubectl get deployment security-demo -n security-demo -o yaml | grep -E 'image:|runAsNonRoot|runAsUser|runAsGroup' -A4

Expected image:

    nginxinc/nginx-unprivileged:1.27-alpine

Expected user:

    runAsUser: 101

## Cleanup

Delete the Argo CD Application:

    kubectl delete application security-demo -n argocd --ignore-not-found

Delete the namespace:

    kubectl delete namespace security-demo --ignore-not-found

Verify:

    kubectl get applications -n argocd
    kubectl get ns security-demo 2>/dev/null || echo "security-demo namespace removed"
    kubectl get httproute -A

## What you completed

You completed:

- deployed a baseline app through Argo CD
- confirmed the baseline app worked
- verified the baseline pod ran as root
- hardened the deployment through Git
- switched to an unprivileged image
- enabled non-root execution
- disabled privilege escalation
- dropped Linux capabilities
- enabled read-only root filesystem
- added resource requests and limits
- added probes
- verified the hardened app still worked
- verified the pod ran as uid 101

This completes the Professional lab set.
