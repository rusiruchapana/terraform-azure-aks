# Stage 14 - GitOps Manifest Validation Pipeline

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි GitOps repo එකට validation pipeline එකක් add කරනවා.

GitOps repo එකේ Kubernetes manifests වෙනස් වුණාම pipeline එක check කරනවා:

    YAML syntax valid ද?
    Kustomize render වෙනවද?
    rendered Kubernetes manifests schema-valid ද?

මේකෙන් Argo CD sync කරන්න කලින් වැරදි manifests catch කරගන්න පුළුවන්.

## මේ stage එක වැදගත් ඇයි?

GitOps repo එක production-style deployment source of truth එකයි.

Argo CD බලන්නේ GitOps repo එකේ desired state එක.

ඒ නිසා GitOps repo එකට වැරදි YAML file එකක්, invalid Kubernetes manifest එකක්, broken Kustomize config එකක් push වුණොත්:

    Argo CD sync fail වෙන්න පුළුවන්
    Dev deployment break වෙන්න පුළුවන්
    rollback/troubleshooting අවශ්‍ය වෙන්න පුළුවන්

Stage 14 වලදී අපි ඒ risk එක reduce කරනවා.

## Repositories ගැන පැහැදිලි කිරීම

මේ project එකේ pipelines repo කිහිපයක තියෙනවා.

App repo:

    aks-capstone-store-app

මෙහිදී app code build, scan, image push, GitOps update කරනවා.

GitOps repo:

    aks-capstone-gitops

මෙහිදී Kubernetes manifests, Kustomize files, Argo CD application desired state තියෙනවා.

Terraform repo:

    terraform-azure-aks

මෙහිදී platform infrastructure සහ lab guides තියෙනවා.

Stage 14 pipeline එක තියෙන්නේ:

    aks-capstone-gitops

මොකද මේ pipeline එක validate කරන්නේ GitOps manifests.

## Stage 13 සහ Stage 14 අතර වෙනස

Stage 13:

    App repo pipeline
    store-front image build/scan/push
    GitOps image tag update
    Argo CD Dev deployment

Stage 14:

    GitOps repo pipeline
    YAML validation
    Kustomize render validation
    Kubernetes schema validation

මේ දෙක එකම pipeline එකක් නෙවෙයි.

හේතුව:

    App code quality සහ image security app repo එකේ concern එකක්
    Deployment manifest quality GitOps repo එකේ concern එකක්

## Stage 14 validation flow

Pipeline flow එක:

    GitOps repo change
        -> GitHub Actions starts
        -> checkout GitOps repo
        -> install PyYAML
        -> install kubeconform
        -> validate YAML syntax
        -> render Kustomize base
        -> validate rendered manifests with kubeconform

## Tools used

### PyYAML

YAML files syntax-valid ද කියලා check කරන්න use කරනවා.

මෙම step එක catch කරන issues:

    indentation errors
    invalid YAML structure
    broken YAML format

### kubectl kustomize

Kustomize configuration render වෙනවද කියලා check කරනවා.

මෙම step එක catch කරන issues:

    missing resource file
    wrong kustomization path
    invalid patch reference
    broken Kustomize structure

### kubeconform

Rendered Kubernetes manifests Kubernetes schema එකට valid ද කියලා check කරනවා.

මෙම step එක catch කරන issues:

    invalid Kubernetes fields
    wrong apiVersion/kind structure
    schema-related errors

## Workflow file

GitOps repo එකේ workflow file එක:

    .github/workflows/validate-gitops-manifests.yml

Workflow name:

    Validate GitOps manifests

Triggers:

    push to main
    pull_request to main
    manual workflow_dispatch

## Workflow trigger design

මෙම workflow එක run වෙන අවස්ථා:

    main branch එකට push කළාම
    main branch එකට pull request එකක් ආවම
    manually run කළාම

Manual trigger එක useful වන්නේ:

    pipeline test කරන්න
    validation manually verify කරන්න
    troubleshooting වෙලාවට නැවත run කරන්න

## Workflow permissions

මෙම pipeline එකට write access අවශ්‍ය නැහැ.

Required permission:

    contents: read

හේතුව:

    repo checkout කරලා validate කරනවා විතරයි
    GitOps repo එකට commit/push කරන්නේ නැහැ
    cluster එකට deploy කරන්නේ නැහැ

Security best practice:

    අවශ්‍ය permission විතරක් දෙන්න

## Workflow එක create කිරීම

GitOps repo එකට යන්න:

    cd <local-path>/aks-capstone-gitops

Workflow folder එක හදන්න:

    mkdir -p .github/workflows

Workflow file එක create කරන්න:

    .github/workflows/validate-gitops-manifests.yml

මෙම workflow එකේ main steps:

    Checkout GitOps repo
    Install Python YAML parser
    Install kubeconform
    Validate YAML syntax
    Render capstone-store base with Kustomize
    Validate rendered manifests with kubeconform

## Important syntax lesson

මුලින් workflow එක 0 seconds වල fail වුණා.

GitHub CLI output එක:

    This run likely failed because of a workflow file issue

Logs තිබුණේ නැහැ.

මෙයින් අදහස් වෙන්නේ job එක start වෙලා නැහැ.

සාමාන්‍යයෙන් මෙවැනි issue එකක් එන්නේ:

    workflow YAML syntax issue
    GitHub Actions parser issue
    bad indentation
    invalid heredoc indentation
    invalid workflow structure

Fix කළේ:

    clean workflow file එකක් use කළා
    "on" key එක quote කළා
    workflow_dispatch input properly දැම්මා
    Python heredoc block එක properly indent කළා

## Why "on" key quote කළේ?

YAML parsers සමහර context වල `on` key එක boolean-like value එකක් ලෙස interpret කරන අවස්ථා තියෙන්න පුළුවන්.

GitHub Actions වල `on` key එක special trigger key එකක්.

Clean and safe pattern එකක් ලෙස use කළා:

    "on":

මෙය workflow parser confusion avoid කරන්න help වෙනවා.

## Local validation

GitHub Actions push කරන්න කලින් local YAML parse check කරන්න පුළුවන්.

Example:

    python3 - <<'PY'
    from pathlib import Path
    import yaml

    p = Path(".github/workflows/validate-gitops-manifests.yml")
    with p.open() as f:
        yaml.safe_load(f)

    print("Workflow YAML parses successfully")
    PY

මෙය workflow file එක YAML syntax-wise valid ද කියලා check කරනවා.

## Commit and push

Workflow file එක add කරන්න:

    git add .github/workflows/validate-gitops-manifests.yml

Commit කරන්න:

    git commit -m "Add GitOps manifest validation workflow"

Push කරන්න:

    git push

Push කළාම workflow එක automatically run වෙනවා.

## Push-triggered run verification

Workflow runs බලන්න:

    gh run list --limit 5

Expected:

    Validate GitOps manifests
    Event: push
    Status: success

Stage 14 වලදී push-triggered run එක success වුණා.

## Manual run verification

Manual workflow run කරන්න:

    gh workflow run validate-gitops-manifests.yml --ref main -f reason="stage14 manual test"

Run list බලන්න:

    gh run list --workflow="validate-gitops-manifests.yml" --limit 5

Run details බලන්න:

    gh run view <run-id>

Stage 14 වලදී manual run එකත් success වුණා.

## Successful manual run result

Verified run result:

    Workflow: Validate GitOps manifests
    Event: workflow_dispatch
    Status: success
    Duration: 12s

Job:

    Validate YAML, Kustomize, and Kubernetes manifests

Result:

    Passed

## YAML syntax validation result

Pipeline එක YAML files check කළා.

Validated files include:

    apps/capstone-store/base/aks-store-quickstart.yaml
    apps/capstone-store/base/kustomization.yaml
    apps/capstone-store/base/makeline-mongodb.yaml
    apps/capstone-store/base/store-admin.yaml
    apps/capstone-store/base/virtual-customer.yaml
    apps/capstone-store/base/virtual-worker.yaml
    apps/capstone-store/overlays/dev/kustomization.yaml
    apps/capstone-store/overlays/qa/kustomization.yaml
    apps/capstone-store/overlays/prod/kustomization.yaml
    argocd/applications/capstone-store-dev.yaml
    platform/namespaces/capstone-namespaces.yaml

All checked YAML files were OK.

## Kustomize render result

Pipeline එක render කළේ:

    apps/capstone-store/base

Command concept එක:

    kubectl kustomize apps/capstone-store/base

Render output එක successfully generated වුණා.

මෙයින් confirm වෙන්නේ:

    kustomization.yaml valid
    referenced resources available
    Kustomize structure render වෙනවා

## kubeconform validation result

Rendered manifests kubeconform වලින් validate කළා.

Final result:

    17 resources found
    Valid: 17
    Invalid: 0
    Errors: 0
    Skipped: 0

මෙය Stage 14 වල main success criteria එක.

## Node.js 20 warning

Workflow run එකේ warning එකක් තිබුණා:

    Node.js 20 actions are deprecated

මෙය failure එකක් නෙවෙයි.

Reason:

    actions/checkout@v4 Node.js 20 runtime warning එකක් show කරනවා

Workflow result එක success නම් Stage 14 block වෙන්නේ නැහැ.

Future improvement:

    GitHub Actions versions update කරන්න
    Node.js 24-compatible action versions available වුණාම upgrade කරන්න

## Final verified state - අවසාන verified තත්ත්වය

Stage 14 final state:

    GitOps validation workflow created

Push trigger:

    Passed

Manual trigger:

    Passed

YAML syntax validation:

    Passed

Kustomize render:

    Passed

kubeconform validation:

    17 valid resources
    0 invalid resources
    0 errors

Workflow syntax issue:

    Fixed

## Production learning points - production පාඩම්

### 1. GitOps repo එකට වෙනම validation pipeline එකක් ඕන

GitOps repo එක cluster desired state එක represent කරනවා.

ඒ නිසා GitOps repo changes validate නොකර merge/push කරන එක risky.

### 2. App pipeline සහ GitOps pipeline වෙනස් responsibilities තියෙනවා

App pipeline එක බලන්නේ:

    code
    dependencies
    image build
    image scan
    image push

GitOps pipeline එක බලන්නේ:

    manifests
    Kustomize rendering
    Kubernetes schema validity

මෙය production separation එකක්.

### 3. 0-second workflow failure එක manifest issue එකක් නෙවෙයි

Stage 14 මුල් failures 0 seconds වල fail වුණා.

Logs තිබුණේ නැහැ.

ඒකෙන් අපි තේරුම් ගත්තා:

    job එක start වෙලා නැහැ
    workflow YAML/parser issue එකක්

ඒ නිසා manifest troubleshooting නොකර workflow syntax fix කළා.

### 4. Validation cluster එකට deploy නොකරයි

මෙම pipeline එක cluster access use කරන්නේ නැහැ.

එය only validate කරනවා:

    YAML parse
    Kustomize render
    Kubernetes schema

මෙය safe pre-deploy gate එකක්.

### 5. GitOps validation Argo CD sync failures reduce කරනවා

Argo CD sync fail වෙන්න කලින් invalid manifest catch කරන්න පුළුවන්.

ඒක troubleshooting time reduce කරනවා.

## Troubleshooting - ගැටළු විසඳීම

### Issue 1 - Workflow run 0 seconds වල fail වෙනවා

Symptom:

    Run failed immediately
    No logs available
    Message says workflow file issue

Possible cause:

    GitHub Actions YAML syntax issue
    bad indentation
    invalid workflow structure
    heredoc indentation issue

Fix:

    workflow YAML parse check කරන්න
    clean workflow file version use කරන්න
    commit/push කරලා නැවත run කරන්න

### Issue 2 - Manual trigger not available

Symptom:

    Workflow does not have workflow_dispatch trigger

Check remote workflow file:

    gh workflow view <workflow-id> --yaml | sed -n '1,30p'

Check file content:

    gh api repos/<owner>/<repo>/contents/.github/workflows/validate-gitops-manifests.yml \
      --jq '.content' | base64 --decode | sed -n '1,30p'

Fix:

    workflow_dispatch block add කරන්න
    commit/push කරන්න
    30-60 seconds wait කරන්න

### Issue 3 - YAML syntax validation fails

Symptom:

    ERROR: file.yaml

Fix:

    indentation check කරන්න
    missing colon check කරන්න
    invalid list/object structure fix කරන්න

### Issue 4 - Kustomize render fails

Possible causes:

    kustomization.yaml references missing file
    resource path wrong
    patch target wrong
    invalid Kustomize syntax

Fix:

    kubectl kustomize <path> local run කරන්න
    missing resource/patch path fix කරන්න

### Issue 5 - kubeconform validation fails

Possible causes:

    invalid Kubernetes field
    wrong apiVersion
    wrong kind
    schema mismatch

Fix:

    rendered manifest inspect කරන්න
    Kubernetes schema-compatible fields use කරන්න

## Learner summary - ඉගෙනගන්න ප්‍රධාන අදහස

Stage 14 වලදී අපි GitOps repo එකට guardrail එකක් add කළා.

මේ guardrail එකෙන් invalid Kubernetes desired state එක Argo CD වෙත යන්න කලින් catch කරනවා.

Final flow:

    GitOps change
        -> YAML syntax validation
        -> Kustomize render validation
        -> kubeconform schema validation
        -> valid manifests only continue

Stage 14 GitOps repo එකේ තියෙන්නේ ඒ නිසායි:

    GitOps manifests validate කරන්නේ GitOps repo එකේ
    App image build/scan කරන්නේ app repo එකේ

Next stage:

    Stage 15 - End-to-end Dev release visibility workflow
