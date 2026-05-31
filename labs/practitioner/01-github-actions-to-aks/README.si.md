# Practitioner Lab 01 - GitHub Actions to AKS

මෙම lab එකෙන් GitHub Actions workflow එකක් use කරලා container image එකක් build කරලා registry එකට push කරලා AKS cluster එකට deploy කරන flow එක ඉගෙන ගන්නවා.

මෙය practitioner-level lab එකක්. Beginner labs වල Kubernetes basics practice කළාට පස්සේ CI/CD pipeline එකක් හරහා deployment automate කරන විදිය මෙතනින් ඉගෙන ගන්නවා.

## What you will learn

මෙම lab එකෙන් ඔබට මේ දේවල් ඉගෙන ගන්න පුළුවන්:

- GitHub Actions workflow structure එක
- Pipeline jobs separate කරන විදිය
- Docker image build කරන විදිය
- Container registry එකට image push කරන විදිය
- AKS cluster එකට deploy කරන විදිය
- Kubernetes rollout verify කරන විදිය
- Pipeline variables/secrets use කරන basic pattern එක

## Learning-first example

මෙම lab එක learning-first example එකක්.

Goal එක production-ready enterprise pipeline එකක් හදන එක නෙවෙයි. Goal එක GitHub Actions CI/CD flow එක තේරුම් ගන්න එක.

මෙම lab එකෙන් පස්සේ ඔබට ඔබගේ real application, registry, environments, approvals, සහ security rules අනුව pipeline එක improve කරන්න පුළුවන්.

## Authentication note

මෙම lab එක Azure login සහ registry login සඳහා service principal credentials use කරනවා.

Learning labs වලට මෙය simpleයි. Production වලදී GitHub OIDC / federated identity වගේ secretless authentication pattern එකක් prefer කරන්න.

Secrets code එකට commit කරන්න එපා. GitHub repository secrets වලට විතරක් දාන්න.

## Supported registry paths

මෙම lab එක registry paths කිහිපයක් support කරනවා:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- Other private registries

For ACR, `REGISTRY_LOGIN_SERVER` මේ වගේ වෙන්න පුළුවන්:

    myacr.azurecr.io

For Docker Hub:

    docker.io

For GHCR:

    ghcr.io

## Folder structure

Lab files structure එක:

    app/
      sample static web app and Dockerfile

    k8s/
      Kubernetes manifests

    github-actions/
      GitHub Actions workflow template

## Copy workflow into GitHub Actions path

GitHub Actions workflows මේ path එක යටතේ තියෙන්න ඕන:

    .github/workflows/

මෙම lab එක workflow template එක store කරලා තියෙන්නේ:

    labs/practitioner/01-github-actions-to-aks/github-actions/build-deploy-aks.yaml

ඒක copy කරන්න:

    .github/workflows/build-deploy-aks.yaml

Workflow file එක GitHub repo එකේ මේ path එකට copy කළාම GitHub Actions run වෙන්න පුළුවන්.

## Pipeline jobs

GitHub Actions වල `stages` වෙනුවට `jobs` කියන concept එක use වෙනවා.

මෙම lab එක workflow එක jobs හතරකට split කරනවා:

    validate
      |
      v
    build-and-push
      |
      v
    deploy
      |
      v
    verify

Separate jobs තියෙන්නේ ඇයි?

- CI/CD flow එක තේරුම් ගන්න ලේසි
- Pipeline fail වුණේ කොතැනද කියලා දකින්න ලේසි
- Real-world pipeline design එකට closer
- Everything one job එකකට දාන්න වඩා learning වලට හොඳයි

## Prepare Azure CI/CD variables

මෙම lab එක AKS වලට deploy කරනවා සහ image එක registry එකට push කරනවා.

Workflow run කරන්න කලින් required Azure සහ registry values shared guide එකෙන් සකස් කරන්න:

    ../../shared/azure-login-and-cicd-variables.md

Sinhala guide:

    ../../shared/azure-login-and-cicd-variables.si.md

## Required GitHub secrets

මෙම learning setup එකට GitHub repository secrets වලට මේ values configure කරන්න:

    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID
    AZURE_RESOURCE_GROUP
    AKS_CLUSTER_NAME
    REGISTRY_LOGIN_SERVER
    REGISTRY_USERNAME
    REGISTRY_PASSWORD

For ACR, `REGISTRY_LOGIN_SERVER` මේ වගේ වෙන්න පුළුවන්:

    myacr.azurecr.io

For Docker Hub:

    docker.io

For GHCR:

    ghcr.io

## Image tag

Workflow එක image build කරලා GitHub commit SHA එකෙන් tag කරනවා.

Example:

    myacr.azurecr.io/practitioner-github-actions:<commit-sha>

## Deployment method

Workflow එක කරන්නේ:

1. Builds and pushes the image
2. Gets AKS credentials
3. Applies the namespace
4. Replaces IMAGE_PLACEHOLDER with the new image tag
5. Applies the Deployment
6. Applies the Service
7. Verifies rollout

## Local manifest test

CI/CD run කරන්න කලින් `IMAGE_PLACEHOLDER` public image එකකින් replace කරලා Kubernetes manifests locally test කරන්න පුළුවන්.

Example:

    sed "s|IMAGE_PLACEHOLDER|nginx:1.27-alpine|g" \
      terraform-azure-aks/labs/practitioner/01-github-actions-to-aks/k8s/deployment.yaml \
      | kubectl apply -f -

Full local test:

    kubectl apply -f terraform-azure-aks/labs/practitioner/01-github-actions-to-aks/k8s/namespace.yaml

    sed "s|IMAGE_PLACEHOLDER|nginx:1.27-alpine|g" \
      terraform-azure-aks/labs/practitioner/01-github-actions-to-aks/k8s/deployment.yaml \
      | kubectl apply -f -

    kubectl apply -f terraform-azure-aks/labs/practitioner/01-github-actions-to-aks/k8s/service.yaml

Verify:

    kubectl get pods -n practitioner-github-actions
    kubectl rollout status deployment/github-actions-demo -n practitioner-github-actions

Port-forward:

    kubectl port-forward svc/github-actions-demo -n practitioner-github-actions 8084:80

Open:

    http://localhost:8084

## Cleanup

Lab resources cleanup කරන්න:

    kubectl delete namespace practitioner-github-actions

මෙයින් namespace එක තුළ තිබුණු Deployment, Service, Pod resources delete වෙනවා.

## Important note

මෙම lab එක learning-purpose CI/CD example එකක්.

Production pipeline එකකදී consider කරන්න:

- GitHub OIDC / federated credentials
- Least privilege permissions
- Protected branches
- Environment approvals
- Image scanning
- SBOM
- Signed images
- GitOps promotion
