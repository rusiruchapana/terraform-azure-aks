# GitOps Labs

මෙම document එකෙන් AKS DevOps Practice Platform එකේ GitOps learning path එක පැහැදිලි කරනවා.

## Purpose

GitOps මගින් Kubernetes deployments Git වලින් manage කරන ආකාරය තේරුම් ගන්න පුළුවන්.

GitOps වලදී Git repository එක cluster එකේ desired state එකේ source of truth වෙනවා.

## GitOps කියන්නේ මොකක්ද?

GitOps කියන්නේ Kubernetes manifests, Helm values, හෝ Kustomize overlays Git repository එකේ තියාගෙන deploy කරන model එකක්.

GitOps controller එක Git repository එක watch කරලා cluster එක Git state එකට match වෙන විදියට sync කරනවා.

High-level flow:

    Git repository
        |
        v
    Argo CD හෝ Flux
        |
        v
    AKS cluster

## Supported GitOps tools

මෙම project එක examples plan කරන tools:

- Argo CD
- Flux

Folders:

    gitops/argocd
    gitops/flux
    examples/gitops/argocd
    examples/gitops/flux

## CI/CD vs GitOps

CI/CD direct deployment:

    Pipeline
        |
        v
    kubectl apply
        |
        v
    AKS

GitOps deployment:

    Pipeline හෝ developer
        |
        v
    Update Git
        |
        v
    Argo CD හෝ Flux
        |
        v
    AKS

CI/CD direct deployment වලදී pipeline එක cluster එක change කරනවා.

GitOps වලදී pipeline එක Git change කරනවා, GitOps controller එක cluster එක change කරනවා.

## GitOps use කරන්නේ ඇයි?

GitOps useful වෙන හේතු:

- Git desired state store කරනවා
- Changes pull requests හරහා review කරන්න පුළුවන්
- Git history මගින් rollback කරන්න පුළුවන්
- Drift detect කරන්න පුළුවන්
- Cluster changes auditable වෙනවා
- dev, qa, prod promotion clear වෙනවා

## ඉගෙන ගැනීමට සකස් කළ examples

මෙම repository එකේ GitOps examples starter examples.

Beginnersලාට GitOps workflow එක තේරුම් ගන්න උදව් කරන්න මේවා design කරලා තියෙනවා.

ඔයා provided sample app එකට සීමා වෙන්න ඕන නැහැ.

Lab එක complete කළාට පස්සේ sample app එක වෙනුවට මේවා use කරලා බලන්න:

- ඔයාගේම application එක
- ඔයාගේම image එක
- ඔයාගේම Kubernetes manifests
- ඔයාගේම Helm chart එක
- ඔයාගේම Kustomize overlays
- ඔයාගේම promotion strategy එක

මෙම platform එක app-agnostic සහ GitOps-tool friendly.

## Repository GitOps structure

Repository එකේ තියෙන structure:

    gitops/
      argocd/
      flux/
      apps/
        dev/
        qa/
        prod/
      platform-addons/

Purpose:

- argocd: Argo CD bootstrap සහ app-of-apps examples
- flux: Flux bootstrap සහ Kustomization examples
- apps: applications desired state
- platform-addons: platform add-ons desired state

## Application desired state

Application manifests environment අනුව organize කරන්න පුළුවන්.

Example:

    gitops/apps/dev
    gitops/apps/qa
    gitops/apps/prod

Each environment එකේ තියෙන්න පුළුවන්:

- Deployment manifests
- Service manifests
- HTTPRoute manifests
- Helm values
- Kustomize overlays

## Platform add-ons desired state

Platform add-ons පස්සේ GitOps මගින් manage කරන්න පුළුවන්.

Examples:

- Gateway API resources
- Monitoring resources
- Secrets integrations
- External Secrets Operator
- CSI Driver configuration

Current platform add-ons learning සඳහා manually install කළා.

Future labs වලදී ඒවා GitOps-managed configuration එකකට move කරන්න පුළුවන්.

## dev to qa to prod promotion

Common GitOps promotion flow:

    dev
     |
     v
    qa
     |
     v
    prod

Promotion කරන්න පුළුවන් ways:

- Image tags update කිරීම
- Environment folders අතර manifests copy කිරීම
- Kustomize overlays use කිරීම
- Helm values update කිරීම
- Pull requests open කිරීම
- Approval gates use කිරීම

## Image promotion

Common pattern එකක් තමයි same image digest හෝ tag එක environments අතර promote කිරීම.

Example:

    dev  -> my-app:v1.0.0
    qa   -> my-app:v1.0.0
    prod -> my-app:v1.0.0

Production-style workflows සඳහා immutable image tags හෝ image digests recommended.

## Argo CD learning path

Beginner Argo CD labs include කරන්න පුළුවන්:

1. Argo CD install කිරීම
2. Argo CD UI locally access කිරීම
3. Git repository connect කිරීම
4. Git වලින් app එකක් deploy කිරීම
5. Git manifest update කිරීම
6. Argo CD sync වෙන එක බලන්න
7. Git මගින් rollback කිරීම

Practitioner Argo CD labs include කරන්න පුළුවන්:

1. App-of-apps pattern
2. Multiple environments
3. Helm-based app deployment
4. Kustomize overlays
5. Sync policies
6. Health checks
7. Drift detection

Professional Argo CD labs include කරන්න පුළුවන්:

1. PR-based promotion
2. Approval gates
3. Multi-cluster patterns
4. RBAC
5. SSO
6. Notifications
7. Progressive delivery integration

## Flux learning path

Beginner Flux labs include කරන්න පුළුවන්:

1. Flux install කිරීම
2. Git repository එකෙන් Flux bootstrap කිරීම
3. Git වලින් app එකක් deploy කිරීම
4. Git manifest update කිරීම
5. Flux reconcile වෙන එක බලන්න
6. Git මගින් rollback කිරීම

Practitioner Flux labs include කරන්න පුළුවන්:

1. Kustomization resources
2. HelmRelease resources
3. Multiple environments
4. Image automation
5. Source controllers
6. Reconciliation troubleshooting

Professional Flux labs include කරන්න පුළුවන්:

1. Promotion workflows
2. Image update automation
3. Policy integration
4. Multi-cluster GitOps
5. Secret management integration
6. Progressive delivery integration

## Direct deployment vs GitOps handoff

CI/CD GitOps එක්ක තවම use කරන්න පුළුවන්.

Common professional pattern:

    CI/CD pipeline
        |
        v
    Build and push image
        |
        v
    Update image tag in Git
        |
        v
    Argo CD හෝ Flux AKS එකට sync කරනවා

Pipeline එක artifacts build කරනවා.

GitOps artifacts deploy කරනවා.

## Secrets and GitOps

Plain-text secrets Git එකට commit කරන්න එපා.

Secrets සඳහා මේ patterns use කරන්න:

- External Secrets Operator
- Secrets Store CSI Driver
- Sealed Secrets
- SOPS
- Azure Key Vault integration

Secrets labs වෙනම handle කරනවා.

## Beginner GitOps lab idea

Simple first lab එකක්:

1. Git වලින් sample app manifest deploy කරන්න
2. Service create කරන්න
3. HTTPRoute create කරන්න
4. Argo CD හෝ Flux සමඟ sync කරන්න
5. Git එකේ image tag change කරන්න
6. Rollout verify කරන්න
7. Git මගින් rollback කරන්න

## Practitioner GitOps lab idea

Practitioner lab එකක් include කරන්න පුළුවන්:

1. dev සහ qa folders
2. Environment එකකට වෙන image tags
3. Pull request-based promotion
4. Argo CD හෝ Flux sync verification
5. Drift detection සහ correction

## Professional GitOps lab idea

Professional lab එකක් include කරන්න පුළුවන්:

1. dev, qa, prod overlays
2. prod සඳහා approval process
3. Immutable image promotion
4. Policy checks
5. Progressive delivery
6. Observability checks
7. Rollback strategy

## Important note

GitOps labs learning examples.

මේවා strict production templates නෙවෙයි.

මෙම flow එක තේරුම් ගන්න use කරන්න:

    Git desired state -> GitOps controller -> AKS

Flow එක තේරුම් ගත්තට පස්සේ ඔයාගේම application, team, සහ release process එකට ගැලපෙන විදියට structure එක customize කරන්න.
