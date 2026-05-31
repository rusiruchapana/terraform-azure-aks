# CI/CD Labs

මෙම document එකෙන් AKS DevOps Practice Platform එකේ CI/CD learning path එක පැහැදිලි කරනවා.


## Current lab order

Current hands-on lab order එක maintain කරන්නේ මෙතන:

    ../../labs/README.md

මෙම document එක CI/CD concepts සහ learning goals පැහැදිලි කරනවා. Exact lab sequence එක labs index එකේ update කරන්න.

## Lab order source of truth

Current hands-on lab order එක maintain කරන්නේ මෙතන:

    ../../labs/README.md

මෙම document එක CI/CD concepts සහ learning goals පැහැදිලි කරනවා. Exact lab sequence එක labs index එකේ update කරන්න.

## Purpose

CI/CD labs වල goal එක usersලාට applications build කරලා, container registry එකකට push කරලා, AKS එකට deploy කරන workflow එක තේරුම් ගන්න උදව් කිරීම.

මෙම labs learning-first examples.

Beginnersලාට full workflow එක තේරුම් ගන්න ලේසි වෙන්න මේවා intentionally simple කරලා තියෙනවා.

## ඉගෙන ගැනීමට සකස් කළ examples

මෙම repository එකේ labs starter examples.

Beginnersලාට AKS මත DevOps workflows තේරුම් ගන්න උදව් කරන්න මේවා design කරලා තියෙනවා.

ඔයා provided examples වලට සීමා වෙන්න ඕන නැහැ.

Lab එකක් complete කළාට පස්සේ sample app එක වෙනුවට මේවා use කරලා බලන්න:

- ඔයාගේම application එක
- ඔයාගේම Dockerfile එක
- ඔයාගේම container registry එක
- ඔයාගේම Kubernetes manifests
- ඔයාගේම deployment strategy එක

මෙම platform එක:

- App-agnostic
- Registry-agnostic
- CI/CD tool-agnostic

## Supported CI/CD tools

මෙම project එක examples plan කරන tools:

- GitHub Actions
- GitLab CI/CD
- Azure DevOps
- Jenkins

Example folders:

    examples/cicd/github-actions
    examples/cicd/gitlab-ci
    examples/cicd/azure-devops
    examples/cicd/jenkins

## Common CI/CD flow

Most CI/CD pipelines follow කරන basic flow එක:

    Source code
        |
        v
    CI/CD pipeline
        |
        v
    Build container image
        |
        v
    Push image to registry
        |
        v
    Deploy to AKS
        |
        v
    Verify rollout

## Common pipeline stages

Typical pipeline එකක් include කරන stages:

1. Source code checkout කිරීම
2. Runtime හෝ build tools setup කිරීම
3. Application build කිරීම
4. Tests run කිරීම
5. Docker image build කිරීම
6. Container registry login කිරීම
7. Image push කිරීම
8. Azure හෝ Kubernetes authenticate කිරීම
9. Manifests deploy කිරීම හෝ Helm upgrade කිරීම
10. Rollout verify කිරීම

## Registry options

ඔයාට different registries use කරන්න පුළුවන්:

- Azure Container Registry
- Docker Hub
- GitHub Container Registry
- GitLab Container Registry
- Quay
- imagePullSecret සමඟ private registry එකක්

## ACR-based pipeline

ACR enabled නම්:

    enable_acr = true

Pipeline එකට පුළුවන්:

1. Image build කරන්න
2. Image ACR එකට push කරන්න
3. Image AKS එකට deploy කරන්න

AcrPull permission configured නම් AKS ට ACR වලින් image pull කරන්න පුළුවන්.

## External registry pipeline

Docker Hub, GHCR, GitLab Container Registry, හෝ වෙන registry එකක් use කරනවා නම්:

- Public images වලට secret අවශ්‍ය නොවෙන්න පුළුවන්
- Private images වලට imagePullSecret ඕන
- Pipeline එක image එක chosen registry එකට push කරන්න ඕන
- Kubernetes manifests ඒ image එක reference කරන්න ඕන

## Deployment methods

CI/CD pipelines AKS එකට deploy කරන්න different methods use කරන්න පුළුවන්.

Common options:

- kubectl apply
- kubectl set image
- Helm upgrade
- Kustomize
- GitOps handoff

Beginner labs සඳහා kubectl apply easiest.

Practitioner සහ professional labs සඳහා Helm, Kustomize, හෝ GitOps handoff better වෙන්න පුළුවන්.

## Direct CI/CD deployment

Direct deployment කියන්නේ pipeline එක cluster එක update කරනවා.

Example flow:

    CI/CD pipeline
        |
        v
    kubectl apply
        |
        v
    AKS

මේක simple සහ learning සඳහා හොඳයි.

## GitOps handoff

GitOps handoff කියන්නේ pipeline එක directly cluster එක update නොකර Git update කරනවා.

Example flow:

    CI/CD pipeline
        |
        v
    Build and push image
        |
        v
    Update manifest in Git
        |
        v
    Argo CD හෝ Flux AKS එකට sync කරනවා

මේ pattern එක professional workflows සඳහා useful.

## Environment promotion

Repository එකේ environment templates තියෙනවා:

- dev
- qa
- prod

Common promotion flow:

    dev
     |
     v
    qa
     |
     v
    prod

Learning සඳහා dev වලින් පටන් ගන්න.

පස්සේ image tags හෝ manifests dev සිට qa සහ prod වලට promote කරන එක practice කරන්න.

## Beginner lab ideas

Beginner labs basics තේරුම් ගන්න focus කරන්න ඕන:

1. Docker Hub public image deploy කිරීම
2. Simple Docker image build කිරීම
3. Image ACR එකට push කිරීම
4. Image AKS එකට deploy කිරීම
5. Gateway API හරහා app expose කිරීම
6. Rollout verify කිරීම
7. ImagePullBackOff troubleshoot කිරීම

## Practitioner lab ideas

Practitioner labs real CI/CD workflows focus කරන්න ඕන:

1. GitHub Actions pipeline to AKS
2. GitLab CI/CD pipeline to AKS
3. Azure DevOps pipeline to AKS
4. Jenkins pipeline to AKS
5. Build and push to ACR
6. Build and push to GHCR හෝ Docker Hub
7. Variable image tags සමඟ Kubernetes manifests use කිරීම
8. Rollout verification add කිරීම

## Professional lab ideas

Professional labs include කරන්න පුළුවන්:

1. Multi-environment promotion
2. Pull request-based deployment
3. Approval gates
4. Image scanning
5. Policy checks
6. Helm-based deployments
7. GitOps handoff
8. Rollback workflows
9. Blue/green deployment
10. Canary deployment

## Secrets in CI/CD

Pipeline files වල credentials hardcode කරන්න එපා.

CI/CD tool එකේ secret store use කරන්න.

Examples:

- GitHub Actions Secrets
- GitLab CI/CD Variables
- Azure DevOps Variable Groups
- Jenkins Credentials

Common secrets:

- Azure credentials
- Registry username/password
- Kubernetes config
- Service principal values

Azure-native workflows සඳහා පුළුවන් නම් federated identity හෝ workload identity prefer කරන්න.

## Recommended first CI/CD lab

Simplest path එකෙන් පටන් ගන්න:

1. Sample app එකක් use කරන්න
2. Docker image build කරන්න
3. Image ACR එකට push කරන්න
4. kubectl use කරලා AKS එකට deploy කරන්න
5. kubectl rollout status වලින් verify කරන්න
6. Gateway API හරහා access කරන්න

ඊට පස්සේ sample app එක වෙනුවට ඔයාගේම application එක use කරන්න.

## Important note

මෙම labs strict production templates නෙවෙයි.

මේවා learning labs.

මෙම flow එක තේරුම් ගන්න use කරන්න:

    source code -> container image -> registry -> AKS deployment

Flow එක තේරුම් ගත්තට පස්සේ ඔයාගේම application එකට සහ organization එකට ගැලපෙන විදියට pipeline එක customize කරන්න.
