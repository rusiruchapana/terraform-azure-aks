# Professional Lab 04 - Blue/Green Deployment

මෙම lab එකෙන් application එකක blue සහ green versions එකවර run කරලා, active user traffic එක blue සිට green වෙත switch කරලා, අවශ්‍ය නම් green සිට blue වෙත rollback කරන ආකාරය Argo CD සහ GitOps use කරලා ඉගෙන ගන්නවා.

මෙය professional release strategy lab එකක්.

Goal එක commands run කිරීම විතරක් නෙවෙයි. Goal එක එක් එක් component එක කරන වැඩේ තේරුම් ගැනීමයි:

- Git desired state තබාගන්නවා
- Argo CD Git watch කරලා cluster එක reconcile කරනවා
- Kubernetes Deployments blue සහ green versions run කරනවා
- Kubernetes Services traffic route කරනවා
- Browser එකෙන් users දකින version එක verify කරනවා

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- Stable app version එක ලෙස blue version එක running
- New candidate version එක ලෙස green version එක running
- User traffic blue හෝ green වෙත යවන active Service එකක්
- Blue version එක හැමවිටම පෙන්වන blue preview Service එකක්
- Green version එක හැමවිටම පෙන්වන green preview Service එකක්
- Git වලින් blue/green desired state manage කරන Argo CD Application එකක්
- Blue සිට green වෙත tested switch එකක්
- Green සිට blue වෙත tested rollback එකක්
- Argo CD self-heal/drift correction test එකක්

## What you will learn

මෙම lab එකෙන් ඔබට මේවා ඉගෙන ගන්න පුළුවන්:

- Blue/green deployment කියන්නේ මොකක්ද
- Blue සහ green එකවර run කරන්නේ ඇයි
- Traffic switch කරන්න කලින් preview Services වලින් versions දෙක validate කරන්නේ කොහොමද
- Kubernetes Service selector එක active traffic control කරන්නේ කොහොමද
- GitOps release switch එකකදී Argo CD කරන වැඩේ මොකක්ද
- Real switch එක direct kubectl patch එකකින් නොකර Git හරහා කරන්න ඕන ඇයි
- Browser එකෙන් active release එක verify කරන්නේ කොහොමද
- ඉක්මනට rollback කරන්නේ කොහොමද
- Manual drift එක Argo CD self-heal කරන්නේ කොහොමද

## Architecture

මෙම lab එක repositories දෙකක් use කරනවා.

Platform සහ lab repository:

    terraform-azure-aks

මෙම repository එකේ තියෙන්නේ:

    labs/professional/04-blue-green-deployment/README.md
    labs/professional/04-blue-green-deployment/README.si.md
    labs/professional/04-blue-green-deployment/argocd/application.yaml

Sample application GitOps repository:

    aks-gitops-sample-app

Sample repository එකේ application desired state තියෙන්නේ:

    k8s/blue-green

Desired state එකේ files:

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

Blue කියන්නේ current stable version එක:

    bluegreen-blue
    version: blue
    page: blue v1

Green කියන්නේ new candidate version එක:

    bluegreen-green
    version: green
    page: green v2

Active Service එක user-facing service එකයි:

    bluegreen-demo

ආරම්භයේදී active Service එක blue වෙත point කරනවා:

    selector:
      app: bluegreen-demo
      version: blue

Release switch එකෙන් පස්සේ active Service එක green වෙත point කරනවා:

    selector:
      app: bluegreen-demo
      version: green

Rollback එක active Service එක නැවත blue වෙත switch කරනවා.

## Why preview Services exist

මෙම lab එක Services තුනක් use කරනවා:

    bluegreen-demo
    bluegreen-blue-preview
    bluegreen-green-preview

Active Service එක user traffic represent කරනවා:

    bluegreen-demo

Blue preview Service එක හැමවිටම blue වෙත point කරනවා:

    bluegreen-blue-preview

Green preview Service එක හැමවිටම green වෙත point කරනවා:

    bluegreen-green-preview

මෙයින් browser experience එක clear වෙනවා:

    Active app     -> users දැන් දකින version එක
    Blue preview   -> stable blue version එක
    Green preview  -> candidate green version එක

Switch කරන්න කලින්:

    Active app     -> blue v1
    Blue preview   -> blue v1
    Green preview  -> green v2

Green වෙත switch කළ පසු:

    Active app     -> green v2
    Blue preview   -> blue v1
    Green preview  -> green v2

Rollback කළ පසු:

    Active app     -> blue v1
    Blue preview   -> blue v1
    Green preview  -> green v2

## What Argo CD does in this lab

Argo CD sample GitOps repository එක watch කරනවා.

ඔයා Git වල මේ file එක වෙනස් කළාම:

    k8s/blue-green/service-active.yaml

Argo CD ඒ Git change එක detect කරලා cluster එකේ Kubernetes Service එක update කරනවා.

Release switch flow එක:

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

Real release switch එකට `kubectl patch` use කරන්න එපා.

Real blue/green switch එක Git හරහා කරන්න.

`kubectl patch` use කරන්නේ පසුව Argo CD self-heal test එකට විතරයි.

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- kubectl
- Git
- Existing AKS cluster access
- Existing Argo CD installation
- Argo CD UI access
- Sample app repository එකේ fork එකක්

මෙම lab එකට අවශ්‍ය නැහැ:

- Docker Desktop
- Azure Container Registry
- CI/CD pipeline
- Flux

## Check local tools and AKS access

AKS access verify කරන්න:

    kubectl get nodes

Current context check කරන්න:

    kubectl config current-context

Argo CD namespace verify කරන්න:

    kubectl get ns argocd

Argo CD pods verify කරන්න:

    kubectl get pods -n argocd

Argo CD Application CRD verify කරන්න:

    kubectl get crd applications.argoproj.io

## Fork and clone the sample app repository

මෙම lab එක මෙම sample application GitOps repository එක use කරනවා:

    https://github.com/andrewferdinandus/aks-gitops-sample-app

මෙම repository එක ඔයාගේ GitHub account එකට හෝ organization එකට fork කරන්න.

Example fork URL:

    https://github.com/<your-user-or-org>/aks-gitops-sample-app.git

ඔයාගේ fork එක clone කරන්න:

    cd /Users/andrewferdinandus/projcts
    git clone https://github.com/<your-user-or-org>/aks-gitops-sample-app.git
    cd aks-gitops-sample-app

Sample repository directory set කරන්න:

    SAMPLE_REPO_DIR="$(pwd)"

Verify කරන්න:

    echo "$SAMPLE_REPO_DIR"

ඔයාගේ sample repository URL එක set කරන්න:

    REPO_URL="https://github.com/<your-user-or-org>/aks-gitops-sample-app.git"

Verify කරන්න:

    echo "$REPO_URL"

Platform repository directory set කරන්න:

    PLATFORM_REPO_DIR="/Users/andrewferdinandus/projcts/terraform-azure-aks"

Verify කරන්න:

    echo "$PLATFORM_REPO_DIR"

## Verify blue/green desired state

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Files check කරන්න:

    find k8s/blue-green -maxdepth 2 -type f | sort

Active Service selector check කරන්න:

    grep -nE 'selector:|app: bluegreen-demo|version:' \
      k8s/blue-green/service-active.yaml

Expected starter state:

    version: blue

Important blue/green values check කරන්න:

    grep -RInE 'bluegreen-demo|bluegreen-blue-preview|bluegreen-green-preview|version: blue|version: green|Active color|Version:' \
      k8s/blue-green

Expected:

- blue content එකේ `Active color: blue` සහ `Version: v1`
- green content එකේ `Active color: green` සහ `Version: v2`
- active Service එක `version: blue` වලින් start වෙනවා
- blue preview Service එක `version: blue` use කරනවා
- green preview Service එක `version: green` use කරනවා

Git status check කරන්න:

    git status --short

Sample repository එකේ files change/add කරලා තියෙනවා නම් commit සහ push කරන්න:

    git add k8s/blue-green
    git commit -m "Add blue green deployment demo desired state"
    git push

## Create the Argo CD Application

මෙය platform repository එකෙන් run කරන්න:

    cd "$PLATFORM_REPO_DIR"

Argo CD Application apply කරන්න:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/04-blue-green-deployment/argocd/application.yaml \
      | kubectl apply -f -

Verify කරන්න:

    kubectl get applications -n argocd

Expected:

    bluegreen-demo   Synced   Healthy

## Verify Kubernetes resources

Namespace check කරන්න:

    kubectl get ns bluegreen-demo

Pods සහ labels check කරන්න:

    kubectl get pods -n bluegreen-demo --show-labels

Expected:

- blue pods වල `version=blue`
- green pods වල `version=green`

Services check කරන්න:

    kubectl get svc -n bluegreen-demo

Expected Services:

    bluegreen-demo
    bluegreen-blue-preview
    bluegreen-green-preview

Active Service selector check කරන්න:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

Expected:

    selector:
      app: bluegreen-demo
      version: blue

## Access Argo CD UI

Argo CD port-forward කරන්න:

    kubectl port-forward svc/argocd-server -n argocd 8080:443

Open කරන්න:

    https://localhost:8080

Username:

    admin

Initial admin password අවශ්‍ය නම් ගන්න:

    kubectl -n argocd get secret argocd-initial-admin-secret \
      -o jsonpath="{.data.password}" | base64 -d
    echo

UI එකේ open කරන්න:

    bluegreen-demo

Observe කරන්න:

- Application status
- Kubernetes resources
- Service resource
- Blue Deployment
- Green Deployment

Argo CD UI එකෙන් GitOps manage කරන resources දකින්න පුළුවන්.

## Open the active and preview apps

Port-forward සඳහා separate terminals තුනක් open කරන්න.

Active app:

    kubectl port-forward svc/bluegreen-demo -n bluegreen-demo 8084:80

Blue preview:

    kubectl port-forward svc/bluegreen-blue-preview -n bluegreen-demo 8085:80

Green preview:

    kubectl port-forward svc/bluegreen-green-preview -n bluegreen-demo 8086:80

මෙම URLs open කරන්න:

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

මෙයින් green already deployed සහ previewable කියලා prove වෙනවා. හැබැයි active user traffic තවම blue වෙත යනවා.

## Switch active traffic to green

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Active Service selector blue සිට green වෙත change කරන්න:

    python3 -c 'from pathlib import Path; p=Path("k8s/blue-green/service-active.yaml"); text=p.read_text(); p.write_text(text.replace("version: blue", "version: green"))'

Verify කරන්න:

    grep -nE 'selector:|app: bluegreen-demo|version:' \
      k8s/blue-green/service-active.yaml

Commit සහ push කරන්න:

    git add k8s/blue-green/service-active.yaml
    git commit -m "Switch blue green active traffic to green"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application bluegreen-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Argo CD verify කරන්න:

    kubectl get applications -n argocd

Active Service selector verify කරන්න:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

Expected:

    selector:
      app: bluegreen-demo
      version: green

Active port-forward restart කරන්න.

`8084` port-forward එක `Ctrl+C` වලින් stop කරලා නැවත start කරන්න:

    kubectl port-forward svc/bluegreen-demo -n bluegreen-demo 8084:80

Browser හෝ curl නැවත verify කරන්න:

    curl -s http://localhost:8084 | grep -E 'Active color|Version'
    curl -s http://localhost:8085 | grep -E 'Active color|Version'
    curl -s http://localhost:8086 | grep -E 'Active color|Version'

Expected after switch:

    8084 active        -> green v2
    8085 blue preview  -> blue v1
    8086 green preview -> green v2

## Important port-forward note

Service selector change කළ පසු active port-forward restart කරන්න.

`kubectl port-forward svc/...` command එක port-forward session එක start කළ වෙලාවේ selected pod එකට දිගටම forward වෙන්න පුළුවන්.

Cluster එකේ real source of truth එක Service selector එකයි.

Production වල user traffic සාමාන්‍යයෙන් local port-forwarding වෙනුවට Gateway, Ingress, LoadBalancer, හෝ service mesh හරහා යනවා.

## Roll back active traffic to blue

මෙය sample repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Active Service selector green සිට blue වෙත ආපසු change කරන්න:

    python3 -c 'from pathlib import Path; p=Path("k8s/blue-green/service-active.yaml"); text=p.read_text(); p.write_text(text.replace("version: green", "version: blue"))'

Verify කරන්න:

    grep -nE 'selector:|app: bluegreen-demo|version:' \
      k8s/blue-green/service-active.yaml

Commit සහ push කරන්න:

    git add k8s/blue-green/service-active.yaml
    git commit -m "Rollback blue green active traffic to blue"
    git push

Argo CD refresh කරන්න:

    kubectl annotate application bluegreen-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Active Service selector verify කරන්න:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

Expected:

    selector:
      app: bluegreen-demo
      version: blue

Active port-forward restart කරන්න:

    kubectl port-forward svc/bluegreen-demo -n bluegreen-demo 8084:80

Verify කරන්න:

    curl -s http://localhost:8084 | grep -E 'Active color|Version'
    curl -s http://localhost:8085 | grep -E 'Active color|Version'
    curl -s http://localhost:8086 | grep -E 'Active color|Version'

Expected after rollback:

    8084 active        -> blue v1
    8085 blue preview  -> blue v1
    8086 green preview -> green v2

මෙයින් blue version එක remove නොකළ නිසා rollback එක ඉක්මන් බව prove වෙනවා.

## Test Argo CD self-heal

Desired active state එක දැන් blue.

Cluster Service එක manually green කරන්න:

    kubectl patch svc bluegreen-demo -n bluegreen-demo \
      --type merge \
      -p '{"spec":{"selector":{"app":"bluegreen-demo","version":"green"}}}'

Temporary drift එක check කරන්න:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

තත්පර 30 සිට 60 දක්වා wait කරන්න.

නැවත check කරන්න:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector
    kubectl get applications -n argocd

Expected:

    selector:
      app: bluegreen-demo
      version: blue

    bluegreen-demo   Synced   Healthy

මෙයින් Argo CD manual drift correct කරලා Git desired state එක restore කළා කියලා prove වෙනවා.

## Troubleshooting

### Application is OutOfSync

Application refresh කරන්න:

    kubectl annotate application bluegreen-demo -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

නැත්නම් Argo CD UI එකෙන්:

    Application -> SYNC -> SYNCHRONIZE

### Active app still shows the old color

Port `8084` active port-forward restart කරන්න.

ඉන්පසු browser refresh කරන්න හෝ curl use කරන්න:

    curl -s http://localhost:8084 | grep -E 'Active color|Version'

### Service selector is not changing

Git වල active Service check කරන්න:

    grep -nE 'selector:|app: bluegreen-demo|version:' \
      k8s/blue-green/service-active.yaml

Change එක commit/push වෙලාද check කරන්න:

    git status --short
    git log --oneline -3

Cluster Service check කරන්න:

    kubectl get svc bluegreen-demo -n bluegreen-demo -o yaml | grep -A5 selector

### Argo CD cannot find the repo path

Application path check කරන්න:

    k8s/blue-green

Sample repository එකේ ඒ folder එක තියෙනවද සහ changes push වෙලාද verify කරන්න.

## Cleanup

Argo CD Application delete කරන්න:

    kubectl delete application bluegreen-demo -n argocd --ignore-not-found

Namespace delete කරන්න:

    kubectl delete namespace bluegreen-demo --ignore-not-found

Verify කරන්න:

    kubectl get applications -n argocd
    kubectl get ns bluegreen-demo 2>/dev/null || echo "bluegreen-demo namespace removed"

සියලුම port-forward terminals `Ctrl+C` වලින් stop කරන්න.

මෙම cleanup එක Argo CD remove කරන්නේ නැහැ.

## What you completed

ඔයා complete කළා:

- Blue සහ green versions side by side running කිරීම
- Active Service blue වෙත route කිරීම
- Blue preview Service
- Green preview Service
- Git-based blue to green switch
- Argo CD reconciliation
- Browser එකෙන් active version verify කිරීම
- Git-based rollback to blue
- Argo CD self-heal test
- Cleanup path

මෙය next lab එකට prepare කරනවා:

    Professional Lab 05 - Canary Deployment

## Important note

මෙම lab එක Kubernetes Service selector එකක් use කරලා blue/green concept එක clear විදියට teach කරනවා.

Production වල blue/green මේවාවලින්ත් implement කරන්න පුළුවන්:

- Gateway API route switching
- Ingress switching
- LoadBalancer switching
- Service mesh traffic routing
- Progressive delivery tools

Key idea එක එකමයි:

    Old version එක running තබාගන්න.
    New version එක side by side deploy කරන්න.
    New version එක preview කරන්න.
    Active traffic intentionally switch කරන්න.
    අවශ්‍ය නම් ඉක්මනට rollback කරන්න.
