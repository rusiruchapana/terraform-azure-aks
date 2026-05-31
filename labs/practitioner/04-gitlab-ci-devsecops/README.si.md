# Practitioner Lab 04 - GitLab CI/CD DevSecOps Checks

මෙම lab එකෙන් GitLab CI/CD pipeline එකකට DevSecOps security checks add කරන විදිය ඉගෙන ගන්නවා.

මෙය scan-only lab එකක්. ඒ කියන්නේ මෙම lab එක AKS deploy කරන්නේ නැහැ, registry push කරන්නේ නැහැ, Azure login වෙන්නේ නැහැ.

මෙය Lab 03 replace කරන්නේ නැහැ.

Lab 03 teaches:

    validate -> build_push -> deploy -> verify

This lab teaches:

    validate -> scan_config -> build_image -> scan_image -> summary

මෙම lab එකට අවශ්‍ය නැති දේවල්:

- Azure credentials
- Registry credentials
- AKS access
- GitLab paid security features
- CI/CD variables

Goal එක GitLab CI/CD තුළ security scanning flow එක තේරුම් ගන්න එක.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- GitLab CI/CD security stages
- Dockerfile scanning
- Kubernetes manifest scanning
- Local container image scanning
- Security checks before deployment
- Why DevSecOps belongs in CI/CD

## Tool used

මෙම lab එක Trivy use කරනවා.

Trivy open-source security scanner එකක්. Paid GitLab security features නැතුව learning purpose එකට run කරන්න පුළුවන්.

Trivy scan කරන්න පුළුවන් දේවල්:

- Container images
- Filesystems
- Dockerfiles
- Kubernetes YAML / configuration
- Infrastructure configuration

## Why this lab does not deploy

මෙම lab එක security checks වලට focus කරනවා.

Deployment flow එක Lab 03 වල cover කරලා තියෙනවා.

මෙම lab එක deploy නොකරන්නේ learning goal එක clean තියාගන්න:

- Azure login අවශ්‍ය නැහැ
- Registry credentials අවශ්‍ය නැහැ
- AKS permissions අවශ්‍ය නැහැ
- CI/CD variables අවශ්‍ය නැහැ

Production pipeline එකකදී scan + build + push + deploy combine කරන්න පුළුවන්. නමුත් learning lab එකක් විදියට scan-only flow එක security concepts වෙනම තේරුම් ගන්න හොඳයි.

## GitLab project structure

Lab 03 වල use කළ GitLab project එකම use කරන්න පුළුවන්.

Expected structure:

    app/
      Dockerfile
      index.html

    k8s/
      namespace.yaml
      deployment.yaml
      service.yaml

    .gitlab-ci.yml

මෙම lab එකට Azure/GitLab variables add කරන්න අවශ්‍ය නැහැ.

## Copy the DevSecOps pipeline

DevSecOps pipeline template එක තියෙන්නේ:

    labs/practitioner/04-gitlab-ci-devsecops/gitlab-ci/.gitlab-ci.yml

ඒක GitLab project root එකට copy කරන්න:

    .gitlab-ci.yml

මෙය Lab 03 deploy pipeline එක temporary replace කරලා DevSecOps checks test කරන්න use කරන්න පුළුවන්.

## Pipeline stages

Pipeline stages:

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

Stage meaning:

- `validate` required files තියෙනවද බලනවා
- `scan_config` Dockerfile සහ Kubernetes YAML scan කරනවා
- `build_image` local Docker image එකක් build කරනවා
- `scan_image` built image එක scan කරනවා
- `summary` result එක explain කරනවා

## Learning mode

මෙම lab එක default එකෙන් learning mode වල run වෙනවා.

Learning mode කියන්නේ Trivy findings report කරනවා, නමුත් pipeline එක fail කරන්නේ නැහැ.

Pipeline එක use කරන්නේ:

    --exit-code 0

මෙම mode එක beginnersලාට findings කියවලා තේරුම් ගන්න හොඳයි.

## Strict security gate mode

Scan output එක තේරුම් ගත්තට පස්සේ, HIGH හෝ CRITICAL vulnerabilities තිබුණොත් pipeline fail කරන්න strict mode use කරන්න පුළුවන්.

Change කරන්න:

    --exit-code 0

to:

    --exit-code 1

Strict mode carefulව use කරන්න. Public base images වල vulnerabilities තිබිය හැකියි. ඒවා review කරලා fix, update, risk acceptance වගේ decision ගන්න ඕන.

## Example scan result

Image scan එකකදී vulnerabilities report වෙන්න පුළුවන්.

Example:

    Total: 31
    HIGH: 29
    CRITICAL: 2

මෙය lab එක broken කියන එක නෙවෙයි.

මෙයින් කියවෙන්නේ scanner එක image layers තුළ known vulnerabilities detect කළා කියන එක.

Real DevSecOps workflow එකකදී findings review කරලා action decide කරනවා.

Possible actions:

- Newer base image එකක් use කිරීම
- Smaller base image එකක් use කිරීම
- Upstream patches available වෙනකම් rebuild කිරීම
- Base image family change කිරීම
- Accepted risk document කිරීම
- Selected severity levels වලට විතරක් fail කිරීම
- Production branches වල strict gates use කිරීම

## Cleanup

මෙම workflow එක AKS වලට deploy කරන්නේ නැහැ.

ඒ නිසා Kubernetes cleanup අවශ්‍ය නැහැ.

GitLab pipeline artifacts/images temporary නම් GitLab retention policy අනුව cleanup වෙයි.

## Important note

මෙම lab එක learning-purpose DevSecOps example එකක්.

Production DevSecOps pipelines වලදී consider කරන්න:

- Least privilege permissions
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code
- Documented exception process
