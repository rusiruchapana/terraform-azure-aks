# Professional Lab 05 - Canary Deployment

මෙම lab එකෙන් Argo CD, Gateway API, සහ HTTPRoute weighted traffic use කරලා new application version එකක් gradual විදියට release කරන ආකාරය ඉගෙන ගන්නවා.

Blue/green deployment වලදී traffic එක එකවර switch වෙනවා. Canary deployment වලදී new version එකට මුලින්ම traffic එකේ පොඩි percentage එකක් යවනවා. ඒක හොඳ නම් traffic වැඩි කරනවා. අවුලක් තිබුණොත් stable version එකට rollback කරනවා.

## What this lab does

මෙම lab එක deploy කරනවා:

- stable application version එකක්
- canary application version එකක්
- visual traffic viewer එකක්
- traffic weights control කරන HTTPRoute එකක්
- Git desired state sync කරන Argo CD Application එකක්

ඔයා මේ stages test කරනවා:

- 90% stable / 10% canary
- 50% stable / 50% canary
- 0% stable / 100% canary
- 100% stable / 0% canary rollback

## What you will learn

ඔයා ඉගෙන ගන්නවා:

- canary deployment කියන්නේ මොකක්ද
- stable සහ canary versions එකවර run කරන්නේ ඇයි
- Gateway API HTTPRoute weights traffic distribution control කරන්නේ කොහොමද
- canary rollout එකකදී Argo CD කරන වැඩේ මොකක්ද
- browser එකෙන් canary traffic visually observe කරන්නේ කොහොමද
- canary traffic promote කරන්නේ කොහොමද
- stable traffic වලට rollback කරන්නේ කොහොමද

## Architecture

මෙම lab එක repositories දෙකක් use කරනවා.

Platform සහ lab repository:

    terraform-azure-aks

මෙම repository එකේ තියෙන්නේ:

    labs/professional/05-canary-deployment/argocd/application.yaml
    labs/professional/05-canary-deployment/README.md
    labs/professional/05-canary-deployment/README.si.md

Sample application GitOps repository:

    aks-gitops-sample-app

Sample repository එකේ desired state තියෙන්නේ:

    k8s/canary

Canary desired state එකේ files:

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

HTTPRoute එකේ routes දෙකක් තියෙනවා:

    /canary-viewer -> canary-viewer service
    /              -> weighted stable/canary backends

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

ඔයාගේ sample repository URL එක set කරන්න:

    REPO_URL="https://github.com/<your-user-or-org>/aks-gitops-sample-app.git"

Platform repository directory set කරන්න:

    PLATFORM_REPO_DIR="<local-path>/terraform-azure-aks"

Sample repository directory set කරන්න:

    SAMPLE_REPO_DIR="<local-path>/aks-gitops-sample-app"

Gateway IP set කරන්න:

    GATEWAY_IP="<your-gateway-external-ip>"

Example:

    GATEWAY_IP="<gateway-public-ip>"

Verify කරන්න:

    echo "$REPO_URL"
    echo "$PLATFORM_REPO_DIR"
    echo "$SAMPLE_REPO_DIR"
    echo "$GATEWAY_IP"

## Verify canary desired state

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Files check කරන්න:

    find k8s/canary -maxdepth 2 -type f | sort

Route weights check කරන්න:

    grep -nE 'name: canary-stable|name: canary-v2|weight:|value:' \
      k8s/canary/httproute.yaml

Recommended starter state එක:

    canary-stable weight: 90
    canary-v2 weight: 10

Visual viewer configuration check කරන්න:

    grep -RInE 'canary-viewer|canary-viewer-content|mountPath|replacePrefixMatch' \
      k8s/canary

Important expected detail:

    canary-viewer content /usr/share/nginx/html/index.html වෙත mount වෙලා තියෙන්න ඕන

මෙය අවශ්‍යයි මොකද viewer service එක nginx root එකෙන් serve කරන නිසා.

## Deploy with Argo CD

මෙය platform repository එකෙන් run කරන්න:

    cd "$PLATFORM_REPO_DIR"

Argo CD Application apply කරන්න:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/05-canary-deployment/argocd/application.yaml \
      | kubectl apply -f -

Refresh කරන්න:

    kubectl annotate application canary-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify කරන්න:

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

Open කරන්න:

    http://<gateway-ip>/canary-viewer/

Example:

    http://<gateway-public-ip>/canary-viewer/

Viewer එක active Gateway route එකට repeated requests යවලා backend response count කරනවා.

Use කරන්න:

    Run 50 requests

Viewer එකෙන් පෙන්වන්නේ:

- total requests
- stable response count සහ percentage
- canary response count සහ percentage
- last response

## Stage 1 - 90/10 canary

මෙම stage එකේ traffic බහුතරය stable වෙත යනවා. පොඩි traffic ප්‍රමාණයක් canary වෙත යනවා.

Expected weights:

    canary-stable weight: 90
    canary-v2 weight: 10

Verify කරන්න:

    kubectl describe httproute canary-demo -n canary-demo | grep -E 'Name:|Weight:|Value:' -A1

Viewer open කරන්න:

    http://<gateway-ip>/canary-viewer/

Click කරන්න:

    Run 50 requests

Expected result:

    responses බහුතරය stable
    responses කිහිපයක් canary

Tested example result:

    Stable responses: 43 (86%)
    Canary responses: 7 (14%)

Weighted routing approximate. Requests 50ක් වගේ small run එකක් exact 90/10 නොවෙන්න පුළුවන්.

## Stage 2 - Increase canary to 50/50

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

HTTPRoute weights update කරන්න:

    python3 -c 'from pathlib import Path; p=Path("k8s/canary/httproute.yaml"); text=p.read_text(); text=text.replace("weight: 90", "weight: 50"); text=text.replace("weight: 10", "weight: 50"); p.write_text(text)'

Verify කරන්න:

    grep -nE 'name: canary-stable|name: canary-v2|weight:' \
      k8s/canary/httproute.yaml

Commit සහ push කරන්න:

    git add k8s/canary/httproute.yaml
    git commit -m "Increase canary demo traffic to fifty percent"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application canary-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify කරන්න:

    kubectl describe httproute canary-demo -n canary-demo | grep -E 'Name:|Weight:|Value:' -A1

Viewer එක නැවත open කරලා click කරන්න:

    Run 50 requests

Expected result:

    stable සහ canary responses close වෙන්න ඕන

Tested example result:

    Stable responses: 21 (42%)
    Canary responses: 29 (58%)

CLI test එකකදී මෙහෙමත් ලැබුණා:

    25 Track: stable
    25 Track: canary

## Stage 3 - Promote canary to 100%

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

`k8s/canary/httproute.yaml` වල stable 0 සහ canary 100 කරන්න:

    canary-stable weight: 0
    canary-v2 weight: 100

Commit සහ push කරන්න:

    git add k8s/canary/httproute.yaml
    git commit -m "Promote canary demo traffic to version two"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application canary-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Viewer open කරලා click කරන්න:

    Run 50 requests

Expected result:

    Stable responses: 0
    Canary responses: 50

CLI tested result:

    30 Track: canary

## Stage 4 - Roll back to stable

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

`k8s/canary/httproute.yaml` වල stable 100 සහ canary 0 කරන්න:

    canary-stable weight: 100
    canary-v2 weight: 0

Commit සහ push කරන්න:

    git add k8s/canary/httproute.yaml
    git commit -m "Rollback canary demo traffic to stable"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application canary-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Viewer open කරලා click කරන්න:

    Run 50 requests

Expected result:

    Stable responses: 50
    Canary responses: 0

CLI tested result:

    30 Track: stable

## Reset starter state

Final lab state commit කරන්න කලින් route එක recommended starter state එකට reset කරන්න:

    canary-stable weight: 90
    canary-v2 weight: 10

Verify කරන්න:

    grep -nE 'name: canary-stable|name: canary-v2|weight:' \
      k8s/canary/httproute.yaml

අවශ්‍ය නම් commit සහ push කරන්න:

    git add k8s/canary/httproute.yaml
    git commit -m "Reset canary demo starter traffic split"
    git push

## Troubleshooting

### Browser shows default nginx instead of the viewer

Viewer deployment mount check කරන්න:

    kubectl describe deployment canary-viewer -n canary-demo | grep -A20 -E 'Mounts|Volumes'

Viewer ConfigMap එක mount වෙලා තියෙන්න ඕන:

    /usr/share/nginx/html/index.html

Pod එක ඇතුළේ check කරන්න:

    POD=$(kubectl get pod -n canary-demo -l app=canary-viewer -o jsonpath='{.items[0].metadata.name}')
    kubectl exec -n canary-demo "$POD" -- cat /usr/share/nginx/html/index.html | grep 'Canary Traffic Viewer'

### Gateway returns 404 for a path

Backend nginx app එක `/` serve කරනවා.

Weighted app route එක use කරන්න ඕන:

    value: /

`/canary` වගේ path එකක් rewrite නැතුව use කළොත් nginx ට `/canary` ලැබෙන නිසා 404 return වෙන්න පුළුවන්.

### Viewer route does not work

HTTPRoute check කරන්න:

    kubectl describe httproute canary-demo -n canary-demo

Viewer rule එක මෙහෙම තිබිය යුතුයි:

    value: /canary-viewer
    URLRewrite ReplacePrefixMatch /

### Argo CD shows Unknown

Application describe කරන්න:

    kubectl describe application canary-demo -n argocd

Common causes:

- YAML syntax error
- kustomize build error
- repo changes push නොවීම
- invalid HTTPRoute field

## Cleanup

Argo CD Application delete කරන්න:

    kubectl delete application canary-demo -n argocd --ignore-not-found

Namespace delete කරන්න:

    kubectl delete namespace canary-demo --ignore-not-found

Verify කරන්න:

    kubectl get applications -n argocd
    kubectl get ns canary-demo 2>/dev/null || echo "canary-demo namespace removed"
    kubectl get httproute -A

## What you completed

ඔයා complete කළා:

- stable සහ canary deployments side by side run කිරීම
- HTTPRoute weighted traffic routing
- Argo CD managed canary rollout
- browser-based traffic visualizer
- 90/10 canary test
- 50/50 canary test
- 100% canary promotion
- rollback to stable
- cleanup path

මෙය next lab එකට prepare කරනවා:

    Professional Lab 06 - Incident Troubleshooting
