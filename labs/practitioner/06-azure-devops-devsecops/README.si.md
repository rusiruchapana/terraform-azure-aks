# Practitioner Lab 06 - Azure DevOps DevSecOps Checks

මෙම lab එකෙන් deployment එකකට කලින් Azure DevOps Pipelines තුළ DevSecOps checks run කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone scan-only lab එකක්.

මෙම lab එක AKS වලට deploy කරන්නේ නැහැ.

මෙම lab එක container registry එකකට images push කරන්නේ නැහැ.

මෙම lab එක use කරන්නේ:

- Pipelines run කරන්න පුළුවන් Azure DevOps project එකක්
- Azure DevOps pipeline template එකක්
- Security scanning සඳහා Trivy
- Image scan targets ලෙස use කරන backend සහ frontend Dockerfiles
- Config scan targets ලෙස use කරන Kubernetes manifests
- Azure DevOps pipeline agent එක තුළ local image builds
- Scan results සඳහා Azure DevOps pipeline output

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `azure-pipelines-devsecops.yml` use කරන Azure DevOps pipeline එකක්
- Required files validate කරන pipeline run එකක්
- Dockerfiles සහ Kubernetes YAML scan කරන pipeline run එකක්
- CI තුළ backend සහ frontend images locally build කරන pipeline run එකක්
- Local backend සහ frontend images scan කරන pipeline run එකක්
- මෙම lab එකෙන් AKS resources create නොවීම
- මෙම lab එකෙන් container image එකක් registry එකකට push නොවීම

මෙම lab එක security checks වලට පමණක් focus කරනවා.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Scan-only Azure DevOps pipeline එකක් prepare කරන විදිය
- Azure deployment credentials නැතුව DevSecOps checks run කරන විදිය
- Trivy use කරලා Dockerfiles සහ Kubernetes YAML scan කරන විදිය
- Azure DevOps Pipelines තුළ local images build කරන විදිය
- Locally built images scan කරන විදිය
- Trivy vulnerability output කියවන විදිය
- Learning mode සිට strict security gate mode එකට switch කරන විදිය
- CI/CD tools සඳහා supply-chain pinning වැදගත් ඇයි කියලා
- Lab එකෙන් පස්සේ copied app repository files clean up කරන විදිය

## Lab architecture

Flow එක:

    Azure DevOps project
      |
      v
    Azure DevOps Pipeline
      |
      v
    Validate files
      |
      v
    Scan Dockerfiles and Kubernetes YAML
      |
      v
    Build backend and frontend images locally
      |
      v
    Save image artifacts
      |
      v
    Scan backend and frontend images
      |
      v
    Summary

Azure DevOps pipeline එක මේ stages use කරනවා:

    Validate
      |
      v
    ScanConfig
      |
      v
    BuildImages
      |
      v
    ScanImages
      |
      v
    Summary

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- Azure DevOps account එකක්
- Pipelines create/run කරන්න පුළුවන් Azure DevOps project එකක්
- Azure DevOps Pipelines වලට connected Git repository එකක්
- Git
- Terminal එකක්
- Web browser එකක්

මෙම lab එකට අවශ්‍ය නැහැ:

- Azure credentials
- Registry credentials
- AKS access
- Azure DevOps service connections
- Paid security scanning accounts
- Local machine එකේ Docker Desktop

Image builds Azure DevOps pipeline agent එකේ සිදු වෙනවා.

## Azure DevOps project and repository requirement

Azure DevOps Pipelines මේ sources වලින් run කරන්න පුළුවන්:

- Azure Repos Git
- Azure Pipelines වලට connected GitHub

මෙම lab එකට ඔයා own කරන හෝ maintain කරන repository එකක් use කරන්න.

ඔයා own හෝ maintain නොකරන repository එකකට lab pipeline changes push කරන්න එපා.

Pipeline template එක lab folder එකේ තියෙනවා:

    labs/practitioner/06-azure-devops-devsecops/azure-pipelines/azure-pipelines-devsecops.yml

Lab එක කරන අතරතුර ඒ template එක app repository root එකට මෙහෙම copy කරනවා:

    azure-pipelines-devsecops.yml

Lab එක ඉවර වුණාට පස්සේ future pushes වලදී pipeline එක run වෙන්න එපා නම් copied pipeline file එක app repository එකෙන් remove කරන්න.

Lab folder එකේ තියෙන pipeline template එක delete කරන්න එපා.

## App source

මෙම lab එක 3-tier Node.js sample app repository එකක් against run වෙන්න design කරලා තියෙනවා.

Sample app repository:

    https://github.com/andrewferdinandus/3-tier-nodeapp

මෙම lab එකට sample app repository එකේ ඔයාගේ own copy එකක් use කරන්න.

Learning platform repository එක DevSecOps pipeline template සහ scan target reference files store කරනවා.

## Install required local tools

### Git

ඔයාගේ operating system එකට Git install කරන්න:

    https://git-scm.com/downloads

Git verify කරන්න:

    git --version

Expected:

    git version එක successfully print වෙන්න ඕන.

## Check local tools

Continue කරන්න කලින් verify කරන්න:

    git --version

## Files in this lab

මෙම lab එකේ files:

    backend/
      Image scan target එකක් ලෙස use කරන backend Dockerfile

    frontend/
      Scan targets ලෙස use කරන frontend Dockerfile සහ NGINX configuration

    k8s/
      Config scan targets ලෙස use කරන Kubernetes manifests

    azure-pipelines/
      Azure DevOps DevSecOps pipeline template

Files:

    backend/Dockerfile
    frontend/Dockerfile
    frontend/nginx.conf
    k8s/namespace.yaml
    k8s/mysql-secret.yaml
    k8s/mysql-init-configmap.yaml
    k8s/mysql-pvc.yaml
    k8s/mysql-deployment.yaml
    k8s/mysql-service.yaml
    k8s/backend-deployment.yaml
    k8s/backend-service.yaml
    k8s/frontend-deployment.yaml
    k8s/frontend-service.yaml
    azure-pipelines/azure-pipelines-devsecops.yml

මෙම app සහ Kubernetes files මෙම lab එකේ scan targets.

මෙම lab එක ඒවා deploy කරන්නේ නැහැ.

## Copy files into the app repository

මෙම commands `terraform-azure-aks` repository root එකේ සිට run කරන්න.

ඔයාගේ 3-tier app repository clone එකට local path එකක් set කරන්න:

    APP_REPO_DIR="<path-to-your-3-tier-nodeapp-repo>"

Example:

    APP_REPO_DIR="$HOME/terraform-azure-aks-labs/3-tier-nodeapp"

App repository එකේ folders create කරන්න:

    mkdir -p "$APP_REPO_DIR/backend"
    mkdir -p "$APP_REPO_DIR/frontend"
    mkdir -p "$APP_REPO_DIR/k8s"

Lab files copy කරන්න:

    cp labs/practitioner/06-azure-devops-devsecops/backend/Dockerfile "$APP_REPO_DIR/backend/Dockerfile"
    cp labs/practitioner/06-azure-devops-devsecops/frontend/Dockerfile "$APP_REPO_DIR/frontend/Dockerfile"
    cp labs/practitioner/06-azure-devops-devsecops/frontend/nginx.conf "$APP_REPO_DIR/frontend/nginx.conf"
    cp labs/practitioner/06-azure-devops-devsecops/k8s/* "$APP_REPO_DIR/k8s/"
    cp labs/practitioner/06-azure-devops-devsecops/azure-pipelines/azure-pipelines-devsecops.yml "$APP_REPO_DIR/azure-pipelines-devsecops.yml"

App repository structure එක verify කරන්න:

    find "$APP_REPO_DIR" -maxdepth 3 -type f | sort

Expected important files:

    backend/Dockerfile
    backend/package.json
    backend/server.js
    frontend/Dockerfile
    frontend/nginx.conf
    frontend/package.json
    frontend/src/App.js
    k8s/namespace.yaml
    k8s/backend-deployment.yaml
    k8s/backend-service.yaml
    k8s/frontend-deployment.yaml
    k8s/frontend-service.yaml
    k8s/mysql-deployment.yaml
    k8s/mysql-service.yaml
    azure-pipelines-devsecops.yml

## Commit the pipeline to your app repository

Azure DevOps Pipelines run වෙන්නේ connected repository එකට committed pipeline files වලින් පමණයි.

ඔයාගේ app repository clone එකට move වෙන්න:

    cd "$APP_REPO_DIR"

Copied Dockerfiles, manifests, NGINX config, සහ pipeline file commit කරන්න:

    git add backend/Dockerfile frontend/Dockerfile frontend/nginx.conf k8s azure-pipelines-devsecops.yml
    git commit -m "Add Azure DevOps DevSecOps checks lab"
    git push

ඔයා own හෝ maintain කරන repository එකකට විතරක් push කරන්න.

මේ lab pipeline changes වෙන කෙනෙකුගේ repository එකකට push කරන්න එපා.

## Create or connect the Azure DevOps pipeline

Azure DevOps වල:

    Pipelines
    New pipeline

ඔයාගේ repository source එක තෝරන්න:

    Azure Repos Git

හෝ:

    GitHub

App repository එක select කරන්න.

Existing YAML pipeline තෝරන්න.

YAML path එක set කරන්න:

    azure-pipelines-devsecops.yml

Pipeline එක save කරලා run කරන්න.

## Run the pipeline

Pipeline එක මේ stages run කරන්න ඕන:

    Validate
    ScanConfig
    BuildImages
    ScanImages
    Summary

Pipeline run එක open කරලා each stage completes ද check කරන්න.

## Verify the Azure DevOps pipeline run

`Validate` stage එක required files තියෙනවද confirm කරන්න ඕන.

`ScanConfig` stage එක Trivy config scan output පෙන්වන්න ඕන.

`BuildImages` stage එක backend සහ frontend images locally build කරන්න ඕන.

`ScanImages` stage එක images දෙකටම Trivy image scan output පෙන්වන්න ඕන.

`Summary` stage එක මෙම lab එක AKS වලට deploy නොකරන බව explain කරන්න ඕන.

## Expected result

Pipeline එක කරන්නේ:

- Required files validate කිරීම
- Dockerfiles සහ Kubernetes YAML scan කිරීම
- Backend සහ frontend images locally build කිරීම
- Backend සහ frontend image artifacts save කිරීම
- Backend සහ frontend images scan කිරීම
- Learning mode තුළ vulnerabilities report කිරීම
- Images registry එකකට push නොකිරීම
- AKS වලට කිසිවක් deploy නොකිරීම

## Image platform note

Pipeline එක images දෙකම `linux/amd64` සඳහා build කරනවා.

මෙය වැදගත්, මොකද බොහෝ AKS node pools amd64 nodes use කරනවා.

Agent එක ARM hardware එකක run වෙන විට image platform mismatch avoid කරන්නත් මෙය උදව් වෙනවා.

## Learning mode

මෙම lab එක default ලෙස learning mode එකෙන් run වෙනවා.

Learning mode කියන්නේ Trivy findings report කරනවා, නමුත් pipeline එක fail නොකරනවා.

Pipeline එක use කරන්නේ:

    --exit-code 0

## Strict security gate mode

Scan output එක තේරුම් ගත්තට පස්සේ, HIGH හෝ CRITICAL vulnerabilities තිබුණොත් scans වලින් pipeline එක fail කරවන්න පුළුවන්.

Change කරන්න:

    --exit-code 0

To:

    --exit-code 1

Strict mode carefulව use කරන්න.

Public base images වල vulnerabilities තිබිය හැකියි. ඒවා review කිරීම, patch කිරීම, හෝ documented risk acceptance අවශ්‍ය වෙන්න පුළුවන්.

## Why this lab does not use variables or secrets

මෙම lab එක scan-only DevSecOps lab එකක් ලෙස design කරලා තියෙනවා.

මෙම lab එක Azure DevOps pipeline variables use කරන්නේ නැහැ:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

ඒ variables deployment pipelines වලට අවශ්‍යයි, මොකද deployment pipelines වලට මේ දේවල් කරන්න වෙනවා:

- Azure වලට login වීම
- ACR වලට images push කිරීම
- AKS credentials ලබා ගැනීම
- Cluster එකට kubectl run කිරීම

මෙම DevSecOps lab එක ඒ actions කරන්නේ නැහැ.

ඒ වෙනුවට මේවා පමණක් කරනවා:

- Files validate කිරීම
- Dockerfiles සහ Kubernetes YAML scan කිරීම
- Pipeline agent එකේ local container images build කිරීම
- Local container images scan කිරීම
- Summary එක පෙන්වීම

මෙය lab එක safe සහ beginner-friendly තබාගන්නවා.

## Scan-only lab vs production pipeline

මෙම lab එක security scanning deployment වලින් වෙන් කරනවා, learning goal එක clear කරන්න.

Real production pipeline එකක DevSecOps checks deployment එක්ක combine වෙනවා:

    validate
      |
      v
    scan source and configuration
      |
      v
    build images
      |
      v
    scan images
      |
      v
    push images to registry
      |
      v
    deploy to AKS
      |
      v
    verify

එවැනි production-style pipeline එකකට credentials අවශ්‍යයි. වඩා හොඳ pattern එක Azure DevOps service connections හෝ federated identity use කිරීම.

Learning සඳහා මෙම lab එක secrets avoid කරනවා.

Production සඳහා prefer කරන්න:

- Azure DevOps service connections
- OIDC or federated credentials where possible
- Least privilege permissions
- Environment approvals
- Secret rotation
- Protected branches සඳහා strict scan gates

## Common findings

Image scans වල Node හෝ NGINX වගේ base images වල vulnerabilities report කරන එක normal.

ඒක හැමවිටම lab එක broken කියන්නේ නැහැ.

Real DevSecOps workflows වල findings review කරලා next action එක decide කරනවා.

Possible actions:

- Newer base images use කිරීම
- Smaller base images use කිරීම
- Upstream patches available වුණාට පස්සේ rebuild කිරීම
- Base image family change කිරීම
- Accepted risk document කිරීම
- Selected severity levels සඳහා පමණක් fail කිරීම
- Production branches සඳහා strict gates use කිරීම

## Important supply-chain note

Security tools ද dependencies වෙනවා.

Container image versions carefully pin කරන්න සහ upstream project security advisories review කරන්න.

Stronger production-style security සඳහා tools trusted versions වලට pin කරන්න සහ CI/CD dependency compromise එකක් සැක නම් secrets rotate කරන්න.

## Trivy notices

Trivy මෙවැනි notices print කරන්න පුළුවන්:

    A newer Trivy version is available
    VEX notice

මේවා informational.

ඒවා හැමවිටම pipeline failed කියන්නේ නැහැ.

මුලින් focus කරන්න:

- vulnerability severity
- fix එකක් available ද
- affected package එක actually used ද
- මෙය learning lab එකක්ද production deployment එකක්ද

## What to do if the image scan fails

Vulnerability output එක කියවන්න.

Possible actions:

- Newer base image එකක් use කිරීම
- Smaller base image එකක් use කිරීම
- Dependencies patch කිරීම
- Image එක rebuild කිරීම
- Documented exception process එකක් හරහා පමණක් risk accept කිරීම

## Troubleshooting

### Pipeline does not start

Connected app repository root එකේ `azure-pipelines-devsecops.yml` තියෙනවද verify කරන්න:

    azure-pipelines-devsecops.yml

Lab folder එකේ pipeline template එක තිබීම පමණක් ප්‍රමාණවත් නැහැ.

Azure DevOps connected repository එකේ pipeline file එක use කරනවා.

### Required file validation failed

`Validate` stage එක fail වුණොත්, app repository එකේ මෙම files තියෙනවද verify කරන්න:

    backend/Dockerfile
    backend/package.json
    backend/server.js
    frontend/Dockerfile
    frontend/nginx.conf
    frontend/package.json
    frontend/src/App.js
    k8s/namespace.yaml
    k8s/backend-deployment.yaml
    k8s/backend-service.yaml
    k8s/frontend-deployment.yaml
    k8s/frontend-service.yaml
    k8s/mysql-deployment.yaml
    k8s/mysql-service.yaml

### Trivy reports vulnerabilities

Learning labs වල මෙය බොහෝ විට expected.

Severity, package name, installed version, fixed version, සහ vulnerability description කියවන්න.

Finding එක pipeline block කළ යුතුද decide කරන්න.

### Docker build failed

`BuildImages` stage logs check කරන්න.

Dockerfiles තියෙනවද verify කරන්න:

    backend/Dockerfile
    frontend/Dockerfile

### No AKS resources were created

මෙය expected.

මෙම lab එක scan-only සහ AKS වලට deploy කරන්නේ නැහැ.

## Cleanup

මෙම lab එක AKS resources create කරන්නේ නැහැ.

මෙම lab එක registry එකකට images push කරන්නේ නැහැ.

Kubernetes හෝ ACR cleanup අවශ්‍ය නැහැ.

Files මෙම lab එකට විතරක් copy කළා නම්, ඒවා app repository clone එකෙන් remove කරන්න:

    cd "$APP_REPO_DIR"

    rm -rf k8s azure-pipelines-devsecops.yml
    rm -f backend/Dockerfile
    rm -f frontend/Dockerfile
    rm -f frontend/nginx.conf

Pipeline එක active තබාගන්න අවශ්‍ය නැත්නම්, cleanup change එක ඔයාගේ app repository එකට commit සහ push කරන්න:

    git add -A backend/Dockerfile frontend/Dockerfile frontend/nginx.conf k8s azure-pipelines-devsecops.yml
    git commit -m "Remove Azure DevOps DevSecOps checks lab files"
    git push

Lab templates මෙතනින් delete කරන්න එපා:

    labs/practitioner/06-azure-devops-devsecops/

## Security cleanup

මෙම lab එක Azure credentials හෝ registry credentials use කරන්නේ නැහැ.

Experiment කරන අතරතුර temporary secrets add කළා නම්, ඒවා remove හෝ rotate කරන්න.

Secrets Git වලට commit කරන්න එපා.

Production සඳහා prefer කරන්න:

- Least privilege permissions
- Azure DevOps service connections
- OIDC or federated credentials where possible
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code

## Important note

මෙය learning lab එකක්.

මෙම lab එක cloud deployment credentials නැතුව Azure DevOps Pipelines තුළ DevSecOps scanning teach කරනවා.

Production DevSecOps pipeline එකක් scanning, approvals, least privilege identity, SBOM generation, image signing, සහ policy validation combine කළ යුතුයි.
