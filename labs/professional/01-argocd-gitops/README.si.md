# Professional Lab 01 - Argo CD GitOps

මෙම lab එකෙන් AKS මත Argo CD install කරලා Git වලින් Kubernetes application එකක් deploy කරන GitOps workflow එක ඉගෙන ගන්නවා.

Argo CD Git repository එක watch කරලා, Git වල තියෙන desired state එකට cluster එක reconcile කරනවා.

Flow එක:

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

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- GitOps practical විදියට අදහස් වෙන්නේ මොකක්ද
- AKS මත Argo CD install කරන විදිය
- Argo CD UI locally access කරන විදිය
- Initial Argo CD admin password ගන්න විදිය
- Kubernetes application එකක් Git වල define කරන විදිය
- Argo CD Application එකක් create කරන විදිය
- Argo CD Git වලින් manifests AKS වෙත sync කරන විදිය
- Automated sync සහ self-heal වැඩ කරන විදිය
- Argo CD සහ demo app resources clean up කරන විදිය

## Architecture

මෙම lab එක repositories දෙකක් use කරනවා:

    terraform-azure-aks
      Learning platform සහ lab guide repository එක

    aks-gitops-sample-app
      Argo CD use කරන sample application repository එක

Argo CD AKS cluster එක ඇතුළේ run වෙනවා. ඒ නිසා ඔයාගේ laptop එකේ files direct read කරන්න බැහැ.

මෙම lab එකේදී Argo CD Kubernetes manifests read කරන්නේ sample app repository එකෙන්:

    https://github.com/andrewferdinandus/aks-gitops-sample-app.git

Path එක:

    k8s/overlays/dev

Flow එක:

    aks-gitops-sample-app
      |
      v
    Argo CD
      |
      v
    AKS namespace: gitops-sample-dev
      |
      v
    dev-gitops-sample-app

මෙම lab එකට learnersලා GitHub එකට කිසිම දෙයක් push කරන්න අවශ්‍ය නැහැ. Argo CD public sample repository එකෙන් sample app manifests read කරනවා විතරයි.


## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- Azure CLI
- kubectl
- Existing AKS cluster
- AKS cluster access
- මෙම lab එක committed සහ pushed කරපු public GitHub repo එක
- Local Argo CD port-forward URL එක browser එකෙන් access කරන්න හැකියාව

Kubernetes access check කරන්න:

    kubectl get nodes

Current context check කරන්න:

    kubectl config current-context

## Lab files

මෙම lab එකේ files:

    manifests/
      Demo app සහ Argo CD Application සඳහා Kubernetes manifests

    scripts/
      Optional helper scripts පසුව add කරන්න පුළුවන්

Files:

    manifests/namespace.yaml
    manifests/app.yaml
    manifests/argocd-application.yaml

## Set lab variables

ඔයාගේ environment එකට values set කරන්න:

    ARGOCD_NAMESPACE="argocd"
    APP_NAMESPACE="gitops-sample-dev"
    REPO_URL="https://github.com/andrewferdinandus/aks-gitops-sample-app.git"
    APP_PATH="k8s/overlays/dev"

## Install Argo CD

Argo CD namespace එක create කරන්න:

    kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

Official install manifest එක use කරලා Argo CD install කරන්න:

    kubectl apply -n "$ARGOCD_NAMESPACE" \
      --server-side \
      --force-conflicts \
      -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Argo CD components ready වෙනකම් wait කරන්න:

    kubectl rollout status deployment/argocd-server -n "$ARGOCD_NAMESPACE"
    kubectl rollout status deployment/argocd-repo-server -n "$ARGOCD_NAMESPACE"
    kubectl rollout status deployment/argocd-applicationset-controller -n "$ARGOCD_NAMESPACE"
    kubectl rollout status statefulset/argocd-application-controller -n "$ARGOCD_NAMESPACE"

Verify කරන්න:

    kubectl get pods -n "$ARGOCD_NAMESPACE"
    kubectl get svc -n "$ARGOCD_NAMESPACE"

## Access Argo CD locally

Initial admin password එක ගන්න:

    kubectl get secret argocd-initial-admin-secret \
      -n "$ARGOCD_NAMESPACE" \
      -o jsonpath="{.data.password}" | base64 --decode; echo

Argo CD server එක port-forward කරන්න:

    kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" 8080:443

Argo CD open කරන්න:

    https://localhost:8080

Login:

    Username: admin
    Password: secret command එකෙන් ගත්ත password එක use කරන්න

මෙම local lab එකේ browser certificate warning එකක් එන එක normal.

Port-forward stop කරන්න:

    Ctrl+C

## Review the demo app manifests

Demo app namespace එක define කරලා තියෙන්නේ:

    manifests/namespace.yaml

Demo workload එක define කරලා තියෙන්නේ:

    manifests/app.yaml

Demo workload එක deploy කරන්නේ:

- NGINX Deployment
- ClusterIP Service
- professional-gitops-demo namespace

Main lab flow එකේදී demo app manifests manually apply කරන්න එපා. Argo CD Git වලින් ඒවා apply කරන්න ඕන.

## Review the Argo CD Application

Argo CD Application එක define කරලා තියෙන්නේ:

    manifests/argocd-application.yaml

ඒක වෙනම sample application repository එකට point කරනවා:

    repoURL: https://github.com/andrewferdinandus/aks-gitops-sample-app.git
    targetRevision: main
    path: k8s/overlays/dev

Destination namespace එක:

    gitops-sample-dev

මේකෙන් learning platform repository එක සහ sample application repository එක වෙන වෙනම තියාගන්නවා.


## Create the Argo CD Application

Argo CD Application එක apply කරන්න:

    kubectl apply -f labs/professional/01-argocd-gitops/manifests/argocd-application.yaml

Application resource එක verify කරන්න:

    kubectl get applications -n "$ARGOCD_NAMESPACE"

Sample app namespace එක check කරන්න:

    kubectl get ns "$APP_NAMESPACE"

Sample app workload එක check කරන්න:

    kubectl get pods -n "$APP_NAMESPACE"
    kubectl get svc -n "$APP_NAMESPACE"

Expected result:

    professional-gitops-demo   Synced   Healthy
    dev-gitops-sample-app pods Running
    dev-gitops-sample-app service created


## Verify in the Argo CD UI

අවශ්‍ය නම් Argo CD නැවත port-forward කරන්න:

    kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" 8080:443

Open කරන්න:

    https://localhost:8080

ඔයාට මෙය පේන්න ඕන:

    professional-gitops-demo

Application එක මෙහෙම වෙන්න ඕන:

    Synced
    Healthy

OutOfSync නම්, Sync click කරන්න හෝ automated sync වෙනකම් wait කරන්න.

## Test self-heal

Deployment එක manually scale කරන්න:

    kubectl scale deployment dev-gitops-sample-app -n "$APP_NAMESPACE" --replicas=1

Pods check කරන්න:

    kubectl get pods -n "$APP_NAMESPACE"

Self-heal enabled නිසා Argo CD deployment එක Git desired state එකට නැවත reconcile කරන්න ඕන:

    replicas: 2

නැවත verify කරන්න:

    kubectl get deployment dev-gitops-sample-app -n "$APP_NAMESPACE"

## Understand GitOps changes

Argo CD watch කරන්නේ මෙතන configure කරලා තියෙන Git source එක:

    manifests/argocd-application.yaml

මෙම lab එකේ source එක:

    https://github.com/andrewferdinandus/aks-gitops-sample-app.git

ඔයාගේ laptop එකේ local file edits practice සඳහා useful. හැබැයි ඒ edits configured Git source එකෙන් available නැත්නම් Argo CD ඒවා දකින්නේ නැහැ.

මෙම lab එකේ reconciliation concept එක තේරුම් ගන්න කිසිම changes push නොකර ඉහත self-heal test එක use කරන්න.

වැදගත් concept එක:

    Git desired state
      |
      v
    Argo CD reconciliation
      |
      v
    Kubernetes cluster state


## Troubleshooting

Argo CD pods check කරන්න:

    kubectl get pods -n "$ARGOCD_NAMESPACE"

Argo CD Application එක check කරන්න:

    kubectl describe application professional-gitops-demo -n "$ARGOCD_NAMESPACE"

App resources check කරන්න:

    kubectl get all -n "$APP_NAMESPACE"

Argo CD server logs check කරන්න:

    kubectl logs deployment/argocd-server -n "$ARGOCD_NAMESPACE" --tail=100

Repo server logs check කරන්න:

    kubectl logs deployment/argocd-repo-server -n "$ARGOCD_NAMESPACE" --tail=100

App sync නොවුණොත් මේවා check කරන්න:

- Repo URL
- Branch name
- Manifest path
- Public repo access
- Application destination namespace
- ServiceAccount/RBAC permissions

## Cleanup

Argo CD Application එක delete කරන්න:

    kubectl delete application professional-gitops-demo -n "$ARGOCD_NAMESPACE" --ignore-not-found

Demo namespace එක delete කරන්න:

    kubectl delete namespace "$APP_NAMESPACE" --ignore-not-found

Argo CD delete කරන්න:

    kubectl delete namespace "$ARGOCD_NAMESPACE" --ignore-not-found

මෙයින් Argo CD සහ demo application එක remove වෙනවා.

මෙයින් remove වෙන්නේ නැහැ:

- AKS cluster
- Monitoring stack
- Key Vault
- ACR
- වෙනත් lab resources

Flux GitOps lab එකට ඉක්මනින් continue කරනවා නම්, tool overlap avoid කරන්න Argo CD clean up කරන්න පුළුවන්.

## What you completed

ඔයා complete කළා:

- AKS මත Argo CD installation
- Argo CD UI access
- GitOps application definition
- Git-based application sync
- Self-heal test
- GitOps change test
- Cleanup path

මෙය next lab එකට prepare කරනවා:

    Professional Lab 02 - Flux GitOps
