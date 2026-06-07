# Stage 17 - Pipeline Visibility and Release Flow Documentation

## මේ stage එකේදී කරන්නේ මොකක්ද?

මේ stage එකේදී අපි capstone project එකේ pipeline flow එක learner කෙනෙක්ට ලේසියෙන් තේරෙන විදිහට පැහැදිලි කරනවා.

Stage 11 සිට Stage 16 දක්වා අපි pipelines කිහිපයක් හදාගෙන තියෙනවා. ඒ pipelines එකම repository එකක නෙවෙයි තියෙන්නේ. සමහර pipelines app repo එකේ තියෙනවා. සමහර pipelines GitOps repo එකේ තියෙනවා. Argo CD sync එක GitHub Actions pipeline එකක් නෙවෙයි; ඒක AKS cluster එක ඇතුළේ run වෙන continuous delivery controller එකක්.

මේ නිසා learner කෙනෙක්ට මේ වගේ ප්‍රශ්න එන්න පුළුවන්:

    මුලින්ම run කරන්න ඕන pipeline එක මොකක්ද?
    ඊළඟට automatically run වෙන pipeline එක මොකක්ද?
    App repo pipeline එක සහ GitOps repo pipeline එක වෙනස් ඇයි?
    Dev release එක verify කරන්නේ කොහොමද?
    QA වලට promote කරන්නේ කොහොමද?
    Prod වලට promote කරන්නේ කොහොමද?
    GitHub Actions UI එකේ මම බලන්න ඕන workflow එක මොකක්ද?

මේ guide එකෙන් ඒ flow එක සරලව පැහැදිලි කරනවා.

## මේ documentation stage එක වැදගත් ඇයි?

Pipeline එක වැඩ කරනවා කියන එක පමණක් ප්‍රමාණවත් නෑ. Userට pipeline flow එක තේරෙන්න ඕන.

හොඳ platform engineering project එකක මේ දේවල් clear වෙන්න ඕන:

    automation එක වැඩ කරනවාද
    pipeline responsibility එක මොකක්ද
    release එක environment අතර යන්නේ කොහොමද
    user බලන්න ඕන workflow එක මොකක්ද
    final verification කරන්නේ කොහොමද

Stage 17 එකෙන් අපි අලුත් AKS resource එකක් add කරන්නේ නෑ. අලුත් application service එකක් add කරන්නේ නෑ. මේ stage එක documentation සහ learner visibility improve කරන stage එකක්.

## Stage 17 පටන් ගන්න කලින් තිබුණු stable තත්ත්වය

Stage 17 ලියන්නේ Stage 16 complete වුණාට පස්සේ.

ඒ වෙලාවේ තත්ත්වය:

    Dev release pipeline වැඩ කරනවා
    GitOps manifest validation pipeline වැඩ කරනවා
    Dev release end-to-end verification pipeline වැඩ කරනවා
    QA promotion workflow වැඩ කරනවා
    Prod promotion workflow වැඩ කරනවා
    Dev, QA, Prod Argo CD apps Synced / Healthy
    QA සහ Prod store-front services ClusterIP
    MongoDB probe/resource tuning fix එක apply වෙලා stable

ඒ නිසා දැන් full pipeline flow එක document කරන එක safe. Stage 16ට කලින් මේ guide එක ලිව්වා නම් QA/Prod promotion flow තව complete නැති නිසා guide එක outdated වෙන්න තිබුණා.

## Repositories තුනේ role එක

මෙම capstone project එකට repositories තුනක් සම්බන්ධයි.

### aks-capstone-store-app

මෙය application source repository එක.

මෙහි තියෙන්නේ:

    store-front source code
    Dockerfile
    image build workflow
    Dev GitOps update workflow
    Dev release verification workflow

මෙම repo එකේ workflows වලින් mainly බලන්නේ:

    app code scan pass ද
    Docker image build වෙනවද
    image ACR එකට push වෙනවද
    Dev GitOps image tag update වෙනවද
    Dev release end-to-end verify වෙනවද

### aks-capstone-gitops

මෙය GitOps desired state repository එක.

මෙහි තියෙන්නේ:

    Kubernetes manifests
    Kustomize base
    Dev overlay
    QA overlay
    Prod overlay
    Argo CD Application manifests
    GitOps validation workflow
    QA/Prod promotion workflow

මෙම repo එකේ workflows වලින් mainly බලන්නේ:

    YAML valid ද
    Kustomize render වෙනවද
    Kubernetes schema validation pass ද
    QA/Prod overlay image tag update වෙනවද
    promotion commit push වෙනවද

### terraform-azure-aks

මෙය platform සහ documentation repository එක.

මෙහි තියෙන්නේ:

    Terraform platform code
    AKS platform setup
    capstone guides
    learning documentation

මෙම Stage 17 guide එක තියෙන්නේ මේ repository එකේ.

## Pipelines repos දෙකක තියෙන්නේ ඇයි?

මෙය වැරදි design එකක් නෙවෙයි. මේක production-style separation එකක්.

App repo එකේ responsibility එක:

    application code
    image build
    image scan
    image publish
    Dev image tag update

GitOps repo එකේ responsibility එක:

    Kubernetes desired state
    environment overlays
    manifest validation
    QA/Prod promotion

Argo CD responsibility එක:

    GitOps repo එකේ desired state එක AKS cluster එකට sync කිරීම

සරලව කිව්වොත්:

    App repo pipeline එක artifact එක හදනවා.
    GitOps repo pipeline එක deployment manifests validate කරනවා.
    Argo CD ඒ desired state එක cluster එකට apply කරනවා.
    Verification pipeline එක release එක ඇත්තටම වැඩ කරනවද බලනවා.
    Promotion workflow එක same image එක QA/Prod වලට promote කරනවා.

## Full release flow එක

Full flow එක මෙහෙමයි:

    1. User app repo එකේ Dev build/deploy workflow එක run කරනවා
    2. App pipeline image build කරලා scan කරලා ACR එකට push කරනවා
    3. App pipeline GitOps repo එකේ Dev image tag update කරනවා
    4. GitOps repo එකට commit push වුණාම GitOps validation workflow auto run වෙනවා
    5. Argo CD GitOps change එක detect කරලා Dev environment sync කරනවා
    6. User Dev release verification workflow එක run කරනවා
    7. Dev verified නම් same image tag එක QA වලට promote කරනවා
    8. QA promotion commit එකෙන් GitOps validation auto run වෙනවා
    9. Argo CD QA environment sync කරනවා
    10. QA okay නම් same image tag එක Prod වලට promote කරනවා
    11. Prod promotion commit එකෙන් GitOps validation auto run වෙනවා
    12. Argo CD Prod environment sync කරනවා

## Pipeline flow diagram එක

සරල text diagram එක:

    Developer / Learner
          |
          v
    aks-capstone-store-app
    Build store-front and deploy Dev via GitOps
          |
          v
    ACR image push
          |
          v
    aks-capstone-gitops
    Dev overlay image tag update
          |
          v
    Validate GitOps manifests
          |
          v
    Argo CD syncs Dev
          |
          v
    aks-capstone-store-app
    Verify Dev release end-to-end
          |
          v
    aks-capstone-gitops
    Promote same image to QA
          |
          v
    Validate GitOps manifests
          |
          v
    Argo CD syncs QA
          |
          v
    aks-capstone-gitops
    Promote same image to Prod
          |
          v
    Validate GitOps manifests
          |
          v
    Argo CD syncs Prod

## Pipeline 1 - Dev image build සහ GitOps update

මෙම pipeline එක app repo එකේ තියෙනවා.

Repository:

    aks-capstone-store-app

Workflow name:

    Build store-front and deploy Dev via GitOps

Run කරන ආකාරය:

    Manual workflow_dispatch

User දෙන input එක:

    image_tag

උදාහරණයක්:

    stage13-v1

මෙම pipeline එක කරන්නේ:

    store-front source code checkout කරනවා
    Gitleaks secret scan run කරනවා
    Trivy source/dependency scan run කරනවා
    Azure login with OIDC කරනවා
    ACR login කරනවා
    Docker image build කරනවා
    Trivy image scan run කරනවා
    image එක ACR එකට push කරනවා
    pushed image tag එක ACR එකේ තියෙනවද verify කරනවා
    GitOps repo checkout කරනවා
    Dev overlay image tag update කරනවා
    GitOps repo එකට commit/push කරනවා

මෙම pipeline එක AKS cluster එකට direct deploy කරන්නේ නෑ.

ඒ වෙනුවට එය GitOps repo එක update කරනවා. Argo CD පස්සේ GitOps change එක detect කරලා deploy කරනවා.

## Pipeline 1 එකෙන් ලැබෙන result එක

මෙම pipeline එක success වුණාම මේවා complete වෙලා තියෙන්න ඕන:

    image ACR එකේ තියෙනවා
    GitOps Dev overlay image tag update වෙලා තියෙනවා
    GitOps repo එකට commit push වෙලා තියෙනවා
    GitHub Actions workflow success

උදාහරණ image format එක:

    <acr-login-server>/store-front:<image-tag>

## Pipeline 2 - GitOps manifest validation

මෙම pipeline එක GitOps repo එකේ තියෙනවා.

Repository:

    aks-capstone-gitops

Workflow name:

    Validate GitOps manifests

Run වෙන ආකාරය:

    GitOps repo main branch එකට push වුණාම automatic run වෙනවා
    main branch එකට pull request එකක් ආවොත් run වෙනවා
    අවශ්‍ය නම් manually run කරන්නත් පුළුවන්

මෙම pipeline එක කරන්නේ:

    YAML syntax check කරනවා
    Kustomize render වෙනවද බලනවා
    rendered Kubernetes manifests kubeconform වලින් validate කරනවා

මෙය app pipeline එක Dev GitOps update කළාට පස්සේ automatically run වෙනවා.

මෙය QA/Prod promotion workflow එක GitOps repo එකට commit push කළාට පස්සේත් automatically run වෙනවා.

## Pipeline 2 එකෙන් ලැබෙන result එක

මෙම pipeline එක success වුණාම මේවා confirm වෙනවා:

    YAML files valid
    Kustomize render pass
    Kubernetes schema validation pass
    GitOps desired state invalid නැහැ

මෙම pipeline එක fail වුණොත් GitOps change එක safe කියලා assume කරන්න එපා.

## Argo CD Dev sync

Argo CD කියන්නේ GitHub Actions workflow එකක් නෙවෙයි.

එය AKS cluster එක ඇතුළේ run වෙන continuous delivery controller එකක්.

Dev Argo CD Application එක:

    capstone-store-dev

එය watch කරන GitOps path එක:

    apps/capstone-store/overlays/dev

GitOps Dev overlay වෙනස් වුණාම Argo CD ඒ change එක detect කරලා capstone-dev namespace එකට sync කරනවා.

Check command:

    kubectl get application capstone-store-dev -n argocd

Expected status:

    Synced / Healthy

## Pipeline 3 - Dev release end-to-end verification

මෙම pipeline එක app repo එකේ තියෙනවා.

Repository:

    aks-capstone-store-app

Workflow name:

    Verify Dev release end-to-end

Run කරන ආකාරය:

    Manual workflow_dispatch

User දෙන input එක:

    image_tag

මෙම pipeline එක deploy කරන්නේ නෑ. එය release එක verify කරනවා.

එය check කරන දේවල්:

    ACR image tag exists ද
    GitOps repo image tag match ද
    latest GitOps validation workflow passed ද
    AKS credentials ගන්න පුළුවන්ද
    Argo CD app Synced / Healthy ද
    AKS deployment expected image එක use කරනවද
    rollout complete ද
    pod Running ද
    Gateway HTTP 200 return කරනවද

## Pipeline 3 එකෙන් ලැබෙන result එක

මෙම pipeline එක success නම් Dev release එක end-to-end healthy කියලා කියන්න පුළුවන්.

මෙම pipeline එක app repo සහ GitOps repo අතර confusion අඩු කරනවා, මොකද එක workflow එකෙන් ACR -> GitOps -> Argo CD -> AKS -> Gateway flow එක verify කරනවා.

## Pipeline 4 - QA/Prod promotion

මෙම pipeline එක GitOps repo එකේ තියෙනවා.

Repository:

    aks-capstone-gitops

Workflow name:

    Promote store-front image

Run කරන ආකාරය:

    Manual workflow_dispatch

User දෙන inputs:

    target_environment
    image_tag

target_environment values:

    qa
    prod

මෙම pipeline එක image rebuild කරන්නේ නෑ.

එය කරන්නේ target environment overlay එකේ image tag update කිරීමයි.

QA promotion එක update කරන file එක:

    apps/capstone-store/overlays/qa/kustomization.yaml

Prod promotion එක update කරන file එක:

    apps/capstone-store/overlays/prod/kustomization.yaml

## Pipeline 4 steps

Promotion workflow එකේ numbered steps තියෙනවා.

    [01] Checkout GitOps repo
    [02] Validate promotion input
    [03] Update target overlay image tag
    [04] Render target overlay with Kustomize
    [05] Commit and push promotion change
    [06] Promotion summary

Numbered steps use කළේ GitHub Actions UI එකේ learnerට current phase එක ලේසියෙන් තේරෙන්න.

## Pipeline 4 එකෙන් ලැබෙන result එක

මෙම pipeline එක success වුණාම:

    target overlay image tag update වෙනවා
    Kustomize render pass වෙනවා
    GitOps repo එකට promotion commit එක push වෙනවා
    GitOps validation workflow auto run වෙනවා
    Argo CD target environment sync කරනවා

If target environment එක already requested image tag එක use කරනවා නම් workflow එකට commit කරන්න දෙයක් නැති වෙන්න පුළුවන්.

එවිට output එකේ මෙහෙම පෙන්වන්න පුළුවන්:

    No promotion change to commit

ඒක failure එකක් නෙවෙයි. ඒකෙන් කියන්නේ environment එක already requested image tag එකේ තියෙනවා කියලා.

## QA promotion flow එක

Dev release verify වුණාට පස්සේ QA promotion කරන්න.

Workflow:

    Promote store-front image

Inputs:

    target_environment: qa
    image_tag: Dev වල verify කළ same image tag එක

QA promotion එකෙන් පස්සේ:

    GitOps validation auto run වෙනවා
    Argo CD capstone-store-qa sync කරනවා

QA verify කරන්න:

    kubectl get application capstone-store-qa -n argocd

Expected:

    Synced / Healthy

QA image verify කරන්න:

    kubectl get deployment store-front -n capstone-qa \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

QA service verify කරන්න:

    kubectl get svc store-front -n capstone-qa

Expected service type:

    ClusterIP

## Prod promotion flow එක

QA verify වුණාට පස්සේ Prod promotion කරන්න.

Workflow:

    Promote store-front image

Inputs:

    target_environment: prod
    image_tag: QA වල verify කළ same image tag එක

Prod promotion එකෙන් පස්සේ:

    GitOps validation auto run වෙනවා
    Argo CD capstone-store-prod sync කරනවා

Prod verify කරන්න:

    kubectl get application capstone-store-prod -n argocd

Expected:

    Synced / Healthy

Prod image verify කරන්න:

    kubectl get deployment store-front -n capstone-prod \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

Prod service verify කරන්න:

    kubectl get svc store-front -n capstone-prod

Expected service type:

    ClusterIP

## User මුලින්ම බලන්න ඕන workflow එක

New release එකක් test කරන්න user මුලින් run කරන්න ඕන workflow එක:

    aks-capstone-store-app
      Build store-front and deploy Dev via GitOps

මෙම workflow එක app build කරලා image publish කරලා Dev GitOps update කරනවා.

## පළවෙනි pipeline එකෙන් පස්සේ automatically run වෙන දේ

App pipeline එක GitOps repo එකට commit push කළාම automatically run වෙන්නේ:

    aks-capstone-gitops
      Validate GitOps manifests

ඊට පස්සේ Argo CD Dev app එක sync කරනවා.

## Dev verify කරන්න user run කරන්න ඕන workflow එක

Dev app sync වුණාට පස්සේ user run කරන්න ඕන workflow එක:

    aks-capstone-store-app
      Verify Dev release end-to-end

මෙය Dev release එක ඇත්තටම workingද කියලා prove කරනවා.

## QA වලට යවන්න user run කරන්න ඕන workflow එක

Dev verification pass නම් user run කරන්න ඕන workflow එක:

    aks-capstone-gitops
      Promote store-front image

Input:

    target_environment: qa
    image_tag: Dev වල verify කළ image tag එක

## Prod වලට යවන්න user run කරන්න ඕන workflow එක

QA validation pass නම් user run කරන්න ඕන workflow එක:

    aks-capstone-gitops
      Promote store-front image

Input:

    target_environment: prod
    image_tag: QA වල verify කළ image tag එක

## Manual සහ automatic steps

Manual steps:

    App build and Dev GitOps update workflow
    Dev release verification workflow
    QA promotion workflow
    Prod promotion workflow

Automatic steps:

    GitOps validation workflow after GitOps push
    Argo CD sync after GitOps desired state change

## Manual promotion වැදගත් ඇයි?

QA සහ Prod promotion automatic කරන එක හැම project එකකටම හොඳ නෑ.

විශේෂයෙන් Prod promotion එක human decision එකක් වෙන්න ඕන.

Manual promotion use කරන එකෙන්:

    userට control තියෙනවා
    wrong image එක Prod යන risk අඩු වෙනවා
    learning project එකේ flow එක clear වෙනවා
    approval-style release thinking එක build වෙනවා

## Build once, promote same image

මෙම project එකේ important release principle එක:

    Build once.
    Promote same image.

Dev වල build කළ image එකම QA වලට යවන්න.

QA වල verify කළ image එකම Prod වලට යවන්න.

QA හෝ Prod වලට අලුතින් rebuild කළ image එකක් යවන්න එපා.

මෙයින් ලැබෙන වාසි:

    traceability හොඳයි
    Dev/QA/Prod අතර artifact එක same
    rollback planning ලේසි
    release confidence වැඩි

## GitHub Actions UI එකේ stages පේන්නේ නැත්තේ ඇයි?

GitHub Actions වල Azure DevOps වගේ explicit stage view එකක් නෑ.

GitHub Actions structure එක:

    Workflow
      -> Job
          -> Steps

ඒ නිසා අපි workflow steps numbered කරලා තියෙනවා.

උදාහරණයක්:

    [01] Checkout GitOps repo
    [02] Validate promotion input
    [03] Update target overlay image tag

මෙය learnerට pipeline එකේ current phase එක හොයාගන්න උදව් වෙනවා.

## User workflows බලන්න ඕන තැන්

App build සහ Dev verification බලන්න:

    aks-capstone-store-app
      Actions tab

GitOps validation සහ QA/Prod promotion බලන්න:

    aks-capstone-gitops
      Actions tab

Argo CD health බලන්න:

    kubectl get applications -n argocd

## Current final workflow list

App repo workflows:

    Build store-front and deploy Dev via GitOps
    Verify Dev release end-to-end

GitOps repo workflows:

    Validate GitOps manifests
    Promote store-front image

Argo CD apps:

    capstone-store-dev
    capstone-store-qa
    capstone-store-prod

## Final project state after Stage 16

Stage 16 අවසානයේ verified state එක:

    capstone-store-dev    Synced / Healthy
    capstone-store-qa     Synced / Healthy
    capstone-store-prod   Synced / Healthy

QA promotion:

    success

Prod promotion:

    success

QA store-front service:

    ClusterIP

Prod store-front service:

    ClusterIP

MongoDB:

    probe/resource tuning පස්සේ stable

## Stage 17 වලින් add කරන්නේ මොනවාද?

Stage 17 වලින් new infrastructure add කරන්නේ නෑ.

Stage 17 වලින් add කරන්නේ:

    pipeline flow explanation
    repo responsibility explanation
    manual vs automatic step explanation
    Dev -> QA -> Prod release journey explanation
    troubleshooting guidance

## Stage 17 ලියන්නේ Stage 16 පස්සේ ඇයි?

Stage 16ට කලින් QA/Prod promotion flow complete නැහැ.

Stage 16 වලදී add වුණේ:

    QA overlay
    Prod overlay
    QA Argo CD app
    Prod Argo CD app
    promotion workflow
    MongoDB stability improvement
    QA/Prod ClusterIP service design

ඒ නිසා Stage 17 guide එක Stage 16 පස්සේ ලියන එක තමයි correct.

## Production lessons

### 1. Pipelines කිහිපයක් තිබීම normal

Real projects වල app build, GitOps validation, release verification, promotion වගේ වැඩ එක pipeline එකකම නොවෙන්න පුළුවන්.

Pipelines කිහිපයක් තිබුණත් responsibility clear නම් ඒක හොඳ pattern එකක්.

### 2. Documentation DevOps quality එකේ කොටසක්

Automation තිබුණත් userට flow එක තේරෙන්නේ නැත්නම් project එක complete නෑ.

Good DevOps project එකක documentationත් strong වෙන්න ඕන.

### 3. GitOps build සහ deploy වෙන් කරනවා

App pipeline එක image build කරනවා.

GitOps repo එක desired state define කරනවා.

Argo CD desired state cluster එකට sync කරනවා.

මෙය GitOps model එකේ core idea එක.

### 4. Promotion intentional වෙන්න ඕන

QA සහ Prod promotion human decision එකක් විය යුතුයි.

Manual workflow_dispatch මේ learning project එකට හොඳ approach එකක්.

### 5. Final verification අනිවාර්යයි

Pipeline pass වුණා කියලා app userට වැඩ කරනවා කියලා assume කරන්න බැහැ.

ඒ නිසා Dev verification workflow එක Gateway HTTP 200 දක්වා check කරනවා.

### 6. Naming clear නම් learnerට ලේසියි

Workflow names සහ step names clear නම් GitHub Actions UI එකේ flow එක ලේසියෙන් තේරෙනවා.

## Troubleshooting

### Issue 1 - Workflow එක හොයාගන්න බැහැ

මුලින් correct repo එක open කරලා තියෙනවද බලන්න.

App workflows තියෙන්නේ:

    aks-capstone-store-app

GitOps workflows තියෙන්නේ:

    aks-capstone-gitops

CLI check:

    gh workflow list

### Issue 2 - GitOps validation auto run වෙන්නේ නැහැ

GitOps repo main branch එකට commit push වුණාද බලන්න.

Commands:

    git log --oneline -5
    gh run list --workflow="validate-gitops-manifests.yml" --limit 5

### Issue 3 - Argo CD update වෙන්නේ නැහැ

Argo CD applications status බලන්න:

    kubectl get applications -n argocd

Hard refresh කරන්න:

    kubectl annotate application <app-name> -n argocd \
      argocd.argoproj.io/refresh=hard \
      --overwrite

### Issue 4 - Target environment image update වෙලා නැහැ

Overlay file එක බලන්න:

    apps/capstone-store/overlays/qa/kustomization.yaml
    apps/capstone-store/overlays/prod/kustomization.yaml

Actual deployment image බලන්න:

    kubectl get deployment store-front -n <namespace> \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

### Issue 5 - QA/Prod service public IP එකක් ගන්නවා

QA/Prod store-front service expected type එක:

    ClusterIP

If `LoadBalancer` පේනවා නම් overlay patch එක check කරන්න:

    patch-store-front-service.yaml

Rendered manifest check කරන්න:

    kubectl kustomize apps/capstone-store/overlays/qa
    kubectl kustomize apps/capstone-store/overlays/prod

### Issue 6 - Argo CD Synced නමුත් Progressing

Pods check කරන්න:

    kubectl get pods -n <namespace>

Pod logs බලන්න:

    kubectl logs <pod-name> -n <namespace> --tail=100

Pod events බලන්න:

    kubectl describe pod <pod-name> -n <namespace>

## Learner summary

Stage 17 වලින් pipeline flow එක පැහැදිලි වුණා.

දැන් project එකේ complete release story එක:

    app image build කරනවා
    security scans run කරනවා
    image ACR එකට push කරනවා
    GitOps desired state update කරනවා
    GitOps manifests validate කරනවා
    Argo CD Dev sync කරනවා
    Dev release verify කරනවා
    same image QA වලට promote කරනවා
    same image Prod වලට promote කරනවා

මතක තබාගන්න ඕන main idea එක:

    App pipeline artifact එක හදනවා.
    GitOps pipeline desired state validate කරනවා.
    Argo CD desired state deploy කරනවා.
    Verification pipeline release එක prove කරනවා.
    Promotion pipeline same image එක environment අතර move කරනවා.

Next stages:

    AIOps PR remediation
    platform Terraform CI
    final README and architecture cleanup
    DNS and TLS later
