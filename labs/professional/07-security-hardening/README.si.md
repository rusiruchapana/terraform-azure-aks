# Professional Lab 07 - Security Hardening

මෙම lab එකෙන් AKS මත Kubernetes application security hardening ඉගෙන ගන්නවා. Argo CD සහ GitOps use කරලා workload එක secure කරනවා.

ඔයා working but weak baseline deployment එකකින් පටන් ගන්නවා. ඊට පස්සේ Git හරහා workload එක harden කරනවා. App එක තවම වැඩ කරන බව සහ pod security posture එක improve වෙලා තියෙන බව verify කරනවා.

Professional security workflow එක:

    deploy
    inspect
    identify weak defaults
    harden through Git
    verify the app still works
    verify the security settings improved

## What this lab does

මෙම lab එක NGINX application එක stages දෙකකින් deploy කරනවා.

Stage 1 - Baseline:

- standard nginx image
- root user ලෙස run වෙනවා
- explicit container securityContext නැහැ
- resource requests or limits නැහැ
- app වැඩ කරනවා, නමුත් security posture weak

Stage 2 - Hardened:

- unprivileged nginx image
- non-root user ලෙස run වෙනවා
- privilege escalation disabled
- Linux capabilities dropped
- read-only root filesystem enabled
- seccomp RuntimeDefault enabled
- resource requests and limits added
- readiness and liveness probes added
- writable paths emptyDir volumes වලට move කරලා තියෙනවා

## What you will learn

ඔයා ඉගෙන ගන්නවා:

- working app එකක් හැමවිටම secure app එකක් නොවන හේතුව
- container එක run වෙන්නේ කුමන user එකෙන්ද inspect කරන විදිය
- missing security controls identify කරන විදිය
- `securityContext` use කරන විදිය
- container එක non-root run කරන විදිය
- privilege escalation prevent කරන විදිය
- Linux capabilities drop කරන විදිය
- read-only root filesystem use කරන විදිය
- resource requests and limits වැදගත් ඇයි
- hardening කළාට පස්සෙත් app එක working තබාගන්නා විදිය
- Argo CD Git වල security changes apply කරන විදිය

## Architecture

මෙම lab එක repositories දෙකක් use කරනවා.

Platform සහ lab repository:

    terraform-azure-aks

මෙම repository එකේ තියෙන්නේ:

    labs/professional/07-security-hardening/argocd/application.yaml
    labs/professional/07-security-hardening/README.md
    labs/professional/07-security-hardening/README.si.md

Sample application GitOps repository:

    aks-gitops-sample-app

Sample repository එකේ තියෙන්නේ:

    k8s/security-hardening

Desired state එකේ files:

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

මෙම lab එකට අවශ්‍යයි:

- AKS cluster access
- kubectl
- Git
- Argo CD installed
- Gateway API installed
- shared Gateway `platform-gateway/public-gateway`
- `aks-gitops-sample-app` fork එක

Argo CD verify කරන්න:

    kubectl get ns argocd
    kubectl get pods -n argocd
    kubectl get crd applications.argoproj.io

Gateway API verify කරන්න:

    kubectl get gateway -A
    kubectl get gateway public-gateway -n platform-gateway

Expected:

    PROGRAMMED=True

## Set lab variables

Sample repository URL set කරන්න:

    REPO_URL="https://github.com/<your-user-or-org>/aks-gitops-sample-app.git"

Platform repository directory set කරන්න:

    PLATFORM_REPO_DIR="/Users/andrewferdinandus/projcts/terraform-azure-aks"

Sample repository directory set කරන්න:

    SAMPLE_REPO_DIR="/Users/andrewferdinandus/projcts/aks-gitops-sample-app"

Gateway IP set කරන්න:

    GATEWAY_IP="<your-gateway-external-ip>"

Example:

    GATEWAY_IP="104.43.75.139"

Verify කරන්න:

    echo "$REPO_URL"
    echo "$PLATFORM_REPO_DIR"
    echo "$SAMPLE_REPO_DIR"
    echo "$GATEWAY_IP"

## Verify desired state

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Files check කරන්න:

    find k8s/security-hardening -maxdepth 2 -type f | sort

Manifests render කරන්න:

    kubectl kustomize k8s/security-hardening >/tmp/security-rendered.yaml && echo "security kustomize OK"

Important values check කරන්න:

    grep -RInE 'security-demo|nginx|Mode:|runAsNonRoot|allowPrivilegeEscalation|readOnlyRootFilesystem|RuntimeDefault|resources:' \
      k8s/security-hardening

## Deploy with Argo CD

මෙය platform repository එකෙන් run කරන්න:

    cd "$PLATFORM_REPO_DIR"

Argo CD Application apply කරන්න:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/07-security-hardening/argocd/application.yaml \
      | kubectl apply -f -

Refresh කරන්න:

    kubectl annotate application security-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify කරන්න:

    kubectl get applications -n argocd
    kubectl get pods -n security-demo --show-labels
    kubectl get svc -n security-demo
    kubectl get httproute -n security-demo

Expected:

    security-demo Synced Healthy

Gateway හරහා test කරන්න:

    curl -s http://$GATEWAY_IP/security | grep -E 'Security|Status|Mode'

## Stage 1 - Baseline inspection

Baseline app එක වැඩ කරනවා, නමුත් weak security defaults තියෙනවා.

Running pod එක check කරන්න:

    POD=$(kubectl get pod -n security-demo -l app=security-demo -o jsonpath='{.items[0].metadata.name}')
    echo "$POD"

Container එක run වෙන්නේ කුමන user එකෙන්ද check කරන්න:

    kubectl exec -n security-demo "$POD" -- id

Hardening settings තියෙනවද check කරන්න:

    kubectl get deployment security-demo -n security-demo -o yaml | grep -E 'securityContext|resources|runAsNonRoot|allowPrivilegeEscalation|readOnlyRootFilesystem|capabilities' -A5 || echo "No explicit hardening found"

Expected baseline result:

    uid=0(root)
    resources: {}
    securityContext: {}

මෙයින් app එක වැඩ කළත් weak/default security settings සමඟ run වෙන බව පෙන්වයි.

## Stage 2 - Harden the deployment

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

ConfigMap එක hardened mode text එකට replace කරන්න:

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

Deployment එක hardened workload එකකට replace කරන්න:

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

Service target port replace කරන්න:

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

Validate කරන්න:

    kubectl kustomize k8s/security-hardening >/tmp/security-rendered.yaml && echo "security hardened kustomize OK"

Hardening fields check කරන්න:

    grep -RInE 'nginx-unprivileged|runAsNonRoot|allowPrivilegeEscalation|readOnlyRootFilesystem|RuntimeDefault|drop:|resources:|targetPort: 8080|Mode: hardened' \
      k8s/security-hardening

Commit සහ push කරන්න:

    git add k8s/security-hardening
    git commit -m "Harden security demo deployment"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application security-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Rollout එකට wait කරන්න:

    sleep 45

## Verify the hardened app still works

Argo CD සහ Kubernetes check කරන්න:

    kubectl get applications -n argocd
    kubectl get pods -n security-demo --show-labels
    kubectl get deployment security-demo -n security-demo

Gateway හරහා test කරන්න:

    curl -s http://$GATEWAY_IP/security | grep -E 'Security|Status|Mode'

Expected:

    Security Hardening Demo
    Status: running
    Mode: hardened

## Verify security improvement

Pod එකක් ගන්න:

    POD=$(kubectl get pod -n security-demo -l app=security-demo -o jsonpath='{.items[0].metadata.name}')
    echo "$POD"

User එක check කරන්න:

    kubectl exec -n security-demo "$POD" -- id

Expected:

    uid=101(nginx)

Deployment security settings check කරන්න:

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

Hardened container එක use කරනවා:

    readOnlyRootFilesystem: true

ඒ කියන්නේ container එකට root filesystem එකට write කරන්න බැහැ.

NGINX runtime එකේ writable paths කිහිපයක් අවශ්‍යයි. මෙම lab එක `emptyDir` volumes use කරලා writable temporary paths ලබා දෙනවා:

    /var/cache/nginx
    /var/run
    /tmp

ඒ නිසා root filesystem read-only තියාගෙන app එක working තබාගන්න පුළුවන්.

## Troubleshooting

### Hardened pod does not start

Pod events check කරන්න:

    kubectl get pods -n security-demo
    kubectl describe pod -n security-demo <pod-name> | sed -n '/Events:/,$p'

Common causes:

- wrong container port
- Service targetPort තවම 80 වෙත point කරනවා, 8080 නොවේ
- writable emptyDir path missing
- app root ලෙස run වෙන්න උත්සාහ කරනවා
- read-only filesystem required writes block කරනවා

### App works but Gateway does not

Service check කරන්න:

    kubectl get svc security-demo -n security-demo -o yaml | grep -A8 ports

Expected:

    port: 80
    targetPort: 8080

Endpoints check කරන්න:

    kubectl get endpoints security-demo -n security-demo

Route check කරන්න:

    kubectl describe httproute security-demo -n security-demo

### Pod still runs as root

Image සහ pod security context check කරන්න:

    kubectl get deployment security-demo -n security-demo -o yaml | grep -E 'image:|runAsNonRoot|runAsUser|runAsGroup' -A4

Expected image:

    nginxinc/nginx-unprivileged:1.27-alpine

Expected user:

    runAsUser: 101

## Cleanup

Argo CD Application delete කරන්න:

    kubectl delete application security-demo -n argocd --ignore-not-found

Namespace delete කරන්න:

    kubectl delete namespace security-demo --ignore-not-found

Verify කරන්න:

    kubectl get applications -n argocd
    kubectl get ns security-demo 2>/dev/null || echo "security-demo namespace removed"
    kubectl get httproute -A

## What you completed

ඔයා complete කළා:

- Argo CD හරහා baseline app deploy කිරීම
- baseline app වැඩ කරන බව confirm කිරීම
- baseline pod root ලෙස run වෙන බව verify කිරීම
- Git හරහා deployment harden කිරීම
- unprivileged image එකකට switch කිරීම
- non-root execution enable කිරීම
- privilege escalation disable කිරීම
- Linux capabilities drop කිරීම
- read-only root filesystem enable කිරීම
- resource requests and limits add කිරීම
- probes add කිරීම
- hardened app තවම වැඩ කරන බව verify කිරීම
- pod එක uid 101 ලෙස run වෙන බව verify කිරීම

මෙයින් Professional lab set එක complete වෙනවා.
