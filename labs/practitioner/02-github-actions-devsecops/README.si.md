# Practitioner Lab 02 - GitHub Actions DevSecOps Checks

මෙම lab එකෙන් deployment එකකට කලින් GitHub Actions තුළ DevSecOps checks run කරන විදිය ඉගෙන ගන්නවා.

මෙය standalone scan-only lab එකක්.

මෙම lab එක AKS වලට deploy කරන්නේ නැහැ.

මෙම lab එක container registry එකකට images push කරන්නේ නැහැ.

මෙම lab එක use කරන්නේ:

- GitHub Actions run කරන්න පුළුවන් GitHub repository එකක්
- GitHub Actions workflow template එකක්
- Security scanning සඳහා Trivy
- Image scan target එකක් ලෙස use කරන sample app එකක්
- Config scan targets ලෙස use කරන Kubernetes manifests
- GitHub Actions runner එක තුළ local image build එකක්
- Scan results සඳහා GitHub Actions job output

## Lab goal

මෙම lab එක අවසානයේ ඔයාට මේවා තිබිය යුතුයි:

- `GitHub Actions DevSecOps Checks` කියන GitHub Actions workflow එකක්
- `.github/workflows/devsecops-checks.yaml` path එකේ copied workflow file එකක්
- Required files validate කරන workflow run එකක්
- Repository files scan කරන workflow run එකක්
- Dockerfile සහ Kubernetes YAML scan කරන workflow run එකක්
- CI තුළ local container image එකක් build කරන workflow run එකක්
- Local image එක scan කරන workflow run එකක්
- මෙම lab එකෙන් AKS resources create නොවීම
- මෙම lab එකෙන් container image එකක් registry එකකට push නොවීම

මෙම lab එක security checks වලට පමණක් focus කරනවා.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Scan-only GitHub Actions workflow එකක් prepare කරන විදිය
- Azure deployment credentials නැතුව DevSecOps checks run කරන විදිය
- Trivy use කරලා repository files scan කරන විදිය
- Trivy use කරලා Dockerfile සහ Kubernetes YAML scan කරන විදිය
- GitHub Actions තුළ local image එකක් build කරන විදිය
- Locally built image එක scan කරන විදිය
- Trivy vulnerability output කියවන විදිය
- Findings pipeline එක fail කළ යුතුද කියලා තීරණය කරන විදිය
- GitHub Actions supply-chain pinning වැදගත් ඇයි කියලා
- Lab එකෙන් පස්සේ copied workflow files clean up කරන විදිය

## Lab architecture

Flow එක:

    GitHub repository
      |
      v
    GitHub Actions workflow
      |
      v
    Validate files
      |
      v
    Scan repository files
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

GitHub Actions workflow එක මේ jobs use කරනවා:

    validate
      |
      v
    scan_filesystem
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

- GitHub account එකක්
- Workflow files add කරන්න සහ GitHub Actions run කරන්න පුළුවන් GitHub repository එකක්
- Git
- Terminal එකක්
- Web browser එකක්

මෙම lab එකට අවශ්‍ය නැහැ:

- Azure credentials
- Registry credentials
- AKS access
- GitHub Advanced Security
- Paid security scanning accounts
- Local machine එකේ Docker Desktop

Image build එක GitHub Actions runner එකේ සිදු වෙනවා.

## GitHub repository requirement

GitHub Actions workflows GitHub repository එකක මේ path එක යටතේ තිබිය යුතුයි:

    .github/workflows/

මෙම lab එකට ඔයා own කරන හෝ maintain කරන repository එකක් use කරන්න.

ඔයාට මෙම learning repository එකේ own copy එකක් use කරන්න පුළුවන්.

ඔයා own හෝ maintain නොකරන repository එකකට lab workflow changes push කරන්න එපා.

Workflow template එක lab folder එකේ තියෙනවා:

    labs/practitioner/02-github-actions-devsecops/github-actions/devsecops-checks.yaml

Lab එක කරන අතරතුර ඒ template එක මෙතනට copy කරනවා:

    .github/workflows/devsecops-checks.yaml

Lab එක ඉවර වුණාට පස්සේ future pushes වලදී workflow එක run වෙන්න එපා නම් copied workflow එක remove කරන්න.

Lab folder එකේ තියෙන workflow template එක delete කරන්න එපා.

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

    github-actions/
      GitHub Actions DevSecOps workflow template

Files:

    app/Dockerfile
    app/index.html
    k8s/namespace.yaml
    k8s/deployment.yaml
    k8s/service.yaml
    github-actions/devsecops-checks.yaml

මෙම app සහ Kubernetes files මෙම lab එකේ scan targets.

මෙම lab එක ඒවා deploy කරන්නේ නැහැ.

## Copy the workflow template

මෙම commands `terraform-azure-aks` repository root එකේ සිට run කරන්න.

GitHub Actions workflow folder එක create කරන්න:

    mkdir -p .github/workflows

Workflow template එක copy කරන්න:

    cp labs/practitioner/02-github-actions-devsecops/github-actions/devsecops-checks.yaml \
      .github/workflows/devsecops-checks.yaml

Copied workflow එක verify කරන්න:

    test -f .github/workflows/devsecops-checks.yaml

## Review the workflow trigger

Workflow එක manual සහ push-based execution දෙකම support කරනවා:

    workflow_dispatch

සහ:

    push to main

Push trigger එක watch කරන්නේ:

    labs/practitioner/02-github-actions-devsecops/**
    .github/workflows/devsecops-checks.yaml

ඒ කියන්නේ `main` branch එකේ lab files හෝ workflow file එකට changes push කළාම workflow එක run වෙන්න පුළුවන්.

GitHub Actions tab එකෙන් manually run කරන්නත් පුළුවන්.

## Commit the workflow to your own GitHub repository

GitHub Actions run වෙන්නේ GitHub repository එකකට committed workflows පමණයි.

Copied workflow සහ lab files ඔයාගේම repository එකට commit කරන්න:

    git add .github/workflows/devsecops-checks.yaml
    git add labs/practitioner/02-github-actions-devsecops

    git commit -m "Add GitHub Actions DevSecOps checks lab"
    git push

ඔයා own හෝ maintain කරන repository එකකට විතරක් push කරන්න.

මේ lab workflow changes වෙන කෙනෙකුගේ repository එකකට push කරන්න එපා.

## Run the workflow

Browser එකෙන් ඔයාගේ GitHub repository එක open කරන්න.

මෙතනට යන්න:

    Actions
    GitHub Actions DevSecOps Checks

Workflow එක මේ ways දෙකෙන් එකකින් run කරන්න පුළුවන්:

Option 1, manual run:

    Run workflow
    Branch: main
    Run workflow

Option 2, push trigger:

    Workflow හෝ lab files change කරන commit එකක් main branch එකට push කරන්න.

Workflow එක මේ jobs run කරන්න ඕන:

    validate
    scan_filesystem
    scan_config
    build_image
    scan_image
    summary

## Verify the GitHub Actions run

Workflow run එක open කරලා each job completed ද check කරන්න.

Expected jobs:

    validate
    scan_filesystem
    scan_config
    build_image
    scan_image
    summary

`validate` job එක required files තියෙනවද confirm කරන්න ඕන.

`scan_filesystem` job එක Trivy filesystem scan output පෙන්වන්න ඕන.

`scan_config` job එක Trivy config scan output පෙන්වන්න ඕන.

`build_image` job එක runner එක තුළ local image එකක් build කරන්න ඕන.

`scan_image` job එක Trivy image scan output පෙන්වන්න ඕන.

`summary` job එක මෙම lab එක AKS වලට deploy නොකරන බව explain කරන්න ඕන.

## Expected result

Workflow එක කරන්නේ:

- Required files validate කිරීම
- Repository files scan කිරීම
- Dockerfile සහ Kubernetes YAML scan කිරීම
- CI තුළ local Docker image එකක් build කිරීම
- Image එක scan කිරීම
- Workflow logs වල scan results පෙන්වීම
- Images registry එකකට push නොකිරීම
- AKS වලට කිසිවක් deploy නොකිරීම

## Example scan result

Image scan එක base image එකේ vulnerabilities report කරන එක normal.

Example result:

    Total: 31 vulnerabilities
    HIGH: 29
    CRITICAL: 2

ඒක lab එක broken කියන එක නොවේ.

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

## Learning mode and strict mode

මෙම lab එක workflow configuration අනුව learning mode හෝ strict mode එකෙන් run වෙන්න පුළුවන්.

Learning mode එකේදී workflow findings report කරනවා, නමුත් immediately fail වෙන්නේ නැහැ.

Strict mode එකේදී selected severity levels හමු වුණොත් workflow එක fail වෙන්න පුළුවන්.

Strict mode carefulව use කරන්න.

Public base images වල vulnerabilities තිබිය හැකියි. ඒවා review කිරීම, patch කිරීම, හෝ documented risk acceptance අවශ්‍ය වෙන්න පුළුවන්.

## Important supply-chain note

Security tools ද dependencies වෙනවා.

Action versions carefully pin කරන්න සහ upstream project security advisories review කරන්න.

Stronger production-style security සඳහා actions trusted commit SHAs වලට pin කරන්න සහ CI/CD dependency compromise එකක් සැක නම් secrets rotate කරන්න.

## Trivy notices

Trivy මෙවැනි notices print කරන්න පුළුවන්:

    A newer Trivy version is available
    VEX notice

මේවා informational.

ඒවා හැමවිටම workflow failed කියන්නේ නැහැ.

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

### Workflow does not appear in the Actions tab

Workflow file එක root GitHub Actions folder එකේ තියෙනවද verify කරන්න:

    .github/workflows/devsecops-checks.yaml

Lab folder එකේ workflow template එක තිබීම පමණක් ප්‍රමාණවත් නැහැ.

GitHub Actions run කරන්නේ මේ path එක යටතේ තියෙන workflow files පමණයි:

    .github/workflows/

### Workflow is not triggered by push

Workflow එක `main` branch එකට push කරන විට run වෙන්නේ මේ paths change වුණොත් පමණයි:

    labs/practitioner/02-github-actions-devsecops/**
    .github/workflows/devsecops-checks.yaml

මෙහෙම manually run කරන්නත් පුළුවන්:

    Actions
    GitHub Actions DevSecOps Checks
    Run workflow

### Required file validation failed

`validate` job එක fail වුණොත්, workflow expect කරන files check කරන්න:

    labs/practitioner/02-github-actions-devsecops/app/Dockerfile
    labs/practitioner/02-github-actions-devsecops/k8s/namespace.yaml
    labs/practitioner/02-github-actions-devsecops/k8s/deployment.yaml
    labs/practitioner/02-github-actions-devsecops/k8s/service.yaml

ඒ folders ඔයාගේ repository එකේ තියෙනවද බලන්න.

### Trivy reports vulnerabilities

Learning labs වල මෙය බොහෝ විට expected.

Severity, package name, installed version, fixed version, සහ vulnerability description කියවන්න.

Finding එක pipeline block කළ යුතුද decide කරන්න.

### Docker build failed

`build_image` job logs check කරන්න.

Dockerfile එක තියෙනවද verify කරන්න:

    labs/practitioner/02-github-actions-devsecops/app/Dockerfile

### No AKS resources were created

මෙය expected.

මෙම lab එක scan-only සහ AKS වලට deploy කරන්නේ නැහැ.

## Cleanup

මෙම lab එක AKS resources create කරන්නේ නැහැ.

මෙම lab එක registry එකකට images push කරන්නේ නැහැ.

Kubernetes හෝ ACR cleanup අවශ්‍ය නැහැ.

Workflow එක මෙම lab එකට විතරක් copy කළා නම්, root GitHub Actions folder එකෙන් remove කරන්න:

    rm -f .github/workflows/devsecops-checks.yaml

Workflow template එක මෙතනින් delete කරන්න එපා:

    labs/practitioner/02-github-actions-devsecops/github-actions/

Workflow එක active තබාගන්න අවශ්‍ය නැත්නම්, cleanup change එක ඔයාගේ repository එකට commit සහ push කරන්න:

    git add .github/workflows/devsecops-checks.yaml
    git commit -m "Remove GitHub Actions DevSecOps checks workflow"
    git push

File එක already removed නම් `git add` වෙනුවට මේක අවශ්‍ය වෙන්න පුළුවන්:

    git add -u .github/workflows/devsecops-checks.yaml

## Security cleanup

මෙම lab එක Azure credentials හෝ registry credentials use කරන්නේ නැහැ.

Experiment කරන අතරතුර temporary secrets add කළා නම්, ඒවා remove හෝ rotate කරන්න.

Secrets Git වලට commit කරන්න එපා.

Production සඳහා prefer කරන්න:

- Least privilege permissions
- Cloud access සඳහා OIDC federation
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code

## Important note

මෙය learning lab එකක්.

මෙම lab එක cloud deployment credentials නැතුව GitHub Actions තුළ DevSecOps scanning teach කරනවා.

Production DevSecOps workflow එකක් scanning, approvals, least privilege identity, SBOM generation, image signing, සහ policy validation combine කළ යුතුයි.
