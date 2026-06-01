# Professional Lab 02 - Flux GitOps

මෙම lab එකෙන් AKS මත Flux install කරලා Git වලින් Kubernetes application එකක් deploy කරන GitOps workflow එක ඉගෙන ගන්නවා.

Flux Git repository එක watch කරලා, Git වල තියෙන desired state එකට cluster එක reconcile කරනවා.

මෙය standalone professional GitOps lab එකක්.

Flow එක:

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

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `flux-system` namespace එකේ Flux installed වීම
- `professional-gitops-demo` කියන Flux GitRepository එකක්
- `professional-gitops-demo` කියන Flux Kustomization එකක්
- Public Git repository එකකින් synced demo app එකක්
- `gitops-sample-dev` namespace එකේ running demo app එකක්
- Flux reconciliation tested වීම
- Basic drift correction tested වීම

මෙම lab එක public sample app repository එකක් use කරන නිසා learnersලා GitHub එකට changes push කරන්න අවශ්‍ය නැහැ.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- GitOps workflow එකක Flux කරන දේ
- Flux direct `kubectl apply` වලින් වෙනස් වෙන්නේ කොහොමද
- AKS මත Flux install කරන විදිය
- Flux GitRepository source එකක් create කරන විදිය
- Flux Kustomization එකක් create කරන විදිය
- Flux Git වලින් manifests AKS වෙත sync කරන විදිය
- Flux reconciliation වැඩ කරන විදිය
- Flux status inspect කරන විදිය
- Drift correction test කරන විදිය
- Flux සහ demo app resources clean up කරන විදිය

## Architecture

මෙම lab එක repositories දෙකක් use කරනවා:

    terraform-azure-aks
      Learning platform සහ lab guide repository එක

    aks-gitops-sample-app
      Flux use කරන sample application repository එක

Flux AKS cluster එක ඇතුළේ run වෙනවා.

Flux Kubernetes manifests read කරන්නේ sample app repository එකෙන්:

    https://github.com/andrewferdinandus/aks-gitops-sample-app.git

Path එක:

    k8s/overlays/dev

Flow එක:

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

මෙම lab එකට learnersලා GitHub එකට කිසිම දෙයක් push කරන්න අවශ්‍ය නැහැ.

Flux public sample repository එකෙන් sample app manifests read කරනවා විතරයි.

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- kubectl
- Flux CLI
- Existing AKS cluster
- AKS cluster access
- Terminal එකක්
- Web browser එකක් optional
- Flux CLI install කරන්න laptop එකෙන් internet access
- Container images pull කරන්න cluster එකෙන් internet access
- Public sample Git repository එකට Flux access

මෙම lab එකට අවශ්‍ය නැහැ:

- Docker Desktop
- Azure Container Registry
- CI/CD platform
- GitHub එකට changes push කිරීම
- Argo CD

## Install required local tools

### kubectl

kubectl install කරන්න:

    https://kubernetes.io/docs/tasks/tools/

kubectl verify කරන්න:

    kubectl version --client

### Flux CLI

Flux CLI install කරන්න:

    https://fluxcd.io/flux/installation/

Flux CLI verify කරන්න:

    flux --version

## Check local tools and AKS access

Continue කරන්න කලින් kubectl ට AKS cluster එකට connect වෙන්න පුළුවන්ද verify කරන්න:

    kubectl get nodes

Current context check කරන්න:

    kubectl config current-context

Flux prerequisites verify කරන්න:

    flux check --pre

Expected:

    Nodes Ready status එකෙන් පෙන්විය යුතුයි.
    Flux prerequisite check pass වෙන්න ඕන.

## Lab files

මෙම lab එකේ files:

    manifests/
      Demo app namespace එක සඳහා Kubernetes namespace manifest

    flux/
      Flux GitRepository සහ Kustomization resources

Files:

    manifests/namespace.yaml
    flux/gitrepository.yaml
    flux/kustomization.yaml

## Set lab variables

ඔයාගේ environment එකට values set කරන්න:

    FLUX_NAMESPACE="flux-system"
    APP_NAMESPACE="gitops-sample-dev"
    REPO_URL="https://github.com/andrewferdinandus/aks-gitops-sample-app.git"
    APP_PATH="./k8s/overlays/dev"

Verify කරන්න:

    echo "$FLUX_NAMESPACE"
    echo "$APP_NAMESPACE"
    echo "$REPO_URL"
    echo "$APP_PATH"

## Install Flux

Flux components cluster එකට install කරන්න:

    flux install

Flux pods verify කරන්න:

    kubectl get pods -n "$FLUX_NAMESPACE"

Flux status check කරන්න:

    flux check

Expected:

    Flux controllers Running වෙන්න ඕන.
    `flux check` pass වෙන්න ඕන.

## Create the demo app namespace

Flux demo app deploy කරන namespace එක create කරන්න:

    kubectl apply -f labs/professional/02-flux-gitops/manifests/namespace.yaml

Verify කරන්න:

    kubectl get namespace "$APP_NAMESPACE"

## Review the Flux GitRepository

GitRepository define කරලා තියෙන්නේ:

    flux/gitrepository.yaml

ඒක public sample application repository එකට point කරනවා:

    url: https://github.com/andrewferdinandus/aks-gitops-sample-app.git
    branch: main

GitRepository එක Flux ට desired state fetch කරන්න තියෙන තැන කියනවා.

## Review the Flux Kustomization

Kustomization define කරලා තියෙන්නේ:

    flux/kustomization.yaml

ඒක point කරන්නේ:

    path: ./k8s/overlays/dev

ඒක GitRepository source එක use කරනවා:

    professional-gitops-demo

ඒක deploy කරන්නේ:

    gitops-sample-dev

මේකෙන් learning platform repository එක සහ sample application repository එක වෙන වෙනම තියාගන්නවා.

## Create the Flux GitRepository

GitRepository apply කරන්න:

    kubectl apply -f labs/professional/02-flux-gitops/flux/gitrepository.yaml

Verify කරන්න:

    flux get sources git -n "$FLUX_NAMESPACE"

ඔයාට මෙය පේන්න ඕන:

    professional-gitops-demo

## Create the Flux Kustomization

Kustomization apply කරන්න:

    kubectl apply -f labs/professional/02-flux-gitops/flux/kustomization.yaml

Verify කරන්න:

    flux get kustomizations -n "$FLUX_NAMESPACE"

ඔයාට මෙය පේන්න ඕන:

    professional-gitops-demo

අවශ්‍ය නම් reconcile force කරන්න:

    flux reconcile source git professional-gitops-demo -n "$FLUX_NAMESPACE"
    flux reconcile kustomization professional-gitops-demo -n "$FLUX_NAMESPACE"

## Verify the synced app

App namespace එක check කරන්න:

    kubectl get ns "$APP_NAMESPACE"

App workload එක check කරන්න:

    kubectl get pods -n "$APP_NAMESPACE"
    kubectl get svc -n "$APP_NAMESPACE"
    kubectl get deployment -n "$APP_NAMESPACE"

Expected result:

    dev-gitops-sample-app pods Running
    dev-gitops-sample-app service created

Flux status check කරන්න:

    flux get sources git -n "$FLUX_NAMESPACE"
    flux get kustomizations -n "$FLUX_NAMESPACE"

Expected:

    GitRepository is Ready
    Kustomization is Ready

## Test reconciliation

Deployment එක manually scale කරන්න:

    kubectl scale deployment dev-gitops-sample-app -n "$APP_NAMESPACE" --replicas=1

Deployment එක check කරන්න:

    kubectl get deployment dev-gitops-sample-app -n "$APP_NAMESPACE"

Flux reconciliation force කරන්න:

    flux reconcile kustomization professional-gitops-demo -n "$FLUX_NAMESPACE"

නැවත verify කරන්න:

    kubectl get deployment dev-gitops-sample-app -n "$APP_NAMESPACE"

Flux deployment එක Git desired state එකට නැවත reconcile කරන්න ඕන.

## Understand GitOps changes

Flux watch කරන්නේ මෙතන configure කරලා තියෙන Git source එක:

    flux/gitrepository.yaml
    flux/kustomization.yaml

මෙම lab එකේ source එක:

    https://github.com/andrewferdinandus/aks-gitops-sample-app.git

ඔයාගේ laptop එකේ local file edits practice සඳහා useful. හැබැයි ඒ edits configured Git source එකෙන් available නැත්නම් Flux ඒවා දකින්නේ නැහැ.

මෙම lab එකේ GitHub changes push නොකර GitOps concept එක තේරුම් ගන්න reconciliation test එක use කරන්න.

වැදගත් concept එක:

    Git desired state
      |
      v
    Flux reconciliation
      |
      v
    Kubernetes cluster state

## Troubleshooting

### Flux controllers are not running

Flux pods check කරන්න:

    kubectl get pods -n "$FLUX_NAMESPACE"

Flux status check කරන්න:

    flux check

### GitRepository is not Ready

GitRepository status check කරන්න:

    flux get sources git -n "$FLUX_NAMESPACE"

GitRepository describe කරන්න:

    kubectl describe gitrepository professional-gitops-demo -n "$FLUX_NAMESPACE"

source-controller logs check කරන්න:

    kubectl logs deployment/source-controller -n "$FLUX_NAMESPACE" --tail=100

Common causes:

- Repo URL වැරදියි
- Branch name වැරදියි
- Cluster එකට GitHub reach කරන්න බැහැ
- Public repo access issue

### Kustomization is not Ready

Kustomization status check කරන්න:

    flux get kustomizations -n "$FLUX_NAMESPACE"

Kustomization describe කරන්න:

    kubectl describe kustomization professional-gitops-demo -n "$FLUX_NAMESPACE"

kustomize-controller logs check කරන්න:

    kubectl logs deployment/kustomize-controller -n "$FLUX_NAMESPACE" --tail=100

Common causes:

- Path වැරදියි
- Kustomize build fail වෙනවා
- Destination namespace missing
- RBAC issue
- Manifest validation issue

### App pods are not Running

App resources check කරන්න:

    kubectl get all -n "$APP_NAMESPACE"

Pod describe කරන්න:

    kubectl describe pod -n "$APP_NAMESPACE" <pod-name>

Logs check කරන්න:

    kubectl logs -n "$APP_NAMESPACE" <pod-name>

## Cleanup

Flux Kustomization delete කරන්න:

    kubectl delete kustomization professional-gitops-demo -n "$FLUX_NAMESPACE" --ignore-not-found

Flux GitRepository delete කරන්න:

    kubectl delete gitrepository professional-gitops-demo -n "$FLUX_NAMESPACE" --ignore-not-found

Demo namespace delete කරන්න:

    kubectl delete namespace "$APP_NAMESPACE" --ignore-not-found

Flux uninstall කරන්න:

    flux uninstall --silent

Kubernetes Flux resources remove කරන අතරතුර `flux-system` namespace එක ටික වෙලාවක් `Terminating` state එකේ තියෙන්න පුළුවන්.

Cleanup verify කරන්න:

    kubectl get ns flux-system 2>/dev/null || echo "flux-system removed"
    kubectl get ns gitops-sample-dev 2>/dev/null || echo "gitops-sample-dev removed"
    kubectl get crd | grep -E 'gitrepositories|kustomizations' || echo "Flux CRDs removed"

මෙයින් Flux සහ demo application එක remove වෙනවා.

මෙයින් remove වෙන්නේ නැහැ:

- AKS cluster
- Monitoring stack
- Key Vault
- ACR
- වෙනත් lab resources

Flux සහ Argo CD compare කරන්න අවශ්‍ය නම්, පසුව ඕනෑම tool එකක් නැවත install කරන්න පුළුවන්.

## What you completed

ඔයා complete කළා:

- AKS මත Flux installation
- Flux GitRepository source definition
- Flux Kustomization definition
- Git-based application sync
- Flux reconciliation test
- Cleanup path

මෙය next lab එකට prepare කරනවා:

    Professional Lab 03 - dev to qa to prod promotion

## Important note

මෙය professional GitOps lab එකක්.

Flux cluster එක ඇතුළේ run වෙලා GitRepository සහ Kustomization resources වල configure කරලා තියෙන Git repository එකෙන් reconcile කරනවා.

ඔයාගේ laptop එකේ local file edits Flux දකින්නේ නැහැ, ඒ edits configured Git source එකට commit වෙලා available වුණොත් විතරයි.

මෙම lab එකේ configured Git source එක public sample app repository එකයි.
