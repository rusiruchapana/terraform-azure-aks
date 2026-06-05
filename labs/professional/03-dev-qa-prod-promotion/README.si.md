# Professional Lab 03 - dev to qa to prod promotion

මෙම lab එකෙන් Argo CD use කරලා application desired state එක dev සිට qa හරහා prod වෙත promote කරන ආකාරය ඉගෙන ගන්නවා.

මෙය professional GitOps lab එකක්.

Goal එක direct `kubectl apply` කිරීම නෙවෙයි. Goal එක Git හරහා environment promotion තේරුම් ගැනීමයි.

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- Sample GitOps application repository එකේ fork එකක්
- Sample repository එකේ dev, qa, prod desired-state folders
- Argo CD Applications තුනක්
- AKS namespaces තුනක්
- එක් එක් environment එකේ running demo app එකක්
- dev v1 සිට v2 වෙත promote වීම
- qa v1 සිට v2 වෙත promote වීම
- prod v1 සිට v2 වෙත promote වීම
- Argo CD UI එකෙන් environments බලන්න හැකියාව
- Argo CD self-heal tested වීම

## What you will learn

මෙම lab එකෙන් ඔබට මේවා ඉගෙන ගන්න පුළුවන්:

- GitOps promotion වැඩ කරන ආකාරය
- App desired state application GitOps repository එකක තියෙන්න ඕන ඇයි
- dev, qa, prod desired state වෙන වෙනම තබන ආකාරය
- Argo CD Applications කිහිපයක් track කරන ආකාරය
- Change එකක් environment by environment promote කරන ආකාරය
- GitOps වල local file changes පමණක් ප්‍රමාණවත් නැත්තේ ඇයි
- Argo CD sync සහ self-heal වැඩ කරන ආකාරය
- kubectl සහ browser access හරහා promotion verify කරන ආකාරය

## Architecture

මෙම lab එක repositories දෙකක් use කරනවා.

Platform සහ lab repository:

    terraform-azure-aks

මෙම repository එකේ තියෙන්නේ:

    labs/professional/03-dev-qa-prod-promotion/README.md
    labs/professional/03-dev-qa-prod-promotion/README.si.md
    labs/professional/03-dev-qa-prod-promotion/argocd/application-dev.yaml
    labs/professional/03-dev-qa-prod-promotion/argocd/application-qa.yaml
    labs/professional/03-dev-qa-prod-promotion/argocd/application-prod.yaml

Sample application GitOps repository:

    aks-gitops-sample-app

Sample repository එකේ application desired state තියෙන්නේ:

    k8s/promotion/dev
    k8s/promotion/qa
    k8s/promotion/prod

එක් එක් Argo CD Application එක environment path එකකට point කරනවා:

    promotion-demo-dev  -> k8s/promotion/dev
    promotion-demo-qa   -> k8s/promotion/qa
    promotion-demo-prod -> k8s/promotion/prod

එක් එක් environment එක deploy කරන්නේ:

- Namespace
- ConfigMap
- Deployment
- Service

App එක ConfigMap එකකින් environment-specific HTML page serve කරන simple NGINX workload එකක්.

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

## Install required local tools

### kubectl

kubectl verify කරන්න:

    kubectl version --client

### Git

Git verify කරන්න:

    git --version

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

## Fork the sample app repository

මෙම lab එක මෙම sample application GitOps repository එක use කරනවා:

    https://github.com/andrewferdinandus/aks-gitops-sample-app

මෙම repository එක ඔයාගේ GitHub account එකට හෝ organization එකට fork කරන්න.

Example fork URL:

    https://github.com/<your-user-or-org>/aks-gitops-sample-app.git

Fork එකක් use කරන්නේ ඇයි?

Argo CD desired state read කරන්නේ Git වලින්. මෙම lab එකේදී app එක dev සිට qa හරහා prod වෙත promote කරන්නේ මේ files edit කිරීමෙන්:

    k8s/promotion/dev
    k8s/promotion/qa
    k8s/promotion/prod

ඒ changes push කරන්න ඔයාට write access ඕන. Fork එකක් දාගත්තම sample repository එකේ ඔයාගේම copy එකක් ලැබෙනවා.

## Clone your fork

ඔයාගේ projects folder එකට යන්න:

    cd <local-path>

ඔයාගේ fork එක clone කරන්න:

    git clone https://github.com/<your-user-or-org>/aks-gitops-sample-app.git

Sample app repository එකට යන්න:

    cd aks-gitops-sample-app

Sample repo directory set කරන්න:

    SAMPLE_REPO_DIR="$(pwd)"

Verify කරන්න:

    echo "$SAMPLE_REPO_DIR"

## Set lab variables

ඔයාගේ sample app repository URL එක set කරන්න.

ඔයාගේ fork එක use කරන්න:

    REPO_URL="https://github.com/<your-user-or-org>/aks-gitops-sample-app.git"

Verify කරන්න:

    echo "$REPO_URL"

Platform repo directory set කරන්න:

    PLATFORM_REPO_DIR="<local-path>/terraform-azure-aks"

Verify කරන්න:

    echo "$PLATFORM_REPO_DIR"

## Verify starter desired state

මෙය sample app repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

Starter version values check කරන්න:

    grep -RInE 'Environment:|Version:' \
      k8s/promotion/dev/configmap.yaml \
      k8s/promotion/qa/configmap.yaml \
      k8s/promotion/prod/configmap.yaml

Expected starter state:

    dev  = v1
    qa   = v1
    prod = v1

Git status check කරන්න:

    git status --short

Sample app repository එකේ files change/add කරලා තියෙනවා නම් commit සහ push කරන්න:

    git add k8s/promotion
    git commit -m "Add promotion demo desired state"
    git push

## Create Argo CD Applications

මෙම commands platform repository එකෙන් run කරන්න:

    cd "$PLATFORM_REPO_DIR"

dev Application apply කරන්න:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/03-dev-qa-prod-promotion/argocd/application-dev.yaml \
      | kubectl apply -f -

qa Application apply කරන්න:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/03-dev-qa-prod-promotion/argocd/application-qa.yaml \
      | kubectl apply -f -

prod Application apply කරන්න:

    sed "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" \
      labs/professional/03-dev-qa-prod-promotion/argocd/application-prod.yaml \
      | kubectl apply -f -

Verify කරන්න:

    kubectl get applications -n argocd

Expected:

    promotion-demo-dev    Synced    Healthy
    promotion-demo-qa     Synced    Healthy
    promotion-demo-prod   Synced    Healthy

## Verify Kubernetes resources

Namespaces check කරන්න:

    kubectl get ns promotion-dev promotion-qa promotion-prod

Pods check කරන්න:

    kubectl get pods -n promotion-dev
    kubectl get pods -n promotion-qa
    kubectl get pods -n promotion-prod

Services check කරන්න:

    kubectl get svc -n promotion-dev
    kubectl get svc -n promotion-qa
    kubectl get svc -n promotion-prod

Expected:

- dev namespace එකේ pod 1ක්
- qa namespace එකේ pods 2ක්
- prod namespace එකේ pods 2ක්
- එක් එක් namespace එකේ `promotion-demo` ClusterIP service එකක්

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

UI එකේ මේ Applications පේනවද verify කරන්න:

- promotion-demo-dev
- promotion-demo-qa
- promotion-demo-prod

මෙම lab එකට Argo CD public expose කරන්න එපා.

Port-forward use කරන්නේ local learning සඳහා safer සහ simpler නිසා.

## Verify app pages

dev port-forward කරන්න:

    kubectl port-forward svc/promotion-demo -n promotion-dev 8081:80

Open කරන්න:

    http://localhost:8081

Expected:

    Environment: dev
    Version: v1

qa port-forward කරන්න:

    kubectl port-forward svc/promotion-demo -n promotion-qa 8082:80

Open කරන්න:

    http://localhost:8082

Expected:

    Environment: qa
    Version: v1

prod port-forward කරන්න:

    kubectl port-forward svc/promotion-demo -n promotion-prod 8083:80

Open කරන්න:

    http://localhost:8083

Expected:

    Environment: prod
    Version: v1

Browser එක old content පෙන්වනවා නම්, port-forward restart කරලා browser hard refresh කරන්න.

## Promote dev to v2

මෙය sample app repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

dev ConfigMap එකේ HTML version line එක පමණක් update කරන්න:

    python3 -c 'from pathlib import Path; p=Path("k8s/promotion/dev/configmap.yaml"); text=p.read_text(); p.write_text(text.replace("<p>Version: v1</p>", "<p>Version: v2</p>"))'

Verify කරන්න:

    grep -nE 'apiVersion|Environment:|Version:' \
      k8s/promotion/dev/configmap.yaml

Commit සහ push කරන්න:

    git add k8s/promotion/dev/configmap.yaml
    git commit -m "Promote demo dev environment to v2"
    git push

dev Application refresh කරන්න:

    kubectl annotate application promotion-demo-dev -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Verify කරන්න:

    kubectl get applications -n argocd

dev ConfigMap check කරන්න:

    kubectl get configmap promotion-demo-content -n promotion-dev \
      -o jsonpath='{.data.index\.html}'
    echo

Expected:

    Environment: dev
    Version: v2

මෙම අවස්ථාවේදී:

    dev  = v2
    qa   = v1
    prod = v1

## Promote qa to v2

මෙය sample app repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

qa ConfigMap එකේ HTML version line එක පමණක් update කරන්න:

    python3 -c 'from pathlib import Path; p=Path("k8s/promotion/qa/configmap.yaml"); text=p.read_text(); p.write_text(text.replace("<p>Version: v1</p>", "<p>Version: v2</p>"))'

Verify කරන්න:

    grep -nE 'apiVersion|Environment:|Version:' \
      k8s/promotion/qa/configmap.yaml

Commit සහ push කරන්න:

    git add k8s/promotion/qa/configmap.yaml
    git commit -m "Promote demo qa environment to v2"
    git push

qa Application refresh කරන්න:

    kubectl annotate application promotion-demo-qa -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

qa verify කරන්න:

    kubectl get configmap promotion-demo-content -n promotion-qa \
      -o jsonpath='{.data.index\.html}'
    echo

prod තවම v1 ද verify කරන්න:

    kubectl get configmap promotion-demo-content -n promotion-prod \
      -o jsonpath='{.data.index\.html}'
    echo

මෙම අවස්ථාවේදී:

    dev  = v2
    qa   = v2
    prod = v1

## Promote prod to v2

මෙය sample app repository එකෙන් run කරන්න:

    cd "$SAMPLE_REPO_DIR"

prod ConfigMap එකේ HTML version line එක පමණක් update කරන්න:

    python3 -c 'from pathlib import Path; p=Path("k8s/promotion/prod/configmap.yaml"); text=p.read_text(); p.write_text(text.replace("<p>Version: v1</p>", "<p>Version: v2</p>"))'

Verify කරන්න:

    grep -nE 'apiVersion|Environment:|Version:' \
      k8s/promotion/prod/configmap.yaml

Commit සහ push කරන්න:

    git add k8s/promotion/prod/configmap.yaml
    git commit -m "Promote demo prod environment to v2"
    git push

prod Application refresh කරන්න:

    kubectl annotate application promotion-demo-prod -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

Final state verify කරන්න:

    kubectl get applications -n argocd

    kubectl get configmap promotion-demo-content -n promotion-dev \
      -o jsonpath='{.data.index\.html}'
    echo

    kubectl get configmap promotion-demo-content -n promotion-qa \
      -o jsonpath='{.data.index\.html}'
    echo

    kubectl get configmap promotion-demo-content -n promotion-prod \
      -o jsonpath='{.data.index\.html}'
    echo

Expected final state:

    dev  = v2
    qa   = v2
    prod = v2

## Test self-heal

Prod desired state එකේ replicas 2යි.

Prod replicas manually change කරන්න:

    kubectl scale deployment promotion-demo -n promotion-prod --replicas=1

Check කරන්න:

    kubectl get deployment promotion-demo -n promotion-prod

තත්පර 30 සිට 60 දක්වා wait කරලා නැවත check කරන්න:

    kubectl get deployment promotion-demo -n promotion-prod
    kubectl get applications -n argocd

Expected:

    promotion-demo නැවත replicas 2ට එන්න ඕන
    promotion-demo-prod Synced සහ Healthy වෙන්න ඕන

මේකෙන් Argo CD self-heal manual drift correct කළා කියලා prove වෙනවා.

## Troubleshooting

### Application is OutOfSync

Application refresh කරන්න:

    kubectl annotate application promotion-demo-dev -n argocd \
      argocd.argoproj.io/refresh=hard --overwrite

නැත්නම් Argo CD UI එකෙන්:

    Application -> SYNC -> SYNCHRONIZE

### Argo CD cannot find the repo path

Application manifest එකේ path check කරන්න:

    k8s/promotion/dev
    k8s/promotion/qa
    k8s/promotion/prod

Files commit කරලා `REPO_URL` එකෙන් configured Git repository එකේ available ද verify කරන්න.

### Browser shows old version

Port-forward restart කරන්න.

Browser hard refresh කරන්න.

Kubernetes වලින් direct verify කරන්න:

    kubectl get configmap promotion-demo-content -n promotion-dev \
      -o jsonpath='{.data.index\.html}'
    echo

### ConfigMap apiVersion error

මේ වගේ error එකක් ආවොත්:

    The Kubernetes API could not find version "v2" of /ConfigMap

ඔයා වැරදිලා Kubernetes API version line එක වෙනස් කරලා.

ඒක නැවත fix කරන්න:

    apiVersion: v1

HTML line එක පමණක් change කරන්න:

    <p>Version: v1</p>

## Cleanup

Argo CD Applications delete කරන්න:

    kubectl delete application promotion-demo-dev -n argocd --ignore-not-found
    kubectl delete application promotion-demo-qa -n argocd --ignore-not-found
    kubectl delete application promotion-demo-prod -n argocd --ignore-not-found

Promotion namespaces delete කරන්න:

    kubectl delete namespace promotion-dev --ignore-not-found
    kubectl delete namespace promotion-qa --ignore-not-found
    kubectl delete namespace promotion-prod --ignore-not-found

Verify කරන්න:

    kubectl get applications -n argocd
    kubectl get ns promotion-dev promotion-qa promotion-prod 2>/dev/null || echo "promotion namespaces removed"

මෙම cleanup එක Argo CD remove කරන්නේ නැහැ.

## What you completed

ඔයා complete කළා:

- dev, qa, prod desired-state structure
- Argo CD Applications තුනක්
- dev සිට qa හරහා prod promotion
- Argo CD UI verification
- Browser verification
- Git-driven environment promotion
- Argo CD self-heal test
- Cleanup

මෙය next lab එකට prepare කරනවා:

    Professional Lab 04 - Blue/Green Deployment

## Important note

මෙම lab එක promotion pattern එකක්.

වැදගත් දේ sample NGINX app එක නෙවෙයි.

වැදගත් concept එක:

    Git desired state
      |
      v
    Argo CD sync
      |
      v
    Environment-specific cluster state

Real production use සඳහා මෙම pattern එක pull requests, approvals, security checks, monitoring, rollback plans, සහ change management සමඟ combine කරන්න.
