# Practitioner Lab 04 - GitLab CI/CD DevSecOps Checks

මෙම lab එකෙන් deployment එකකට කලින් GitLab CI/CD තුළ DevSecOps checks run කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone scan-only lab එකක්.

මෙම lab එක AKS වලට deploy කරන්නේ නැහැ.

මෙම lab එක container registry එකකට images push කරන්නේ නැහැ.

මෙම lab එක use කරන්නේ:

- CI/CD pipelines run කරන්න පුළුවන් GitLab project එකක්
- GitLab CI/CD pipeline template එකක්
- Security scanning සඳහා Trivy
- Image scan target එකක් ලෙස use කරන sample app එකක්
- Config scan targets ලෙස use කරන Kubernetes manifests
- GitLab runner එක තුළ local image build එකක්
- Scan results සඳහා GitLab job output

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `.gitlab-ci.yml` use කරන GitLab pipeline එකක්
- Required files validate කරන workflow එකක්
- Dockerfile සහ Kubernetes YAML scan කරන workflow එකක්
- CI තුළ local container image එකක් build කරන workflow එකක්
- Local image එක scan කරන workflow එකක්
- මෙම lab එකෙන් AKS resources create නොවීම
- මෙම lab එකෙන් container image එකක් registry එකකට push නොවීම

මෙම lab එක security checks වලට පමණක් focus කරනවා.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Scan-only GitLab CI/CD pipeline එකක් prepare කරන විදිය
- Azure deployment credentials නැතුව DevSecOps checks run කරන විදිය
- Trivy use කරලා Dockerfile සහ Kubernetes YAML scan කරන විදිය
- GitLab CI/CD තුළ local image එකක් build කරන විදිය
- Locally built image එක scan කරන විදිය
- Trivy vulnerability output කියවන විදිය
- Learning mode සිට strict gate mode එකට switch කරන විදිය
- CI/CD tools සඳහා supply-chain pinning වැදගත් ඇයි කියලා
- Lab එකෙන් පස්සේ copied GitLab project files clean up කරන විදිය

## Lab architecture

Flow එක:

    GitLab project
      |
      v
    GitLab CI/CD pipeline
      |
      v
    Validate files
      |
      v
    Scan Dockerfile and Kubernetes YAML
      |
      v
    Build local image in CI
      |
      v
    Scan local image
      |
      v
    Summary

GitLab pipeline එක මේ stages use කරනවා:

    validate
      |
      v
    scan_config
      |
      v
    build_image
      |
      v
    scan_image
      |
      v
    summary

## What this lab requires

ඔයාට මේවා අවශ්‍යයි:

- GitLab account එකක්
- `.gitlab-ci.yml` add කරන්න සහ pipelines run කරන්න පුළුවන් GitLab project එකක්
- Git
- Terminal එකක්
- Web browser එකක්

මෙම lab එකට අවශ්‍ය නැහැ:

- Azure credentials
- Registry credentials
- AKS access
- GitLab Ultimate
- Paid GitLab security features
- Local machine එකේ Docker Desktop

Image build එක GitLab runner එකේ සිදු වෙනවා.

## GitLab project requirement

GitLab CI/CD pipelines GitLab project root එකේ මෙම file එකෙන් detect වෙනවා:

    .gitlab-ci.yml

මෙම lab එකට ඔයා own කරන හෝ maintain කරන GitLab project එකක් use කරන්න.

ඔයා own හෝ maintain නොකරන project එකකට lab pipeline changes push කරන්න එපා.

Pipeline template එක lab folder එකේ තියෙනවා:

    labs/practitioner/04-gitlab-ci-devsecops/gitlab-ci/.gitlab-ci.yml

Lab එක කරන අතරතුර ඒ template එක GitLab project root එකට මෙහෙම copy කරනවා:

    .gitlab-ci.yml

Lab එක ඉවර වුණාට පස්සේ future pushes වලදී pipeline එක run වෙන්න එපා නම් copied pipeline file එක GitLab project එකෙන් remove කරන්න.

Lab folder එකේ තියෙන pipeline template එක delete කරන්න එපා.

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

    app/
      Image scan target එකක් ලෙස use කරන sample static app එක

    k8s/
      Config scan targets ලෙස use කරන Kubernetes manifests

    gitlab-ci/
      GitLab CI/CD DevSecOps pipeline template

Files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    gitlab-ci/.gitlab-ci.yml

මෙම app සහ Kubernetes files මෙම lab එකේ scan targets.

මෙම lab එක ඒවා deploy කරන්නේ නැහැ.

## Copy files into your GitLab project

මෙම commands `terraform-azure-aks` repository root එකේ සිට run කරන්න.

ඔයාගේ GitLab project clone එකට local path එකක් set කරන්න:

    GITLAB_PROJECT_DIR="<path-to-your-gitlab-project>"

Example:

    GITLAB_PROJECT_DIR="$HOME/terraform-azure-aks-labs/aks-gitlab-devsecops-lab"

GitLab project එකේ folders create කරන්න:

    mkdir -p "$GITLAB_PROJECT_DIR/app"
    mkdir -p "$GITLAB_PROJECT_DIR/k8s"

Lab files copy කරන්න:

    cp labs/practitioner/04-gitlab-ci-devsecops/app/* "$GITLAB_PROJECT_DIR/app/"
    cp labs/practitioner/04-gitlab-ci-devsecops/k8s/* "$GITLAB_PROJECT_DIR/k8s/"
    cp labs/practitioner/04-gitlab-ci-devsecops/gitlab-ci/.gitlab-ci.yml "$GITLAB_PROJECT_DIR/.gitlab-ci.yml"

GitLab project structure එක verify කරන්න:

    find "$GITLAB_PROJECT_DIR" -maxdepth 3 -type f | sort

Expected files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    .gitlab-ci.yml

## Commit the pipeline to your own GitLab project

GitLab CI/CD run වෙන්නේ GitLab project එකකට committed pipelines පමණයි.

ඔයාගේ GitLab project clone එකට move වෙන්න:

    cd "$GITLAB_PROJECT_DIR"

Copied app, manifests, සහ pipeline file commit කරන්න:

    git add app k8s .gitlab-ci.yml
    git commit -m "Add GitLab CI/CD DevSecOps checks lab"
    git push

ඔයා own හෝ maintain කරන GitLab project එකකට විතරක් push කරන්න.

මේ lab pipeline changes වෙන කෙනෙකුගේ project එකකට push කරන්න එපා.

## Run the pipeline

Browser එකෙන් ඔයාගේ GitLab project එක open කරන්න.

මෙතනට යන්න:

    Build
    Pipelines

Project එකට push කළාම pipeline එක run වෙන්න පුළුවන්.

Manually run කරන්න අවශ්‍ය නම්:

    Run pipeline

Pipeline එක මේ stages run කරන්න ඕන:

    validate
    scan_config
    build_image
    scan_image
    summary

## Verify the GitLab pipeline run

Pipeline එක open කරලා each stage succeeded ද check කරන්න.

Expected stages:

    validate
    scan_config
    build_image
    scan_image
    summary

`validate` stage එක required files තියෙනවද confirm කරන්න ඕන.

`scan_config` stage එක Trivy config scan output පෙන්වන්න ඕන.

`build_image` stage එක runner එක තුළ local image එකක් build කරන්න ඕන.

`scan_image` stage එක Trivy image scan output පෙන්වන්න ඕන.

`summary` stage එක මෙම lab එක AKS වලට deploy නොකරන බව explain කරන්න ඕන.

## Expected result

Pipeline එක කරන්නේ:

- Required files validate කිරීම
- Dockerfile සහ Kubernetes YAML scan කිරීම
- CI තුළ local Docker image එකක් build කිරීම
- Image එක `image.tar` ලෙස save කිරීම
- Image archive එක scan කිරීම
- Pipeline logs වල scan results පෙන්වීම
- Images registry එකකට push නොකිරීම
- AKS වලට කිසිවක් deploy නොකිරීම

## Image platform note

Pipeline එක image එක `linux/amd64` සඳහා build කරනවා:

    docker build --platform linux/amd64 -t "$IMAGE_NAME:$CI_COMMIT_SHA" "$APP_PATH"

මෙය වැදගත්, මොකද බොහෝ AKS node pools amd64 nodes use කරනවා.

Runner එක ARM hardware එකක run වෙන විට image platform mismatch avoid කරන්නත් මෙය උදව් වෙනවා.

## Learning mode

මෙම lab එක default ලෙස learning mode එකෙන් run වෙනවා.

Learning mode කියන්නේ Trivy findings report කරනවා, නමුත් pipeline එක fail නොකරනවා.

Pipeline එක use කරන්නේ:

    --exit-code 0

## Strict security gate mode

Output එක තේරුම් ගත්තට පස්සේ, HIGH හෝ CRITICAL vulnerabilities හමු වුණොත් scan එකෙන් pipeline එක fail කරවන්න පුළුවන්.

Change කරන්න:

    --exit-code 0

To:

    --exit-code 1

Strict mode carefulව use කරන්න.

Public base images වල vulnerabilities තිබිය හැකියි. ඒවා review කිරීම, patch කිරීම, හෝ documented risk acceptance අවශ්‍ය වෙන්න පුළුවන්.

## Example scan result

Image scan එක base image එකේ vulnerabilities report කරන එක normal.

Example result:

    Total: 31 vulnerabilities
    HIGH: 29
    CRITICAL: 2

ඒක හැමවිටම lab එක broken කියන්නේ නැහැ.

ඒකෙන් කියන්නේ scanner එක image layers තුළ known vulnerabilities හොයාගෙන තියෙනවා කියලා. සාමාන්‍යයෙන් ඒවා base operating system packages වලින් එනවා.

Real DevSecOps workflow එකකදී findings review කරලා next action එක decide කරනවා.

Possible actions:

- Newer base image එකක් use කිරීම
- Smaller base image එකක් use කිරීම
- Upstream patches available වුණාට පස්සේ rebuild කිරීම
- Base image family එක change කිරීම
- Accepted risk document කිරීම
- Selected severity levels සඳහා පමණක් pipeline fail කිරීම
- Production branches සඳහා strict security gates use කිරීම

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

GitLab project root එකේ `.gitlab-ci.yml` තියෙනවද verify කරන්න:

    .gitlab-ci.yml

Lab folder එකේ pipeline template එක තිබීම පමණක් ප්‍රමාණවත් නැහැ.

GitLab project root එකේ `.gitlab-ci.yml` file එකෙන් pipelines detect කරනවා.

### Required file validation failed

`validate` stage එක fail වුණොත්, GitLab project එකේ මෙම files තියෙනවද verify කරන්න:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml

### Trivy reports vulnerabilities

Learning labs වල මෙය බොහෝ විට expected.

Severity, package name, installed version, fixed version, සහ vulnerability description කියවන්න.

Finding එක pipeline block කළ යුතුද decide කරන්න.

### Docker build failed

`build_image` stage logs check කරන්න.

Dockerfile එක තියෙනවද verify කරන්න:

    app/Dockerfile

### No AKS resources were created

මෙය expected.

මෙම lab එක scan-only සහ AKS වලට deploy කරන්නේ නැහැ.

## Cleanup

මෙම lab එක AKS resources create කරන්නේ නැහැ.

මෙම lab එක registry එකකට images push කරන්නේ නැහැ.

Kubernetes හෝ ACR cleanup අවශ්‍ය නැහැ.

Files මෙම lab එකට විතරක් copy කළා නම්, ඒවා ඔයාගේ GitLab project clone එකෙන් remove කරන්න:

    cd "$GITLAB_PROJECT_DIR"

    rm -rf app k8s .gitlab-ci.yml

Pipeline එක active තබාගන්න අවශ්‍ය නැත්නම්, cleanup change එක ඔයාගේ GitLab project එකට commit සහ push කරන්න:

    git add -A app k8s .gitlab-ci.yml
    git commit -m "Remove GitLab CI/CD DevSecOps checks lab files"
    git push

Lab templates මෙතනින් delete කරන්න එපා:

    labs/practitioner/04-gitlab-ci-devsecops/

## Security cleanup

මෙම lab එක Azure credentials හෝ registry credentials use කරන්නේ නැහැ.

Experiment කරන අතරතුර temporary secrets add කළා නම්, ඒවා remove හෝ rotate කරන්න.

Secrets Git වලට commit කරන්න එපා.

Production සඳහා prefer කරන්න:

- Least privilege permissions
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code

## Important note

මෙය learning lab එකක්.

මෙම lab එක cloud deployment credentials නැතුව GitLab CI/CD තුළ DevSecOps scanning teach කරනවා.

Production DevSecOps pipeline එකක් scanning, approvals, least privilege identity, SBOM generation, image signing, සහ policy validation combine කළ යුතුයි.
