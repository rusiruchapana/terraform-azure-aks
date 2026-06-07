# Stage 18 - Terraform Platform CI and Pipeline Visibility Improvements

## මේ stage එකේදී කරන්නේ මොකක්ද?

මේ stage එකේදී අපි project එකේ platform සහ pipeline quality වැඩි කරනවා.

මෙම stage එකේ main parts දෙකක් තියෙනවා.

    1. terraform-azure-aks repo එකට Terraform Platform CI workflow එකක් add කිරීම
    2. App, GitOps, Terraform pipelines userට clear වෙන විදිහට multi-job quality gates වලට refactor කිරීම

මේකෙන් project එක technically වැඩ කරනවා විතරක් නෙවෙයි, userට GitHub Actions UI එකෙන්ම “දැන් මොන phase එකද run වෙන්නේ?” කියලා තේරෙනවා.

## මේ stage එක වැදගත් ඇයි?

Stage 11 සිට Stage 17 දක්වා අපි app build, GitOps validation, Dev verification, QA/Prod promotion workflows හදාගත්තා.

නමුත් pipeline එක එක long job එකක් ඇතුළේ steps විදිහට තිබුණාම userට මේවා හොයාගන්න අමාරුයි:

    මොන scan එකද දැන් run වෙන්නේ?
    image එක push වෙලාද?
    image scan එක push කලින්ද පස්සෙද?
    GitOps update වුණාද?
    Argo CD sync වුණාද?
    Terraform code validate වෙනවද?
    Checkov fail වුණොත් ඒක production issue එකක්ද learning exception එකක්ද?

මේ stage එකෙන් ඒ confusion අඩු කරනවා.

## Stage 18 පටන් ගන්න කලින් තිබුණු problem එක

App සහ GitOps pipelines success වුණාට UI එකේ userට high-level flow එක clear නැහැ.

උදාහරණයක් ලෙස:

    Build and scan and push and update GitOps

මේ වගේ එක job එකක් pass වුණාම, userට steps expand කරලා බලන්න වෙනවා. ඒක learner-friendly නෑ.

තවත් වැදගත් issue එකක් තිබුණා:

    App pipeline GitOps repo එක update කළා.
    GitOps validation pass වුණා.
    Argo CD Synced / Healthy වුණා.
    නමුත් AKS deployment image tag එක update වෙලා නැති අවස්ථාවක් තිබුණා.

මෙහි root cause එක GitOps tool එකේ issue එකක් නෙවෙයි. අපේ workflow එක පරණ file path එක update කළා. Project එක evolve වෙලා Dev/QA/Prod overlays use කරන්න පටන් ගත්තත් app workflow එක base manifest update කරන assumption එක තියාගෙන තිබුණා.

Stage 18 එකෙන් මේ issue එක permanent guardrail එකකින් fix කළා.

## Terraform Platform CI එක

terraform-azure-aks repo එකට workflow එකක් add කළා.

Workflow name:

    Terraform Platform CI

Workflow file:

    .github/workflows/terraform-platform-ci.yml

මෙම workflow එකේ goal එක:

    Terraform code format හරිද බලනවා.
    Terraform root modules validate කරනවා.
    TFLint run කරනවා.
    Checkov security scan run කරනවා.
    Terraform apply හෝ destroy කිසිම දෙයක් run කරන්නේ නැහැ.

## Terraform CI එක safe ඇයි?

මෙම workflow එක run කරන්නේ validation සහ scanning පමණයි.

මෙය run නොකරන දේවල්:

    terraform apply
    terraform destroy
    Azure resources create
    Azure resources delete
    remote state modify

මෙය run කරන දේවල්:

    terraform fmt -check
    terraform init -backend=false
    terraform validate
    tflint
    checkov

ඒ නිසා pull request හෝ push එකකදී platform code quality check කරන්න safe.

## Terraform CI quality gates

Terraform workflow එක multi-job view එකකට refactor කළා.

GitHub Actions UI එකේ දැන් මෙහෙම පේනවා:

    Terraform Format
    Terraform Validate
    TFLint
    Checkov Security Scan
    Terraform CI Summary

මෙයින් userට clear:

    formatting issue එකක්ද?
    Terraform validate issue එකක්ද?
    TFLint issue එකක්ද?
    Checkov security finding එකක්ද?

## Terraform Format gate එක

මෙම job එක run කරන්නේ:

    terraform fmt -check -recursive

මෙයින් Terraform files consistent format එකේ තියෙනවද බලනවා.

Format issue එකක් තිබුණොත් local machine එකේ run කරන්න:

    terraform fmt -recursive

## Terraform Validate gate එක

මෙම job එක selected Terraform root directories වල run කරනවා.

Selected root directories:

    bootstrap/state-storage
    environments/capstone-platform
    environments/dev
    environments/qa
    environments/prod

මෙම directories වල workflow එක run කරන්නේ:

    terraform init -backend=false
    terraform validate

`-backend=false` use කරන්නේ remote state touch නොකර provider/plugin initialize කරලා validate කරන්න.

## Root modules සහ reusable modules අතර වෙනස

මුලින් workflow එක Terraform files තියෙන හැම folder එකක්ම detect කරලා validate/TFLint කරන්න උත්සාහ කළා.

ඒකෙන් modules folders වල unnecessary TFLint warnings ආවා.

උදාහරණයක්:

    modules/acr
    modules/aks
    modules/network

Reusable module folders වල provider version constraints සහ required_version direct define කරන්නේ නැති වෙන්න පුළුවන්. ඒවා root module එකෙන් inherit වෙන design එකක්.

ඒ නිසා workflow එක selected root directories වලට limit කළා.

මෙම decision එක වැදගත්:

    modules ignore කළේ නැහැ.
    modules root environments හරහා validate වෙනවා.
    direct TFLint run කිරීම root directories වලට පමණක් කළා.

## TFLint issue සහ fix

TFLint මුලින් real issue එකක් catch කළා.

Issue එක:

    bootstrap/state-storage/variables.tf file එකේ location variable එකට type නැති වීම

Fix එක:

    type = string

මෙය suppress කළේ නැහැ. Real best-practice issue එකක් නිසා code එක fix කළා.

මෙම lesson එක වැදගත්:

    CI fail වුණා කියලා scanner disable කරන්න එපා.
    Real issue එකක් නම් code එක fix කරන්න.
    False positive හෝ learning exception නම් reason එක්ක document කරන්න.

## Checkov Security Scan gate එක

Checkov workflow එක Terraform code security සහ best-practice policies against scan කරනවා.

Checkov මුලින් failures කිහිපයක් දුන්නා.

ඒවා mainly enterprise production controls:

    AKS private cluster
    paid SLA tier
    Azure Policy add-on
    disk encryption set
    private endpoints
    storage account customer-managed keys
    storage account private networking
    Key Vault private endpoint

මෙම project එක low-cost learning capstone එකක්. Azure Free Trial / Pay-As-You-Go cost control, GitHub-hosted runner access, සහ learning simplicity නිසා සමහර enterprise controls intentional exception ලෙස document කළා.

## Checkov baseline

Checkov baseline file එක add කළා:

    .checkov.yml

මෙම file එකේ skipped checks blind hide කරලා නැහැ.

එහි comments වලින් explain කරලා තියෙනවා:

    මේ project එක production landing zone එකක් නෙවෙයි.
    මේ skipped checks learning/free-trial constraints නිසා accepted exceptions.
    Production version එකකදී මේ controls revisit කරන්න ඕන.

මෙය important security practice එකක්:

    finding එක ignore කිරීම නෙවෙයි.
    reason එක්ක risk accept කිරීම.

## Terraform CI final result

Final Terraform Platform CI run එක success වුණා.

Passed gates:

    Terraform Format
    Terraform Validate
    TFLint
    Checkov Security Scan
    Terraform CI Summary

මෙයින් terraform-azure-aks repo එකට platform/IaC quality gate එකක් ලැබුණා.

## Pipeline visibility improvement එක

Terraform CI pass කරලා නතර වුණේ නැහැ. අපි app repo සහ GitOps repo pipelinesත් userට clear වෙන විදිහට refactor කළා.

Reason එක:

    pipeline technically success වුණාට userට flow එක තේරෙන්නේ නැත්නම් learning experience හොඳ නැහැ.

GitHub Actions වල Azure DevOps වගේ explicit "stages" concept එකක් නැහැ. නමුත් separate jobs use කළාම UI එකේ stage-like view එකක් ලැබෙනවා.

## GitOps validation workflow improvement

GitOps repo:

    aks-capstone-gitops

Workflow:

    Validate GitOps manifests

මෙය multi-job structure එකකට refactor කළා.

දැන් UI එකේ පේන jobs:

    YAML Syntax Validation
    Kustomize Render
    Kubeconform Kubernetes Validation
    GitOps Validation Summary

මෙයින් userට clear:

    YAML syntax valid ද
    Kustomize render වෙනවද
    Kubernetes manifest schemas valid ද
    GitOps desired state deploy-ready ද

## GitOps promotion workflow improvement

GitOps repo:

    aks-capstone-gitops

Workflow:

    Promote store-front image

මෙය multi-job structure එකකට refactor කළා.

දැන් UI එකේ පේන jobs:

    Validate Promotion Input
    Update Target Overlay
    Render Target Overlay
    Commit Promotion Change
    Promotion Summary

මෙයින් userට clear:

    target environment input valid ද
    QA/Prod overlay update වුණාද
    Kustomize render pass ද
    GitOps commit push වුණාද
    ඊළඟට Argo CD sync වෙන්න ඕන කියලා

## App Dev build workflow improvement

App repo:

    aks-capstone-store-app

Workflow:

    Build store-front and deploy Dev via GitOps

මෙය multi-job structure එකකට refactor කළා.

දැන් UI එකේ පේන jobs:

    Validate Release Input
    Secret Scan
    Source Security Scan
    Build Image
    Image Security Scan
    Push Image to ACR
    Update Dev GitOps
    Build and Dev Update Summary

මෙම flow එක security perspective එකෙන්ද improve කළා.

## Image scan before push

මුලින් workflow එක image build කරලා ACR එකට push කළා. ඊට පස්සේ image scan කළා.

එය deploy block කරත් vulnerable image එක registry එකට push වෙලා තියෙන්න පුළුවන්.

Stage 18 වලදී flow එක correct කළා:

    Build image locally
    Scan image
    Scan pass නම් පමණක් ACR එකට push
    Push pass නම් පමණක් GitOps update

මෙම order එක වඩා secureයි.

Current flow:

    Validate input
    Secret scan
    Source scan
    Build image locally
    Image scan before push
    Push scanned image to ACR
    Update Dev GitOps

## Dev GitOps overlay guardrail

මෙම stage එකේදී වැදගත් GitOps correctness issue එකක් fix කළා.

Problem එක:

    App pipeline GitOps file update කළා.
    GitOps validation pass වුණා.
    Argo CD Synced / Healthy වුණා.
    නමුත් AKS deployment image old tag එකේම තිබුණා.

Root cause එක:

    App workflow එක base manifest image line update කරන්න හදා තිබුණා.
    නමුත් Dev environment එක actual image tag control කළේ Dev overlay kustomization.yaml file එකේ newTag value එකෙන්.

Fix එක:

    App repo variable GITOPS_STORE_FRONT_FILE දැන් Dev overlay file එකට point කරනවා.

Current value:

    apps/capstone-store/overlays/dev/kustomization.yaml

Workflow එක දැන් update කරන්නේ:

    newTag: <image-tag>

ඒකට අමතරව workflow එක Dev overlay render කරලා expected image එක rendered manifest එකේ තියෙනවද verify කරනවා.

මෙයින් wrong file update issue එක නැවත එන්න ඉඩ අඩුයි.

## Dev overlay rendered verification

Update Dev GitOps job එක දැන් මෙය කරයි:

    Dev overlay kustomization.yaml update කරනවා
    kubectl kustomize apps/capstone-store/overlays/dev run කරනවා
    rendered manifest එකේ expected image tag එක තියෙනවද බලනවා
    namespace capstone-dev ද බලනවා
    ඒවා pass නම් පමණක් GitOps commit/push කරනවා

මෙයින් “GitOps commit වුණා නමුත් actual desired image wrong” කියන problem එක prevent වෙනවා.

## Dev verification workflow improvement

App repo:

    aks-capstone-store-app

Workflow:

    Verify Dev release end-to-end

මෙය multi-job structure එකකට refactor කළා.

දැන් UI එකේ පේන jobs:

    Validate Verification Input
    Verify ACR Image
    Verify GitOps Desired State
    Verify GitOps Validation Status
    Verify Argo CD Health
    Verify AKS Deployment
    Verify Gateway
    Dev Release Verification Summary

මෙම workflow එක deploy කරන්නේ නැහැ. එය Dev release එක verify කරනවා.

මෙයින් verify කරන chain එක:

    ACR image exists
    GitOps Dev desired state expected image use කරනවා
    GitOps validation latest run success
    Argo CD app Synced / Healthy
    AKS deployment actual image expected image
    rollout and pods healthy
    Gateway HTTP 200

## Legacy workflow rename

App repo එකේ old workflow එකක් තිබුණා:

    Build store-front image to ACR

මෙය Stage 11 learning/basic workflow එක. දැන් main release flow එකට use කරන්න ඕන workflow එක නෙවෙයි.

User confusion අඩු කරන්න workflow name එක rename කළා:

    Legacy - Build store-front image to ACR

දැන් userට clear:

    Legacy workflow = learning/history only
    Main workflow = Build store-front and deploy Dev via GitOps
    Verification workflow = Verify Dev release end-to-end

## Final workflow view

### terraform-azure-aks

Workflow:

    Terraform Platform CI

Jobs:

    Terraform Format
    Terraform Validate
    TFLint
    Checkov Security Scan
    Terraform CI Summary

### aks-capstone-gitops

Workflow:

    Validate GitOps manifests

Jobs:

    YAML Syntax Validation
    Kustomize Render
    Kubeconform Kubernetes Validation
    GitOps Validation Summary

Workflow:

    Promote store-front image

Jobs:

    Validate Promotion Input
    Update Target Overlay
    Render Target Overlay
    Commit Promotion Change
    Promotion Summary

### aks-capstone-store-app

Workflow:

    Build store-front and deploy Dev via GitOps

Jobs:

    Validate Release Input
    Secret Scan
    Source Security Scan
    Build Image
    Image Security Scan
    Push Image to ACR
    Update Dev GitOps
    Build and Dev Update Summary

Workflow:

    Verify Dev release end-to-end

Jobs:

    Validate Verification Input
    Verify ACR Image
    Verify GitOps Desired State
    Verify GitOps Validation Status
    Verify Argo CD Health
    Verify AKS Deployment
    Verify Gateway
    Dev Release Verification Summary

Workflow:

    Legacy - Build store-front image to ACR

Use:

    Stage 11 learning/history workflow only

## Final verified Dev release state

Final verified Dev image tag:

    stage18-secure-flow-v3

GitOps Dev overlay:

    newTag: stage18-secure-flow-v3

GitOps validation:

    Validate GitOps manifests passed

Argo CD:

    capstone-store-dev Synced / Healthy

AKS deployment image:

    <acr-login-server>/store-front:stage18-secure-flow-v3

This confirms the full Dev release path works.

## Production learning points

### 1. Pipeline pass වුණා කියලා actual deployment correct කියලා assume කරන්න එපා

Always verify:

    GitOps desired state
    rendered manifest
    Argo CD status
    AKS actual deployment image

### 2. GitOps validation සහ Argo CD Synced වෙනත් concepts දෙකක්

GitOps validation කියන්නේ manifests valid ද කියලා බලන CI check එකක්.

Argo CD Synced කියන්නේ cluster actual state සහ Git desired state match වෙනවා කියන එක.

Git desired state එක වැරදි image tag එකක් නම් Argo CD ඒකම correctly sync කරනවා.

### 3. Rendered manifest verification guardrail එක වැදගත්

Kustomize overlays use කරන project එකක file update කළා කියලා පමණක් ප්‍රමාණවත් නෑ.

Rendered output එක verify කරන්න ඕන.

### 4. Security scan push කලින් run කිරීම හොඳ pattern එකක්

Bad image එක registry එකට push වෙලා පස්සේ block කරනවට වඩා, image scan pass වුණාට පස්සේ push කරන එක වඩා හොඳයි.

### 5. Multiple jobs user experience improve කරනවා

Single long job එකක් success වුණාට userට flow එක හොයාගන්න අමාරුයි.

Separate jobs use කළාම userට high-level phase එක GitHub Actions UI එකෙන්ම පේනවා.

### 6. Legacy workflows mark කරන්න

Old learning workflows remove නොකර keep කරන්න පුළුවන්.

නමුත් ඒවා main release flow එකෙන් වෙනස් කියලා clear කරන්න ඕන.

## Troubleshooting

### Terraform CI fail වුණොත්

Workflow open කරලා fail වූ gate එක බලන්න:

    Terraform Format
    Terraform Validate
    TFLint
    Checkov Security Scan

Fail වූ gate එකෙන් issue area එක හඳුනාගන්න.

### Checkov fail වුණොත්

මුලින් finding එක read කරන්න.

Decision කරන්න:

    real issue නම් fix කරන්න
    learning/free-trial exception නම් .checkov.yml තුළ reason එක්ක document කරන්න
    blind skip කරන්න එපා

### GitOps validation pass නමුත් app image update නොවුණොත්

Check කරන්න:

    GitOps Dev overlay newTag
    rendered Dev manifest image
    Argo CD revision
    AKS actual deployment image

Commands:

    grep -n "newTag:" apps/capstone-store/overlays/dev/kustomization.yaml

    kubectl get deployment store-front -n capstone-dev \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

### App build workflow success නමුත් GitOps validation trigger නොවුණොත්

Possible reason:

    GitOps repo එකට new commit එකක් push වෙලා නැහැ.
    Dev overlay already same image tag use කරනවා.

Check කරන්න:

    Update Dev GitOps job log
    aks-capstone-gitops commit history
    Validate GitOps manifests workflow runs

### Dev verification fail වුණොත්

Fail වූ job එක බලන්න:

    Verify ACR Image
    Verify GitOps Desired State
    Verify GitOps Validation Status
    Verify Argo CD Health
    Verify AKS Deployment
    Verify Gateway

Fail වූ job එකෙන් issue area එක clear වෙනවා.

## Learner summary

Stage 18 වලදී project එකේ platform quality සහ pipeline user experience දෙකම improve කළා.

අපි add කළා:

    Terraform Platform CI
    Terraform Format gate
    Terraform Validate gate
    TFLint gate
    Checkov Security Scan gate
    documented Checkov baseline

අපි improve කළා:

    GitOps validation workflow visibility
    GitOps promotion workflow visibility
    App Dev build workflow visibility
    Dev verification workflow visibility
    Image scan before push security flow
    Dev overlay rendered image guardrail

Final result එක:

    project එක run වෙනවා විතරක් නෙවෙයි
    userට මොකක්ද වෙන්නේ කියලා UI එකෙන්ම තේරෙනවා
    wrong GitOps image update වගේ mistake නැවත අල්ලගන්න guardrails තියෙනවා
    Terraform platform codeත් CI quality gate එකකින් protect වෙනවා

Next stages can continue with:

    AIOps PR remediation
    final documentation/navigation cleanup
    architecture diagram cleanup
    DNS and TLS later
