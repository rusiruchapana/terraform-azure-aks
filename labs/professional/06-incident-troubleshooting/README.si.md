# Professional Lab 06 - Incident Troubleshooting

මෙම lab එකෙන් AKS incident troubleshooting ඉගෙන ගන්නවා. Argo CD, GitOps, Kubernetes diagnostics, Services, Endpoints, සහ Gateway API use කරලා production-style incidents troubleshoot කරනවා.

ඔයා healthy application එකකින් පටන් ගන්නවා. පසුව Git හරහා realistic incidents introduce කරනවා. Symptoms observe කරලා root cause හොයාගෙන fix එකත් Git හරහා කරනවා.

Goal එක commands run කිරීම විතරක් නෙවෙයි. Goal එක production-style Kubernetes incidents troubleshoot කරන විදිය ඉගෙන ගැනීමයි.

## What this lab does

මෙම lab එක Argo CD හරහා small NGINX application එකක් deploy කරනවා.

ඔයා incidents දෙකක් test කරනවා:

1. Bad image tag
   - Pod එක `ImagePullBackOff` වෙයි
   - Events වල image tag එක නැති බව පෙන්වයි
   - Fix එක Git හරහා කරයි

2. Bad Service selector
   - Pods healthy
   - Service එකට endpoints නැහැ
   - Gateway `503 Service Temporarily Unavailable` return කරයි
   - Fix එක Git හරහා කරයි

## What you will learn

ඔයා ඉගෙන ගන්නවා:

- Argo CD හොඳ සහ වැරදි Git desired state දෙකම apply කරන ආකාරය
- failed pods inspect කරන විදිය
- Kubernetes events කියවන විදිය
- `ImagePullBackOff` identify කරන විදිය
- Services සහ Endpoints inspect කරන විදිය
- label selectors Services සහ Pods connect කරන ආකාරය
- healthy Pod එකක් තිබුණත් app unreachable වෙන්න පුළුවන් හේතුව
- direct cluster patch නොකර GitOps හරහා incidents fix කරන විදිය

## Architecture

මෙම lab එක repositories දෙකක් use කරනවා.

Platform සහ lab repository:

    terraform-azure-aks

මෙම repository එකේ තියෙන්නේ:

    labs/professional/06-incident-troubleshooting/argocd/application.yaml
    labs/professional/06-incident-troubleshooting/README.md
    labs/professional/06-incident-troubleshooting/README.si.md

Sample application GitOps repository:

    aks-gitops-sample-app

Sample repository එකේ තියෙන්නේ:

    k8s/incident

Incident desired state එකේ files:

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

## Verify healthy desired state

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Files check කරන්න:

    find k8s/incident -maxdepth 2 -type f | sort

Image එක check කරන්න:

    grep -nE 'image:' k8s/incident/deployment.yaml

Expected:

    image: nginx:1.27-alpine

Service selector check කරන්න:

    grep -nE 'selector:|app:' k8s/incident/service.yaml

Expected:

    selector:
      app: incident-demo

Manifests render කරන්න:

    kubectl kustomize k8s/incident >/tmp/incident-rendered.yaml && echo "incident kustomize OK"

## Deploy with Argo CD

මෙය platform repository එකෙන් run කරන්න:

    cd "$PLATFORM_REPO_DIR"

Argo CD Application apply කරන්න:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/06-incident-troubleshooting/argocd/application.yaml \
      | kubectl apply -f -

Refresh කරන්න:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify කරන්න:

    kubectl get applications -n argocd
    kubectl get pods -n incident-demo --show-labels
    kubectl get svc -n incident-demo
    kubectl get httproute -n incident-demo

Expected:

    incident-demo Synced Healthy

Gateway හරහා test කරන්න:

    curl -s http://$GATEWAY_IP/incident | grep -E 'Incident|Status|Version'

Expected:

    Incident Troubleshooting Demo
    Status: healthy
    Version: v1

## Incident 1 - Bad image tag

මෙම incident එකේ Deployment image tag එක නොපවතින tag එකකට change කරනවා.

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Incident එක inject කරන්න:

    python3 -c 'from pathlib import Path; p=Path("k8s/incident/deployment.yaml"); text=p.read_text(); p.write_text(text.replace("image: nginx:1.27-alpine", "image: nginx:not-a-real-tag"))'

Verify කරන්න:

    grep -nE 'image:' k8s/incident/deployment.yaml

Commit සහ push කරන්න:

    git add k8s/incident/deployment.yaml
    git commit -m "Inject incident demo bad image tag"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Wait කරලා inspect කරන්න:

    sleep 30

    kubectl get applications -n argocd
    kubectl get pods -n incident-demo
    kubectl get deployment incident-demo -n incident-demo

Bad pod එක හොයන්න:

    BAD_POD=$(kubectl get pod -n incident-demo -o jsonpath='{.items[?(@.status.containerStatuses[0].state.waiting.reason=="ImagePullBackOff")].metadata.name}' 2>/dev/null)
    echo "$BAD_POD"

Pod events describe කරන්න:

    kubectl describe pod -n incident-demo "$BAD_POD" | sed -n '/Events:/,$p'

Expected symptoms:

    ImagePullBackOff
    ErrImagePull
    nginx:not-a-real-tag: not found

## Fix Incident 1

Image tag එක Git හරහා fix කරන්න.

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Image එක fix කරන්න:

    python3 -c 'from pathlib import Path; p=Path("k8s/incident/deployment.yaml"); text=p.read_text(); p.write_text(text.replace("image: nginx:not-a-real-tag", "image: nginx:1.27-alpine"))'

Verify කරන්න:

    grep -nE 'image:' k8s/incident/deployment.yaml

Commit සහ push කරන්න:

    git add k8s/incident/deployment.yaml
    git commit -m "Fix incident demo image tag"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Recovery verify කරන්න:

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

මෙම incident එකේ Pods healthy වුණත් Service selector එක වැරදියි.

App එක running. හැබැයි Service එකට matching Pods හම්බවෙන්නේ නැහැ.

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Bad selector එකක් තියෙන Service එකට replace කරන්න:

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

Verify කරන්න:

    grep -nE 'selector:|app:' k8s/incident/service.yaml

Commit සහ push කරන්න:

    git add k8s/incident/service.yaml
    git commit -m "Inject incident demo bad service selector"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Wait කරලා inspect කරන්න:

    sleep 30

    kubectl get pods -n incident-demo --show-labels
    kubectl get svc incident-demo -n incident-demo -o yaml | grep -A5 selector
    kubectl get endpoints incident-demo -n incident-demo
    kubectl get endpointslices -n incident-demo -l kubernetes.io/service-name=incident-demo

Gateway response check කරන්න:

    curl -i http://$GATEWAY_IP/incident | head -30

Expected symptoms:

    Pods Running with app=incident-demo
    Service selector is app=wrong-incident-demo
    Endpoints are empty
    Gateway returns HTTP 503

මෙයින් healthy Pods තිබුණත් traffic routing healthy කියලා guarantee වෙන්නේ නැහැ කියලා prove වෙනවා.

## Fix Incident 2

Service selector එක Git හරහා fix කරන්න.

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Correct Service selector restore කරන්න:

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

Verify කරන්න:

    grep -nE 'selector:|app:' k8s/incident/service.yaml

Commit සහ push කරන්න:

    git add k8s/incident/service.yaml
    git commit -m "Fix incident demo service selector"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application incident-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Recovery verify කරන්න:

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

App එක unhealthy නම් මේ order එකට check කරන්න:

    kubectl get applications -n argocd
    kubectl get pods -n <namespace>
    kubectl describe pod -n <namespace> <pod-name>
    kubectl get deployment -n <namespace>
    kubectl get svc -n <namespace>
    kubectl get endpoints -n <namespace>
    kubectl get endpointslices -n <namespace>
    kubectl describe httproute -n <namespace> <route-name>

Useful questions:

- Argo CD desired Git state sync කළාද?
- Pods running ද?
- Pods ready ද?
- Image pull errors තියෙනවද?
- Service selector Pod labels වලට match වෙනවද?
- Service එකට endpoints තියෙනවද?
- HTTPRoute accepted ද?
- Gateway HTTP error එකක් return කරනවද?

## Cleanup

Argo CD Application delete කරන්න:

    kubectl delete application incident-demo -n argocd --ignore-not-found

Namespace delete කරන්න:

    kubectl delete namespace incident-demo --ignore-not-found

Verify කරන්න:

    kubectl get applications -n argocd
    kubectl get ns incident-demo 2>/dev/null || echo "incident-demo namespace removed"
    kubectl get httproute -A

## What you completed

ඔයා complete කළා:

- Argo CD හරහා healthy app එකක් deploy කිරීම
- Gateway API හරහා app expose කිරීම
- bad image tag incident එකක් create කිරීම
- `ImagePullBackOff` diagnose කිරීම
- Git හරහා image fix කිරීම
- bad Service selector incident එකක් create කිරීම
- empty endpoints සහ Gateway 503 diagnose කිරීම
- Git හරහා Service selector fix කිරීම
- production-style Kubernetes troubleshooting practice කිරීම

මෙය next lab එකට prepare කරනවා:

    Professional Lab 07 - Security Hardening
