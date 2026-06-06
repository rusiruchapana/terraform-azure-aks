# Stage 16 - Dev to QA to Prod Promotion Workflow

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි Dev environment එකෙන් QA environment එකටත්, QA environment එකෙන් Prod environment එකටත් application image එක promote කරන GitOps workflow එකක් හදනවා.

මෙහි main idea එක:

    Build once.
    Test in Dev.
    Promote the same image to QA.
    Promote the same image to Prod.

QA සහ Prod වලට image එක නැවත build කරන්නේ නැහැ.

Dev වල build කරලා scan කරලා verified වූ image tag එකම QA සහ Prod වලට promote කරනවා.

## මේ stage එක වැදගත් ඇයි?

Real production delivery වලදී environment එකෙන් environment එකට application එක යන්නේ normally මෙහෙමයි:

    Dev
      -> QA
      -> Prod

Dev වල image එක build කරලා test කරනවා.

QA වල testers / validation checks run කරනවා.

Prod වල usersට release කරනවා.

මේ flow එකේදී වැදගත් rule එකක් තියෙනවා:

    QA වලට සහ Prod වලට වෙන වෙනම image rebuild කරන්න හොඳ නැහැ.

ඒකට හේතුව:

    Dev image එක test කළා.
    QA වලට වෙන image එකක් build කළොත් Dev වල test කළ image එකම නෙවෙයි.
    Prod වලට තවත් image එකක් build කළොත් QA වල verified image එකම නෙවෙයි.

ඒ නිසා production-safe pattern එක:

    එකම image tag එක promote කිරීම

## Stage 16 high-level flow

Stage 16 flow එක:

    Dev environment
        image: store-front:<tag>

    Promote to QA
        update QA GitOps overlay newTag

    Argo CD syncs QA
        QA deployment uses same image tag

    Promote to Prod
        update Prod GitOps overlay newTag

    Argo CD syncs Prod
        Prod deployment uses same image tag

## Repositories involved

මෙම stage එකට repositories කිහිපයක් සම්බන්ධයි.

App repo:

    aks-capstone-store-app

මෙහිදී image build, scan, push, Dev update, Dev release verification workflows තියෙනවා.

GitOps repo:

    aks-capstone-gitops

මෙහිදී Kubernetes manifests, environment overlays, Argo CD Applications, promotion workflow තියෙනවා.

Terraform/platform repo:

    terraform-azure-aks

මෙහිදී platform code සහ learning guides තියෙනවා.

Stage 16 implementation වැඩිම කොටස තියෙන්නේ:

    aks-capstone-gitops

මොකද promotion කියන්නේ GitOps desired state update කිරීමක්.

## Stage 16 වලට පෙර තිබූ state

Stage 15 අවසානයේ Dev release verification workflow එක success වුණා.

Dev release verification workflow එක verify කළේ:

    ACR image exists
    GitOps image tag correct
    GitOps validation passed
    Argo CD Synced and Healthy
    AKS deployment correct image use කරනවා
    Pod Running
    Gateway HTTP 200

Stage 16 පටන් ගන්න කලින් Dev flow stable තිබුණා.

## Stage 16 වලදී add කළ main parts

මෙම stage එකේදී අපි add කළ දේවල්:

    QA GitOps overlay
    Prod GitOps overlay
    QA Argo CD Application
    Prod Argo CD Application
    QA/Prod ClusterIP service design
    store-front promotion workflow
    MongoDB stability improvement

## GitOps overlay structure

GitOps repo එකේ app manifests structure එක:

    apps/capstone-store/base
    apps/capstone-store/overlays/dev
    apps/capstone-store/overlays/qa
    apps/capstone-store/overlays/prod

Base folder එකේ common Kubernetes manifests තියෙනවා.

Environment overlays වල environment-specific configuration තියෙනවා.

Example:

    dev overlay:
      namespace: capstone-dev
      environment label: dev
      image tag override

    qa overlay:
      namespace: capstone-qa
      environment label: qa
      image tag override

    prod overlay:
      namespace: capstone-prod
      environment label: prod
      image tag override

## Base සහ overlay අතර වෙනස

Base folder එකේ common resources තියෙනවා:

    Deployments
    StatefulSets
    Services
    common app components

Overlay folder එකේ environment-specific values තියෙනවා:

    namespace
    labels
    image tag
    patches

මෙම approach එකෙන් එකම application එක Dev, QA, Prod ලෙස වෙන වෙනම deploy කරන්න පුළුවන්.

## Dev overlay

Dev overlay path එක:

    apps/capstone-store/overlays/dev

Dev overlay එක use කරන්නේ:

    capstone-dev namespace

Dev environment එකට external access අවශ්‍ය නිසා Dev overlay එකට HTTPRoute තිබුණා.

Dev Argo CD app source path එක:

    apps/capstone-store/overlays/dev

## QA overlay

QA overlay path එක:

    apps/capstone-store/overlays/qa

QA overlay එක use කරන්නේ:

    capstone-qa namespace

QA overlay එකේ image override එක තියෙනවා.

Example:

    images:
      - name: <acr-login-server>/store-front
        newTag: stage13-v1

මෙම `newTag` value එක promotion workflow එකෙන් update කරනවා.

## Prod overlay

Prod overlay path එක:

    apps/capstone-store/overlays/prod

Prod overlay එක use කරන්නේ:

    capstone-prod namespace

Prod overlay එකේ image override එකත් තියෙනවා.

Example:

    images:
      - name: <acr-login-server>/store-front
        newTag: stage13-v1

Prod promotion workflow එකෙන් Prod overlay `newTag` update කරනවා.

## QA/Prod services ClusterIP කරන්නේ ඇයි?

QA සහ Prod create කළාම මුලින් `store-front` Service එක `LoadBalancer` ලෙස create වුණා.

ඒකෙන් QA සහ Prod වලට වෙන වෙනම public IPs create වුණා.

මෙය production සහ cost perspective එකෙන් හොඳ pattern එකක් නෙවෙයි.

Problem:

    QA වලට separate public LoadBalancer
    Prod වලට separate public LoadBalancer
    unnecessary public exposure
    extra cloud cost
    security risk

Fix:

    QA/Prod store-front Service type ClusterIP කළා

මෙම patch එක environment overlays වලට add කළා:

    patch-store-front-service.yaml

Final desired state:

    QA store-front service:
      ClusterIP

    Prod store-front service:
      ClusterIP

External access later controlled way එකකට Gateway / HTTPRoute / DNS / TLS හරහා design කරන්න පුළුවන්.

## QA/Prod Argo CD Applications

Stage 16 වලදී QA සහ Prod සඳහා Argo CD Applications දෙකක් create කළා.

QA app:

    capstone-store-qa

QA source path:

    apps/capstone-store/overlays/qa

QA destination namespace:

    capstone-qa

Prod app:

    capstone-store-prod

Prod source path:

    apps/capstone-store/overlays/prod

Prod destination namespace:

    capstone-prod

## Argo CD Applications final list

Final Argo CD Applications:

    capstone-namespaces
    capstone-store-dev
    capstone-store-qa
    capstone-store-prod

Expected final status:

    Synced / Healthy

## Promotion workflow

Promotion workflow එක GitOps repo එකේ තියෙනවා.

Workflow file:

    .github/workflows/promote-store-front.yml

Workflow name:

    Promote store-front image

Workflow trigger:

    workflow_dispatch

මෙය manual workflow එකක්.

User manually select කරනවා:

    target_environment
    image_tag

## Promotion workflow inputs

Promotion workflow inputs:

    target_environment
    image_tag

target_environment allowed values:

    qa
    prod

image_tag example:

    stage13-v1

මෙම input වලින් workflow එක target environment overlay එක update කරනවා.

## Promotion workflow steps

Promotion workflow එකේ numbered steps:

    [01] Checkout GitOps repo
    [02] Validate promotion input
    [03] Update target overlay image tag
    [04] Render target overlay with Kustomize
    [05] Commit and push promotion change
    [06] Promotion summary

Numbered step names use කළේ GitHub Actions UI එකේ learnerට current phase එක ලේසියෙන් හඳුනාගන්න.

## Step [01] - Checkout GitOps repo

මෙම step එක GitOps repo source code checkout කරනවා.

Promotion workflow එක GitOps repo එකේ run වෙන නිසා default checkout එකම GitOps repo එක checkout කරනවා.

## Step [02] - Validate promotion input

මෙම step එක user දීපු input validate කරනවා.

Validation rules:

    target_environment must be qa or prod
    image_tag cannot be empty

Invalid target environment එකක් දුන්නොත් workflow fail වෙනවා.

මෙය accidental wrong environment update වීම නවත්වන guardrail එකක්.

## Step [03] - Update target overlay image tag

මෙම step එක target environment overlay එකේ `newTag` update කරනවා.

If target_environment is qa:

    apps/capstone-store/overlays/qa/kustomization.yaml

If target_environment is prod:

    apps/capstone-store/overlays/prod/kustomization.yaml

Example:

    newTag: stage13-v1

මෙහිදී image rebuild වෙන්නේ නැහැ.

GitOps desired state update වෙනවා.

## Step [04] - Render target overlay with Kustomize

Promotion change එක commit කරන්න කලින් target overlay එක render කරනවා.

Example concept:

    kubectl kustomize apps/capstone-store/overlays/qa

or:

    kubectl kustomize apps/capstone-store/overlays/prod

මෙම step එකෙන් verify කරනවා:

    overlay structure valid ද?
    image tag rendered output එකේ correct ද?
    store-front service ClusterIP ද?

මෙය promotion workflow එක ඇතුළේ pre-commit validation එකක්.

## Step [05] - Commit and push promotion change

If image tag change එකක් තියෙනවා නම් workflow එක commit කරලා push කරනවා.

Example commit:

    Promote store-front stage13-v1 to qa

or:

    Promote store-front stage13-v1 to prod

If target environment already same image tag use කරනවා නම්:

    No promotion change to commit

මෙය failure එකක් නෙවෙයි.

ඒකෙන් අදහස් වෙන්නේ target environment already expected image tag එක use කරනවා.

## Step [06] - Promotion summary

Workflow summary එක GitHub Actions summary tab එකට ලියනවා.

Summary එකේ පෙන්වන දේවල්:

    target environment
    image tag
    GitOps overlay path
    next actions

මෙය learner/user visibility වැඩි කරනවා.

## QA promotion test

QA promotion run කළා:

    target_environment: qa
    image_tag: stage13-v1

Result:

    success

Run ID:

    27057893963

මෙම run එකෙන් confirm වුණා:

    promotion workflow qa target එකට run වෙනවා
    QA overlay update/render logic pass වෙනවා
    workflow summary generate වෙනවා

## Prod promotion test

Prod promotion run කළා:

    target_environment: prod
    image_tag: stage13-v1

Result:

    success

Run ID:

    27058202587

මෙම run එකෙන් confirm වුණා:

    promotion workflow prod target එකට run වෙනවා
    Prod overlay update/render logic pass වෙනවා
    Prod target environment support කරනවා

## GitOps validation after promotion

Promotion workflow GitOps repo එකට change push කළාම GitOps validation workflow auto run වෙනවා.

GitOps validation workflow:

    Validate GitOps manifests

මෙය check කරනවා:

    YAML syntax
    Kustomize render
    Kubernetes schema validation

Stage 16 වල fixes පස්සේ GitOps validation pass වුණා.

## QA/Prod initial LoadBalancer issue

QA/Prod environments create කළ පසු මුලින් `store-front` Services `LoadBalancer` ලෙස create වුණා.

Observed problem:

    QA store-front Service had public external IP
    Prod store-front Service had public external IP

මෙය avoid කළ යුතුයි.

Fix:

    QA/Prod overlays වල patch-store-front-service.yaml add කළා
    Service type ClusterIP කළා

Final verified state:

    QA store-front Service: ClusterIP
    Prod store-front Service: ClusterIP
    External IP: none

## Argo CD OutOfSync lesson

QA/Prod create කරන අතරතුර Argo CD OutOfSync / Progressing status පෙන්වුණා.

මෙයින් ඉගෙනගන්න වැදගත් lesson එක:

    GitOps desired state correct වුණා කියලා
    cluster actual state correct කියලා assume කරන්න එපා.

Always verify:

    rendered manifest
    Argo CD status
    actual Kubernetes object

Example checks:

    kubectl kustomize
    kubectl get applications -n argocd
    kubectl get svc -n capstone-qa
    kubectl get svc -n capstone-prod

## MongoDB stability issue

QA/Prod environments create කළාට පසු MongoDB pod restarts / CrashLoopBackOff issue එකක් දක්නට ලැබුණා.

Observed:

    mongodb-0 readiness/liveness probe failures
    liveness probe timeout
    container restarts
    QA app Progressing

Root cause:

    MongoDB resources too low
    CPU limit too aggressive
    readiness/liveness probe timing too short
    MongoDB startup slow under shared node resources

Original settings were enough for initial Dev demo, but not stable enough when Dev/QA/Prod environments were running together.

## Stage 09 fully wrong ද?

නැහැ.

Stage 09 වල MongoDB introduce කළා.

Stage 09 goal එක:

    Dev app dependencies add කිරීම
    MongoDB run කිරීම
    makeline-service run කිරීම

ඒ setup එක Dev වල වැඩ කළා.

Stage 16 වලදී Dev/QA/Prod environments තුනම එකට run කරන විට real stability issue එකක් expose වුණා.

ඒ නිසා Stage 16 වලදී MongoDB resource/probe settings improve කළා.

මෙය Stage 09 replacement එකක් නෙවෙයි.

මෙය production-style stability improvement එකක්.

Latest repo version use කරන user කෙනෙක්ට improved MongoDB settings already apply වෙනවා.

## MongoDB fix

MongoDB base manifest update කළා.

File:

    apps/capstone-store/base/makeline-mongodb.yaml

Updated resource requests:

    cpu: 50m
    memory: 128Mi

Updated resource limits:

    cpu: 250m
    memory: 1024Mi

Updated liveness probe:

    initialDelaySeconds: 120
    periodSeconds: 20
    timeoutSeconds: 10
    failureThreshold: 6

Updated readiness probe:

    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 10
    failureThreshold: 12

## Why fix in base manifest?

MongoDB manifest එක base folder එකේ තියෙනවා.

Dev, QA, Prod overlays තුනම base manifest එක inherit කරනවා.

ඒ නිසා base manifest එක improve කළාම environments තුනම benefit වෙනවා.

Final result:

    Dev MongoDB stable
    QA MongoDB stable
    Prod MongoDB stable

## MongoDB final verified state

After probe/resource tuning:

    Dev MongoDB:
      1/1 Running
      restarts 0 after fix

    QA MongoDB:
      1/1 Running
      restarts 0 after fix

    Prod MongoDB:
      1/1 Running
      restarts 0 after fix

Argo CD final status:

    capstone-store-dev   Synced / Healthy
    capstone-store-qa    Synced / Healthy
    capstone-store-prod  Synced / Healthy

## Final verified state - අවසාන verified තත්ත්වය

Stage 16 final state:

    QA GitOps overlay created
    Prod GitOps overlay created
    QA Argo CD Application created
    Prod Argo CD Application created
    QA promotion workflow tested
    Prod promotion workflow tested
    QA/Prod services corrected to ClusterIP
    MongoDB stability issue fixed
    Dev/QA/Prod all Synced and Healthy

Final app status:

    capstone-store-dev    Synced / Healthy
    capstone-store-qa     Synced / Healthy
    capstone-store-prod   Synced / Healthy

Final image status:

    Dev store-front image:
      <acr-login-server>/store-front:stage13-v1

    QA store-front image:
      <acr-login-server>/store-front:stage13-v1

    Prod store-front image:
      <acr-login-server>/store-front:stage13-v1

Final service status:

    QA store-front Service:
      ClusterIP

    Prod store-front Service:
      ClusterIP

## How to run QA promotion

GitOps repo එකේ Actions tab එකට යන්න.

Workflow select කරන්න:

    Promote store-front image

Run workflow:

    target_environment: qa
    image_tag: stage13-v1

CLI command example:

    gh workflow run promote-store-front.yml \
      -f target_environment=qa \
      -f image_tag=stage13-v1

Watch:

    gh run watch

## How to run Prod promotion

GitOps repo එකේ Actions tab එකට යන්න.

Workflow select කරන්න:

    Promote store-front image

Run workflow:

    target_environment: prod
    image_tag: stage13-v1

CLI command example:

    gh workflow run promote-store-front.yml \
      -f target_environment=prod \
      -f image_tag=stage13-v1

Watch:

    gh run watch

## How to verify QA

QA Argo CD app check කරන්න:

    kubectl get application capstone-store-qa -n argocd

QA image check කරන්න:

    kubectl get deployment store-front -n capstone-qa \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

QA service check කරන්න:

    kubectl get svc store-front -n capstone-qa

Expected:

    Argo CD: Synced / Healthy
    image: <acr-login-server>/store-front:<image-tag>
    service type: ClusterIP

## How to verify Prod

Prod Argo CD app check කරන්න:

    kubectl get application capstone-store-prod -n argocd

Prod image check කරන්න:

    kubectl get deployment store-front -n capstone-prod \
      -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

Prod service check කරන්න:

    kubectl get svc store-front -n capstone-prod

Expected:

    Argo CD: Synced / Healthy
    image: <acr-login-server>/store-front:<image-tag>
    service type: ClusterIP

## Production learning points - production පාඩම්

### 1. Build once, promote same image

Dev, QA, Prod වලට වෙන වෙනම image build කරන්න එපා.

Same image tag එක promote කරන්න.

මෙය traceability සහ confidence වැඩි කරනවා.

### 2. GitOps promotion means desired state update

Promotion workflow එක Kubernetes cluster එකට direct deploy command run කරන්නේ නැහැ.

එය GitOps overlay update කරනවා.

Argo CD desired state detect කරලා cluster එක sync කරනවා.

### 3. Environment overlays make promotion clean

Dev, QA, Prod overlays වෙන වෙනම තියෙන නිසා each environment එකට image tag separately control කරන්න පුළුවන්.

### 4. Public exposure must be intentional

QA/Prod වලට accidental LoadBalancer public IPs create වුණා.

එය cost/security issue එකක්.

Fix:

    ClusterIP services
    controlled Gateway strategy later

### 5. Health is more than deployment

Deployment created වුණා කියලා environment healthy කියලා කියන්න බැහැ.

Verify කරන්න ඕන:

    pods ready
    services correct
    Argo CD healthy
    image tag correct
    dependency services stable

### 6. Probes and resources matter

MongoDB issue එකෙන් ඉගෙනගත්තේ:

    too-low CPU limits
    aggressive probes
    slow startup

මේවා app stability affect කරනවා.

Production වල probes/resources tune කිරීම අනිවාර්යයි.

### 7. GitHub Actions step names should be learner-friendly

Numbered steps use කළා:

    [01]
    [02]
    [03]

එයින් GitHub Actions UI එකේ pipeline phase එක හොයාගන්න ලේසියි.

## Troubleshooting - ගැටළු විසඳීම

### Issue 1 - Promotion workflow not found

Possible causes:

    workflow YAML invalid
    workflow not pushed to main
    GitHub Actions indexing delay

Fix:

    gh workflow list

or run by filename:

    gh workflow run promote-store-front.yml \
      -f target_environment=qa \
      -f image_tag=stage13-v1

### Issue 2 - GitOps validation fails after adding workflow

Possible cause:

    workflow YAML syntax issue
    heredoc indentation issue
    invalid YAML formatting

Fix:

    check failed GitHub Actions logs
    validate YAML locally
    simplify workflow script blocks

### Issue 3 - Promotion update step fails

Possible causes:

    kustomization.yaml does not have newTag
    wrong target_environment
    file path wrong

Fix:

    check target overlay file

    apps/capstone-store/overlays/qa/kustomization.yaml
    apps/capstone-store/overlays/prod/kustomization.yaml

### Issue 4 - Argo CD app OutOfSync

Possible causes:

    GitOps commit not synced yet
    Argo CD refresh delay
    immutable Kubernetes field changes
    cluster actual state differs from desired state

Fix:

    hard refresh Argo CD app
    check actual Kubernetes object
    check rendered manifest

### Issue 5 - QA/Prod Service becomes LoadBalancer

Cause:

    base service type inherited as LoadBalancer

Fix:

    add overlay patch to change service type to ClusterIP

Verify:

    kubectl get svc store-front -n capstone-qa
    kubectl get svc store-front -n capstone-prod

Expected:

    ClusterIP

### Issue 6 - MongoDB CrashLoopBackOff

Symptoms:

    mongodb-0 CrashLoopBackOff
    readiness probe failed
    liveness probe timeout
    Argo CD Progressing

Fix:

    increase CPU request/limit
    relax liveness/readiness probe delays and timeouts

Verify:

    kubectl get pods -n capstone-qa | grep mongodb
    kubectl get pods -n capstone-prod | grep mongodb

Expected:

    mongodb-0   1/1   Running

## Learner summary - ඉගෙනගන්න ප්‍රධාන අදහස

Stage 16 වලදී අපි Dev-only delivery එක multi-environment promotion flow එකක් බවට convert කළා.

Before Stage 16:

    Dev deployment and Dev verification තිබුණා.

After Stage 16:

    Dev, QA, Prod environments තියෙනවා.
    QA/Prod Argo CD apps තියෙනවා.
    GitOps promotion workflow තියෙනවා.
    Same image tag promote කරන්න පුළුවන්.
    QA/Prod service exposure controlled.
    MongoDB stability improved.
    Dev/QA/Prod all Healthy.

Final promotion model:

    Build once
      -> deploy to Dev
      -> promote same image to QA
      -> promote same image to Prod

Next stages can build on this:

    pipeline visibility documentation
    AIOps PR remediation
    platform Terraform CI
    DNS and TLS later
