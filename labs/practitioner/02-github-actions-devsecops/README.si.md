# Practitioner Lab 02 - GitHub Actions DevSecOps Checks

මෙම lab එකෙන් GitHub Actions workflow එකකට DevSecOps security checks add කරන විදිය ඉගෙන ගන්නවා.

මෙය scan-only lab එකක්. ඒ කියන්නේ මෙම lab එක AKS deploy කරන්නේ නැහැ, ACR push කරන්නේ නැහැ, Azure login වෙන්නේ නැහැ.

මෙම lab එකට අවශ්‍ය නැති දේවල්:

- Azure credentials
- Registry credentials
- AKS access
- CI/CD variables
- Paid security scanning account

Goal එක security scanning flow එක තේරුම් ගන්න එක.

මෙය Lab 01 replace කරන්නේ නැහැ.

Lab 01 teaches:

    build -> push -> deploy -> verify

This lab teaches:

    validate -> scan files -> scan config -> build image -> scan image


## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- GitHub Actions වල security scan stages add කරන විදිය
- Repository files scan කරන විදිය
- Dockerfile සහ Kubernetes YAML scan කරන විදිය
- Local Docker image build කරලා scan කරන විදිය
- Vulnerability scan output කියවන විදිය
- Learning mode සහ strict security gate mode අතර වෙනස

## Tool used

මෙම lab එක Trivy use කරනවා.

Trivy open-source security scanner එකක්. Learning labs වලට හොඳයි, මොකද paid account එකක් නැතුව run කරන්න පුළුවන්.

Trivy scan කරන්න පුළුවන් දේවල්:

- Container images
- Filesystems
- Dockerfiles
- Kubernetes YAML / configuration
- Infrastructure configuration

## Important supply-chain note

Security scanner එකක් finding එකක් දුන්නා කියලා app එක හැමවිටම broken කියන එක නෙවෙයි.

Findings review කරන්න ඕන:

- Severity එක
- Fix available ද
- Package එක actually use වෙනවද
- Base image එකෙන් ආපු vulnerability එකක්ද
- Production risk එකක්ද learning lab finding එකක්ද

DevSecOps කියන්නේ scanner එක run කරන එක විතරක් නෙවෙයි. Findings understand කරලා decision ගන්න එකත් DevSecOps වල කොටසක්.

## Folder structure

Lab files structure එක:

    app/
      sample app and Dockerfile

    k8s/
      Kubernetes manifests

    github-actions/
      GitHub Actions DevSecOps workflow template

මෙම lab එක deployment lab එකක් නෙවෙයි. Files scan කිරීම සහ image scan කිරීම focus එක.

## Workflow file

Workflow template එක තියෙන්නේ:

    labs/practitioner/02-github-actions-devsecops/github-actions/devsecops-checks.yaml

GitHub repo root එකේ copy කරන්න:

    .github/workflows/devsecops-checks.yaml

Workflow file එක GitHub repo එකට push කළාම GitHub Actions run එක start වෙයි.

## Workflow jobs

මෙම workflow එක jobs කිහිපයකට split කරලා තියෙනවා:

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

Job meaning:

- `validate` required files තියෙනවද බලනවා
- `scan_filesystem` repository filesystem scan කරනවා
- `scan_config` Dockerfile සහ Kubernetes YAML scan කරනවා
- `build_image` local Docker image එකක් build කරනවා
- `scan_image` built image එක scan කරනවා
- `summary` lab result එක summarize කරනවා

## Why this lab does not deploy

මෙම lab එක security checks වලට focus කරනවා.

Deployment flow එක Lab 01 වල cover කරලා තියෙනවා.

මෙම lab එක deploy නොකරන්නේ learning goal එක clean තියාගන්න:

- Azure login අවශ්‍ය නැහැ
- Registry credentials අවශ්‍ය නැහැ
- AKS permissions අවශ්‍ය නැහැ
- Pipeline variables අවශ්‍ය නැහැ

Production pipeline එකකදී scan + build + push + deploy combine කරන්න පුළුවන්. නමුත් beginner/practitioner learning වලට scan-only lab එක security concepts වෙනම තේරුම් ගන්න හොඳයි.

## Expected result

Workflow එකෙන් expected result:

- Required files validate වෙනවා
- Repository files scan වෙනවා
- Dockerfile සහ Kubernetes YAML scan වෙනවා
- Local Docker image build වෙනවා
- Image scan වෙනවා
- Learning mode නිසා findings තිබුණත් workflow pass වෙන්න පුළුවන්
- Fail if critical or high image vulnerabilities are found

Note:

මෙම lab එක learning mode වල run වෙනවා නම් scan findings report වෙලා pipeline fail නොවෙන්න පුළුවන්. Strict gate mode use කළොත් HIGH/CRITICAL findings තිබුණොත් pipeline fail කරන්න පුළුවන්.

## Example scan result

Image scan එකකදී vulnerabilities report වෙන්න පුළුවන්.

Example:

    Total: 31 vulnerabilities
    HIGH: 29
    CRITICAL: 2

මෙය lab එක broken කියන එක නෙවෙයි.

මෙයින් කියවෙන්නේ scanner එක image layers තුළ known vulnerabilities detect කළා කියන එක.

Real DevSecOps workflow එකකදී ඒ findings review කරලා decision ගන්නවා.

Possible actions:

- Newer base image එකක් use කිරීම
- Smaller base image එකක් use කිරීම
- Upstream patches available වෙනකම් rebuild කිරීම
- Base image family change කිරීම
- Accepted risk document කිරීම
- Selected severity levels වලට විතරක් fail කිරීම
- Production branches වල strict gates use කිරීම

## Trivy notices

Trivy output එකේ informational notices පේන්න පුළුවන්:

    A newer Trivy version is available
    VEX notice

මෙවැනි notices හැමවිටම workflow failure එකක් නෙවෙයි.

Focus කරන්න ඕන:

- Vulnerability severity
- Fix available ද
- Affected package use වෙනවද
- Lab mode learning ද production ද

## What to do if the image scan fails

Image scan fail වුණොත්:

- Scan output එක කියවන්න
- HIGH/CRITICAL findings බලන්න
- Fix available ද බලන්න
- Base image update කරන්න පුළුවන්ද බලන්න
- Finding එක false positive / non-exploitable ද බලන්න
- Accept risk only through a documented exception process

Learning lab එකක් නම්, first step එක findings understand කිරීම.

Production pipeline එකක් නම්, documented risk process එකක් නැතුව findings ignore කරන්න එපා.

## Cleanup

මෙම lab එක AKS වලට deploy කරන්නේ නැහැ.

ඒ නිසා Kubernetes cleanup අවශ්‍ය නැහැ.

GitHub Actions run artifacts/images temporary නම් GitHub Actions retention policy අනුව cleanup වෙයි.

## Important note

මෙම lab එක learning-purpose DevSecOps example එකක්.

Production DevSecOps pipelines වලදී consider කරන්න:

- Strict scan gates
- Branch protection
- Environment approvals
- SBOM generation
- Signed images
- Dependency review
- Secret scanning
- Policy as code
- Documented exception process
