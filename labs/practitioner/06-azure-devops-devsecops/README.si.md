# Practitioner Lab 06 - Azure DevOps DevSecOps Checks

මෙම lab එකෙන් Azure DevOps learning flow එකට DevSecOps security checks add කරන විදිය ඉගෙන ගන්නවා.

මෙය scan-only lab එකක්. ඒ කියන්නේ මෙම lab එක AKS deploy කරන්නේ නැහැ, ACR push කරන්නේ නැහැ, Azure login වෙන්නේ නැහැ.

මෙම lab එකට අවශ්‍ය නැති දේවල්:

- Azure credentials
- Registry credentials
- Paid security scanning accounts
- AKS access
- Azure DevOps service connections
- CI/CD variables

මෙය Lab 05 replace කරන්නේ නැහැ.

Lab 05 teaches:

    Validate -> BuildPush -> Deploy -> Verify

This lab teaches:

    Validate -> ScanConfig -> BuildImages -> ScanImages -> Summary

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- Azure DevOps Pipelines වලට security checks add කරන විදිය
- Dockerfiles සහ Kubernetes YAML scan කරන විදිය
- Azure Pipelines වල local container images build කරන විදිය
- Local container images scan කරන විදිය
- Vulnerability findings කියවන විදිය
- Learning mode සහ strict security gate mode අතර වෙනස

## Tool used

මෙම lab එක Trivy use කරනවා.

Trivy open-source security scanner එකක්. Paid security scanning account එකක් නැතුව learning purpose එකට run කරන්න පුළුවන්.

Trivy scan කරන්න පුළුවන් දේවල්:

- Container images
- Filesystems
- Kubernetes configuration
- Infrastructure configuration

## App used

මෙම lab එක 3-tier Node.js sample app එකට run කරන්න design කරලා තියෙනවා:

    https://github.com/andrewferdinandus/3-tier-nodeapp

Expected app repository structure:

    backend/
    frontend/
    k8s/
    azure-pipelines-devsecops.yml

## Pipeline file

මෙම platform repository එකේ template එක තියෙන්නේ:

    labs/practitioner/06-azure-devops-devsecops/azure-pipelines/azure-pipelines-devsecops.yml

ඒක app repository root එකට copy කරන්න:

    azure-pipelines-devsecops.yml

ඊට පස්සේ Azure DevOps වල ඒ YAML file එක use කරලා new pipeline එකක් create කරන්න.

## Pipeline stages

Pipeline stages:

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

මෙම flow එකෙන් DevSecOps checks deployment වලින් වෙනම තේරුම් ගන්න ලේසි වෙනවා.

## Learning mode

මෙම lab එක default එකෙන් learning mode වල run වෙනවා.

Learning mode කියන්නේ Trivy findings report කරනවා, නමුත් pipeline එක fail කරන්නේ නැහැ.

Pipeline එක use කරන්නේ:

    --exit-code 0

## Strict security gate mode

Scan output එක තේරුම් ගත්තට පස්සේ, HIGH හෝ CRITICAL vulnerabilities තිබුණොත් pipeline fail කරන්න පුළුවන්.

Change කරන්න:

    --exit-code 0

to:

    --exit-code 1

Strict mode carefulව use කරන්න. Public base images වල vulnerabilities තිබිය හැකියි. ඒවා review කිරීම, patch කිරීම, හෝ risk acceptance අවශ්‍ය වෙන්න පුළුවන්.

## Why this lab does not use variables or secrets

මෙම lab එක intentionally scan-only DevSecOps lab එකක් විදියට design කරලා තියෙනවා.

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

- Log in to Azure
- Push images to ACR
- Get AKS credentials
- Run kubectl against the cluster

මෙම DevSecOps lab එක ඒ actions කරන්නේ නැහැ.

ඒ වෙනුවට මෙය කරන්නේ:

- Validates files
- Scans Dockerfiles and Kubernetes YAML
- Builds container images locally on the pipeline agent
- Scans the local container images
- Shows a summary

මෙයින් lab එක safe සහ beginner-friendly වෙනවා.

Learnersලාට cloud credentials, registry access, AKS permissions, හෝ paid security tools නැතුව DevSecOps concepts practice කරන්න පුළුවන්.

## Scan-only lab vs production pipeline

මෙම lab එක security scanning deployment වලින් separate කරනවා, learning goal එක clear තියාගන්න.

Lab 05 answers:

    How do I deploy an app to AKS with Azure DevOps?

Lab 06 answers:

    How do I add DevSecOps checks to Azure DevOps?

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
- Strict scan gates for protected branches

## Why this lab does not deploy

මෙම lab එක security checks වලට focus කරනවා.

Deployment flow එක Lab 05 වල cover කරලා තියෙනවා.

Later advanced lab එකක DevSecOps checks deployment approvals, service connections, OIDC, සහ environment gates එක්ක combine කරන්න පුළුවන්.

## Expected result

Pipeline එකෙන් expected result:

- Validate required files
- Scan Dockerfiles and Kubernetes YAML
- Build backend and frontend images locally
- Scan backend and frontend images
- Report vulnerabilities in learning mode
- Finish without deploying anything to AKS

## Common findings

Node හෝ NGINX වගේ base images scan කරන විට vulnerabilities report වෙන්න පුළුවන්.

මෙය හැමවිටම lab එක broken කියන එක නෙවෙයි.

Real DevSecOps workflows වල findings review කරලා next action decide කරනවා.

Possible actions:

- Use newer base images
- Use smaller base images
- Rebuild after upstream patches are available
- Change base image family
- Document accepted risk
- Fail only on selected severity levels
- Use strict gates on production branches

## Cleanup

මෙම workflow එක AKS වලට deploy කරන්නේ නැහැ.

ඒ නිසා Kubernetes cleanup අවශ්‍ය නැහැ.

Testing ඉවර වුණාම local හෝ pipeline image artifacts delete කරන්න පුළුවන්.

## Important note

මෙය learning lab එකක්.

Production DevSecOps pipelines වලදී consider කරන්න:

- Service connections
- OIDC or federated credentials
- Least privilege permissions
- Branch protection
- Environment approvals
- Dependency review
- Secret scanning
- SBOM generation
- Signed images
- Policy as code
