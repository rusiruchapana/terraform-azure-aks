# Stage 17 - Pipeline Visibility and Release Flow Documentation

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි project එකේ complete pipeline flow එක learnerට clear වෙන විදිහට document කරනවා.

Stage 11 සිට Stage 16 දක්වා අපි pipelines කිහිපයක් හදාගත්තා.

ඒ pipelines එක repo එකක විතරක් නැහැ.

Pipelines තියෙන්නේ repos දෙකක:

    aks-capstone-store-app
    aks-capstone-gitops

ඒ නිසා learner කෙනෙක්ට මෙවැනි ප්‍රශ්න එන්න පුළුවන්:

    මුලින් run වෙන්නේ මොන pipeline එකද?
    ඊළඟට auto run වෙන්නේ මොකක්ද?
    GitOps pipeline එක app pipeline එකෙන් වෙනස් ඇයි?
    QA/Prod promote කරන්න බලන්න ඕන pipeline එක මොකක්ද?
    Release එක ඇත්තටම success ද කියලා final check කරන්නේ කොහොමද?

මෙම stage එකේදී ඒ confusion එක remove කරනවා.

## මේ stage එක වැදගත් ඇයි?

Project එක technically වැඩ කරනවා කියලා විතරක් ප්‍රමාණවත් නැහැ.

Learnerට සහ GitHub repo බලන employer කෙනෙක්ට flow එක තේරෙන්න ඕන.

Good project එකක් වන්නේ:

    pipelines run වෙනවා
    logs pass වෙනවා
    architecture clear
    responsibilities clear
    documentation clear

මෙම Stage 17 එක pipeline implementation stage එකක් නෙවෙයි.

මෙය pipeline visibility සහ learning experience improve කරන stage එකක්.

## Current stable pipeline state

Stage 17 පටන් ගන්න කලින් stable state එක:

    Dev release pipeline works
    GitOps validation pipeline works
    Dev end-to-end verification pipeline works
    QA/Prod promotion workflow works
    Dev/QA/Prod all Synced and Healthy
    QA/Prod services are ClusterIP
    MongoDB stability issue fixed

ඒ නිසා දැන් full pipeline flow document කරන්න safe.

Stage 16 ඉවර වෙන්න කලින් final pipeline doc එක ලිව්වා නම් ඒක outdated වෙන්න තිබුණා.

දැන් Dev -> QA -> Prod flow complete නිසා final pipeline flow meaningful.

## Repositories overview

මෙම capstone project එකේ pipeline responsibilities repos කිහිපයකට බෙදා ඇත.

### App repo

Repo:

    aks-capstone-store-app

මෙම repo එකේ තියෙන්නේ:

    application source code
    Dockerfile
    app build workflow
    Dev deployment trigger workflow
    Dev release verification workflow

App repo pipelines mainly answer කරන්නේ:

    image build වෙනවද?
    app source scan pass ද?
    image scan pass ද?
    image ACR එකට push වුණාද?
    Dev GitOps image tag update වුණාද?
    Dev release end-to-end healthy ද?

### GitOps repo

Repo:

    aks-capstone-gitops

මෙම repo එකේ තියෙන්නේ:

    Kubernetes manifests
    Kustomize base
    Dev/QA/Prod overlays
    Argo CD Applications
    GitOps validation workflow
    QA/Prod promotion workflow

GitOps repo pipelines mainly answer කරන්නේ:

    Kubernetes manifests valid ද?
    Kustomize render වෙනවද?
    kubeconform validation pass ද?
    QA/Prod overlay image tag update කළාද?
    promotion commit push වුණාද?

### Terraform/platform repo

Repo:

    terraform-azure-aks

මෙම repo එකේ තියෙන්නේ:

    Terraform platform code
    AKS platform setup
    learning guides
    capstone stage documentation

මෙම repo එකේ මෙම guide එක තියෙනවා.

## Why pipelines are split across repos

Pipelines repos දෙකක තියෙන්නේ project එක confuse කරන්න නෙවෙයි.

ඒක production-style separation එකක්.

App repo concern එක:

    app code
    image build
    image scan
    image publish

GitOps repo concern එක:

    Kubernetes desired state
    environment overlays
    manifest validation
    promotion

Argo CD concern එක:

    GitOps desired state cluster එකට sync කිරීම

මෙම separation එකෙන් ownership clear වෙනවා.

App developer app repo එකේ වැඩ කරනවා.

Platform/GitOps owner GitOps repo එකේ deployment desired state manage කරනවා.

## Main release flow

Full release flow එක මෙහෙමයි:

    App repo pipeline
        -> build and scan image
        -> push image to ACR
        -> update GitOps Dev overlay

    GitOps validation pipeline
        -> validate YAML
        -> render Kustomize
        -> validate Kubernetes schemas

    Argo CD
        -> sync Dev environment

    Dev verification pipeline
        -> verify ACR
        -> verify GitOps
        -> verify Argo CD
        -> verify AKS
        -> verify Gateway

    Promotion workflow
        -> promote same image tag to QA or Prod

    GitOps validation pipeline
        -> validate promoted GitOps change

    Argo CD
        -> sync QA or Prod

## Pipeline map

Full pipeline map:

    1. Build store-front and deploy Dev via GitOps
    2. Validate GitOps manifests
    3. Argo CD Dev sync
    4. Verify Dev release end-to-end
    5. Promote store-front image
    6. Validate GitOps manifests again
    7. Argo CD QA/Prod sync

## Pipeline 1 - App build and Dev GitOps update

Repo:

    aks-capstone-store-app

Workflow:

    Build store-front and deploy Dev via GitOps

Trigger:

    Manual workflow_dispatch

Main input:

    image_tag

Example:

    stage13-v1

Purpose:

    Build store-front image
    Run DevSecOps scans
    Push image to ACR
    Update GitOps Dev image tag

This is the first pipeline user normally runs for a new app release.

## Pipeline 1 steps

This workflow includes steps like:

    Secret scan with Gitleaks
    Source/dependency scan with Trivy
    Azure login with OIDC
    ACR login
    Docker Buildx setup
    Build and push image
    Image scan with Trivy
    Verify image tag in ACR
    Checkout GitOps repo
    Update Dev image tag
    Commit and push GitOps change

This pipeline ends after GitOps repo update is pushed.

It does not directly deploy to AKS.

Argo CD deploys after GitOps update.

## Pipeline 1 output

Expected result:

    image pushed to ACR
    GitOps repo Dev overlay updated
    GitOps commit created
    workflow success

Example image:

    <acr-login-server>/store-front:<image-tag>

## Pipeline 2 - GitOps manifest validation

Repo:

    aks-capstone-gitops

Workflow:

    Validate GitOps manifests

Trigger:

    Automatic on push to main
    Automatic on pull request to main
    Manual workflow_dispatch

Purpose:

    Validate GitOps repo changes before Argo CD relies on them

This workflow auto-runs after Pipeline 1 updates GitOps repo.

It also auto-runs after QA/Prod promotion workflow updates GitOps repo.

## Pipeline 2 steps

This workflow checks:

    YAML syntax with PyYAML
    Kustomize render
    Kubernetes schema validation with kubeconform

Validation flow:

    Checkout GitOps repo
        -> Install PyYAML
        -> Install kubeconform
        -> Validate YAML syntax
        -> Render Kustomize base
        -> Validate rendered manifests

## Pipeline 2 output

Expected result:

    YAML valid
    Kustomize render valid
    kubeconform valid
    workflow success

If this workflow fails, GitOps change is risky.

Do not assume release is safe until this validation passes.

## Argo CD Dev sync

Repo:

    not a GitHub repo workflow

System:

    Argo CD running inside AKS

Application:

    capstone-store-dev

Trigger:

    automatic sync after GitOps desired state changes

Purpose:

    Deploy GitOps desired state into capstone-dev namespace

Argo CD watches:

    aks-capstone-gitops
    apps/capstone-store/overlays/dev

When Dev overlay changes, Argo CD syncs Dev.

## Argo CD Dev verification

Check:

    kubectl get application capstone-store-dev -n argocd

Expected:

    Synced / Healthy

This means Argo CD sees GitOps desired state and cluster actual state as aligned and healthy.

## Pipeline 3 - Dev release end-to-end verification

Repo:

    aks-capstone-store-app

Workflow:

    Verify Dev release end-to-end

Trigger:

    Manual workflow_dispatch

Main input:

    image_tag

Purpose:

    Verify Dev release from image to user access

This pipeline does not deploy.

It verifies the release.

## Pipeline 3 checks

The Dev verification workflow checks:

    ACR image tag exists
    GitOps repo image tag matches
    latest GitOps validation workflow passed
    AKS credentials available
    Argo CD app Synced and Healthy
    AKS deployment uses expected image
    rollout completed
    pod Running
    Gateway returns HTTP 200

This is the best single pipeline to prove Dev release success.

## Pipeline 3 output

Expected result:

    ACR verified
    GitOps verified
    Argo CD verified
    AKS verified
    Gateway verified
    workflow success

If this passes, Dev release is end-to-end healthy.

## Pipeline 4 - Promote store-front image

Repo:

    aks-capstone-gitops

Workflow:

    Promote store-front image

Trigger:

    Manual workflow_dispatch

Inputs:

    target_environment
    image_tag

target_environment options:

    qa
    prod

Purpose:

    Promote same image tag to QA or Prod by updating GitOps overlay

This workflow does not rebuild the image.

It updates:

    apps/capstone-store/overlays/qa/kustomization.yaml

or:

    apps/capstone-store/overlays/prod/kustomization.yaml

## Pipeline 4 steps

Promotion workflow steps:

    [01] Checkout GitOps repo
    [02] Validate promotion input
    [03] Update target overlay image tag
    [04] Render target overlay with Kustomize
    [05] Commit and push promotion change
    [06] Promotion summary

Numbered steps help learner understand the current pipeline phase.

## Pipeline 4 output

Expected result:

    target overlay image tag updated
    Kustomize render passes
    GitOps commit pushed
    workflow success

After this workflow pushes a GitOps commit, Pipeline 2 runs automatically again.

## Pipeline 5 - GitOps validation after promotion

Repo:

    aks-capstone-gitops

Workflow:

    Validate GitOps manifests

Trigger:

    Automatic on promotion commit push

Purpose:

    Validate QA/Prod promotion GitOps change

This is the same GitOps validation workflow used earlier.

It runs again because promotion workflow commits to GitOps repo.

## Pipeline 6 - Argo CD QA/Prod sync

System:

    Argo CD running inside AKS

Applications:

    capstone-store-qa
    capstone-store-prod

Trigger:

    automatic sync after GitOps overlay changes

QA app watches:

    apps/capstone-store/overlays/qa

Prod app watches:

    apps/capstone-store/overlays/prod

After promotion, Argo CD syncs the target environment.

## QA/Prod verification

QA check:

    kubectl get application capstone-store-qa -n argocd

Prod check:

    kubectl get application capstone-store-prod -n argocd

Expected:

    Synced / Healthy

Image check:

    kubectl get deployment store-front -n capstone-qa \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

    kubectl get deployment store-front -n capstone-prod \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

Expected image:

    <acr-login-server>/store-front:<image-tag>

Service check:

    kubectl get svc store-front -n capstone-qa
    kubectl get svc store-front -n capstone-prod

Expected service type:

    ClusterIP

## Which pipeline should user run first?

For a new Dev release, user runs first:

    aks-capstone-store-app
      -> Build store-front and deploy Dev via GitOps

This builds and publishes the image and updates Dev GitOps.

## What runs automatically after the first pipeline?

After app pipeline updates GitOps repo:

    aks-capstone-gitops
      -> Validate GitOps manifests

runs automatically because GitOps repo receives a push.

Then Argo CD automatically syncs Dev.

## What should user run after Dev sync?

User should run:

    aks-capstone-store-app
      -> Verify Dev release end-to-end

This proves the Dev release is actually working.

## How to promote to QA?

After Dev is verified, user runs:

    aks-capstone-gitops
      -> Promote store-front image

Input:

    target_environment: qa
    image_tag: same image tag tested in Dev

This updates QA overlay.

GitOps validation runs automatically.

Argo CD syncs QA.

## How to promote to Prod?

After QA is validated, user runs:

    aks-capstone-gitops
      -> Promote store-front image

Input:

    target_environment: prod
    image_tag: same image tag tested in Dev and QA

This updates Prod overlay.

GitOps validation runs automatically.

Argo CD syncs Prod.

## Full user journey

A learner should follow this journey:

    1. Run app build/deploy pipeline in app repo
    2. Watch GitOps validation pipeline in GitOps repo
    3. Check Argo CD Dev app
    4. Run Dev release verification pipeline in app repo
    5. Promote same image to QA from GitOps repo
    6. Watch GitOps validation pipeline
    7. Check Argo CD QA app
    8. Promote same image to Prod from GitOps repo
    9. Watch GitOps validation pipeline
    10. Check Argo CD Prod app

## Simple visual flow

Text diagram:

    Developer triggers app release
          |
          v
    App repo pipeline
    Build / scan / push image / update Dev GitOps
          |
          v
    GitOps repo validation pipeline
    YAML / Kustomize / kubeconform
          |
          v
    Argo CD syncs Dev
          |
          v
    Dev verification pipeline
    ACR / GitOps / Argo CD / AKS / Gateway
          |
          v
    Promote same image to QA
          |
          v
    GitOps validation
          |
          v
    Argo CD syncs QA
          |
          v
    Promote same image to Prod
          |
          v
    GitOps validation
          |
          v
    Argo CD syncs Prod

## Pipeline responsibility table

Pipeline responsibilities:

    App build pipeline:
      Build, scan, push, update Dev GitOps

    GitOps validation pipeline:
      Validate manifests and Kustomize

    Argo CD:
      Sync desired state to AKS

    Dev verification pipeline:
      Prove Dev release end-to-end

    Promotion pipeline:
      Promote same image tag to QA or Prod

## Manual vs automatic steps

Manual steps:

    Build store-front and deploy Dev via GitOps
    Verify Dev release end-to-end
    Promote store-front image to QA
    Promote store-front image to Prod

Automatic steps:

    Validate GitOps manifests after GitOps push
    Argo CD sync after GitOps desired state change

## Why Dev verification is manual

Dev verification workflow is manual because user decides which image tag to verify.

Example:

    stage13-v1

This makes the verification explicit.

It also avoids unnecessary cluster checks for every small commit.

## Why promotion is manual

Promotion to QA and Prod should be controlled.

Especially Prod promotion should not happen automatically from every Dev change.

Manual promotion gives human control.

Production principle:

    Dev can be frequent.
    QA should be intentional.
    Prod should be approved and intentional.

## Build once, promote same image

The most important release rule:

    Build once.
    Promote the same image.

Do not rebuild for QA.

Do not rebuild for Prod.

Why?

    Same artifact tested in Dev
    Same artifact validated in QA
    Same artifact released to Prod

This improves traceability and confidence.

## What happens if same image tag is already in QA or Prod?

Promotion workflow may say:

    No promotion change to commit

This is not a failure.

It means the target environment already uses the requested image tag.

The workflow can still pass.

## GitHub Actions UI tips

GitHub Actions UI shows:

    Workflow
      -> Job
          -> Steps

It does not show Azure DevOps-style stages.

That is why we use numbered steps like:

    [01]
    [02]
    [03]

This helps users understand which phase is currently running.

## Where to watch each pipeline

For app build and Dev verification:

    Open aks-capstone-store-app
    Go to Actions

For GitOps validation and promotion:

    Open aks-capstone-gitops
    Go to Actions

For Argo CD health:

    Use kubectl

Example:

    kubectl get applications -n argocd

## Current final pipeline list

Final pipeline list after Stage 16:

    aks-capstone-store-app:
      Build store-front and deploy Dev via GitOps
      Verify Dev release end-to-end

    aks-capstone-gitops:
      Validate GitOps manifests
      Promote store-front image

Argo CD apps:

    capstone-store-dev
    capstone-store-qa
    capstone-store-prod

## Final verified project state

At the end of Stage 16:

    Dev:
      Synced / Healthy

    QA:
      Synced / Healthy

    Prod:
      Synced / Healthy

    QA promotion:
      success

    Prod promotion:
      success

    QA/Prod services:
      ClusterIP

    MongoDB:
      stable after probe/resource tuning

## What this stage does not add

Stage 17 does not add:

    new AKS resources
    new application components
    new image build logic
    new promotion logic

Stage 17 only documents and clarifies the existing pipeline flow.

## Why this documentation comes after Stage 16

If this guide was written before Stage 16, it would become outdated.

Stage 16 added:

    QA overlay
    Prod overlay
    QA Argo CD app
    Prod Argo CD app
    promotion workflow
    MongoDB stability improvement

Now the Dev -> QA -> Prod pipeline architecture is stable.

So Stage 17 is the correct time to write final pipeline visibility documentation.

## Production learning points

### 1. Multiple pipelines are normal

Real projects often use separate pipelines for:

    app build
    manifest validation
    promotion
    verification

One giant pipeline is not always the best pattern.

### 2. Clear documentation is part of DevOps quality

If users cannot understand which pipeline to run, the platform is not learner-friendly.

Good DevOps includes:

    automation
    visibility
    documentation
    troubleshooting guidance

### 3. GitOps separates build from deploy

App pipeline creates an artifact.

GitOps repo declares desired state.

Argo CD deploys desired state.

This separation is the core GitOps model.

### 4. Promotion should be controlled

QA and Prod promotions should be intentional.

Manual workflow_dispatch is acceptable for learning and controlled release flow.

### 5. Final verification matters

A pipeline pass does not always mean users can access the app.

That is why Dev release verification checks Gateway HTTP 200.

### 6. Pipeline names and step names matter

Clear names help learners and reviewers.

Numbered steps make GitHub Actions easier to read.

## Troubleshooting

### Issue 1 - User cannot find the workflow

Check correct repo.

App workflows are in:

    aks-capstone-store-app

GitOps workflows are in:

    aks-capstone-gitops

Use:

    gh workflow list

### Issue 2 - GitOps validation does not run

Check whether a commit was pushed to GitOps repo main branch.

Use:

    git log --oneline -5
    gh run list --workflow="validate-gitops-manifests.yml" --limit 5

### Issue 3 - Argo CD does not update

Check application status:

    kubectl get applications -n argocd

Hard refresh if needed:

    kubectl annotate application <app-name> -n argocd \
      argocd.argoproj.io/refresh=hard \
      --overwrite

### Issue 4 - Target environment image did not change

Check overlay file:

    apps/capstone-store/overlays/qa/kustomization.yaml
    apps/capstone-store/overlays/prod/kustomization.yaml

Check actual deployment:

    kubectl get deployment store-front -n <namespace> \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

### Issue 5 - QA/Prod service has public IP

Expected:

    ClusterIP

If it shows LoadBalancer, check overlay patch:

    patch-store-front-service.yaml

Then check rendered manifest:

    kubectl kustomize apps/capstone-store/overlays/qa
    kubectl kustomize apps/capstone-store/overlays/prod

### Issue 6 - App is Synced but Progressing

Check pods:

    kubectl get pods -n <namespace>

Check failing pod logs:

    kubectl logs <pod-name> -n <namespace> --tail=100

Check events:

    kubectl describe pod <pod-name> -n <namespace>

## Learner summary

Stage 17 makes the pipeline flow understandable.

The project now has a complete Dev -> QA -> Prod release story:

    build image
    scan image
    update GitOps
    validate manifests
    deploy with Argo CD
    verify Dev
    promote same image to QA
    promote same image to Prod

The most important idea:

    App pipeline builds the artifact.
    GitOps pipeline validates desired state.
    Argo CD deploys desired state.
    Verification pipeline proves the release.
    Promotion pipeline moves the same image across environments.

Next stages can continue with:

    AIOps PR remediation
    platform Terraform CI
    final README/architecture cleanup
    DNS and TLS later
