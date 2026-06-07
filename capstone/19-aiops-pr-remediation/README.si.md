# Stage 19 - AIOps PR Remediation Workflow

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි AIOps remediation workflow එකක් implement කරලා verify කරනවා.

මෙහි ප්‍රධාන idea එක:

    AIOps incident එක detect කරනවා.
    Evidence collect කරනවා.
    Root cause හඳුනාගන්නවා.
    Safe fix එකක් නම් GitHub PR එකක් create කරනවා.
    Human review/merge කරනවා.
    GitOps validation run වෙනවා.
    Argo CD cluster එකට fix එක apply කරනවා.
    Recovery verify කරනවා.

මෙම stage එකේදී AIOps direct cluster change කරන්නේ නැහැ.

AIOps කරන්නේ GitOps repo එකට pull request එකක් create කිරීම පමණයි.

## මේ stage එක වැදගත් ඇයි?

Production environment එකක AIOps system එකක් automatically cluster එක modify කරන එක risky.

හොඳ pattern එක:

    Detect
    Evidence
    Analysis
    Recommendation
    Pull request
    Human approval
    GitOps deploy
    Recovery verification

මේකෙන් control එක human reviewer ළඟ තියෙනවා. AIOps system එක evidence සහ safe fix proposal එකක් දෙයි. Change එක apply වෙන්නේ PR merge වුණාට පස්සේ GitOps/Argo CD හරහා.

## හැම incident එකකටම PR create කරනවද?

නැහැ.

AIOps හැම scenario එකකටම PR create කරන්න හොඳ නැහැ.

PR create කරන්න හොඳ වන්නේ:

    issue එක evidence වලින් පැහැදිලිව prove කරන්න පුළුවන් නම්
    fix එක GitOps manifest change එකක් නම්
    fix එක low-risk නම්
    fix එක reversible නම්
    exact file/path එක known නම්
    human review එකෙන් පස්සේ merge කරන්න පුළුවන් නම්

PR create නොකර report/recommendation විතරක් දෙන්න හොඳ වන්නේ:

    Node NotReady
    node pressure
    unclear CrashLoopBackOff
    application code bug
    database dependency outage
    security scan failure
    unknown infrastructure issue

මෙම stage එකේදී අපි low-risk deterministic scenario එකක් use කරනවා.

## Stage 19 scenario

Scenario එක:

    Service has no endpoints

Root cause:

    Service selector එක pod labels එක්ක match වෙන්නේ නැහැ.

Expected incident state:

    Pod Running
    Service exists
    Service selector wrong
    Endpoints empty

මෙය AIOps PR remediation සඳහා හොඳ scenario එකක්. මොකද root cause එක evidence වලින් prove කරන්න පුළුවන්.

## Isolated AIOps demo app එක

Main capstone-store Dev/QA/Prod app එක break නොකර AIOps demo එක වෙනම app එකක් විදිහට add කළා.

GitOps repo:

    aks-capstone-gitops

AIOps demo path:

    apps/capstone-aiops-demo

Argo CD application:

    argocd/applications/capstone-aiops-demo.yaml

Namespace:

    capstone-aiops-demo

මෙම design එකෙන් main application environments stable තියෙනවා:

    capstone-dev
    capstone-qa
    capstone-prod

AIOps incident testing වෙනම namespace එකක වෙනවා:

    capstone-aiops-demo

## GitOps files added

AIOps demo app එකට GitOps repo එකේ files add කළා.

Main files:

    apps/capstone-aiops-demo/base/deployment.yaml
    apps/capstone-aiops-demo/base/service.yaml
    apps/capstone-aiops-demo/base/kustomization.yaml
    apps/capstone-aiops-demo/overlays/dev/kustomization.yaml
    argocd/applications/capstone-aiops-demo.yaml

Initial incident එක base service manifest එකේ හිතලා create කළා.

Wrong selector:

    app: wrong-aiops-demo

Deployment pod label:

    app: aiops-demo

මේ නිසා pod Running වුණත් Service endpoints empty වෙනවා.

## Argo CD AppProject permission lesson

AIOps demo Application එක මුලින් Unknown/Unknown වුණා.

Error එක:

    application destination server and namespace do not match allowed destinations in project capstone

Reason එක:

    capstone AppProject එක allowed destinations list එකේ capstone-aiops-demo namespace එක තිබුණේ නැහැ.

Manual patch එකකින් unblock කළා. පස්සේ ඒ change එක source-controlled කළා.

Source-controlled file:

    argocd/projects/capstone-project.yaml

Allowed destination එක add කළා:

    namespace: capstone-aiops-demo
    server: https://kubernetes.default.svc

මෙම lesson එක වැදගත්:

    cluster-side manual patch එකක් පමණක් කරලා නවත්වන්න එපා.
    final source of truth එක GitOps repo එකේ track කරන්න ඕන.

## Incident evidence

Incident state එක verify කළා.

Pod state:

    aiops-demo pod Running
    app=aiops-demo label තියෙනවා

Service state:

    aiops-demo service exists
    selector app=wrong-aiops-demo

Endpoints:

    <none>

Evidence summary:

    Service selector: app=wrong-aiops-demo
    Pod label: app=aiops-demo
    Endpoints: none

Root cause:

    Service selector pod label එකට match වෙන්නේ නැහැ.

## AIOps PR remediation tool

AIOps remediation tool එක GitOps repo එකට add කළා.

Tool path:

    tools/aiops/service-selector-pr-remediator.py

මෙම script එක කරන්නේ:

    live cluster evidence collect කරනවා
    Service selector read කරනවා
    Deployment pod template labels read කරනවා
    Endpoints empty ද බලනවා
    selector mismatch prove කරනවා
    GitOps service.yaml file patch කරනවා
    branch create කරනවා
    commit push කරනවා
    GitHub PR create කරනවා

මෙම script එක direct cluster fix කරන්නේ නැහැ.

## PR remediation flow

AIOps tool එක PR එකක් create කළා.

PR example:

    AIOps fix aiops-demo service selector

PR එකේ change එක:

    app: wrong-aiops-demo

to:

    app: aiops-demo

මෙම PR එක human review කරලා merge කළා.

Merge වුණාට පස්සේ:

    GitOps validation workflow auto-ran
    Argo CD synced
    Service selector fixed
    Endpoints recovered

## GitOps validation after PR

PR open වුණාම GitOps validation workflow pull_request event එකෙන් run වුණා.

PR merge වුණාම GitOps validation workflow push event එකෙන් run වුණා.

Validation workflow jobs:

    YAML Syntax Validation
    Kustomize Render
    Kubeconform Kubernetes Validation
    GitOps Validation Summary

Stage 19 වලදී GitOps validation workflow එකට AIOps demo overlay path එකත් add කළා.

AIOps demo path:

    apps/capstone-aiops-demo/overlays/dev

මෙයින් AIOps demo app එකත් GitOps validation pipeline එකෙන් cover වෙනවා.

## Recovery verification

PR merge එකෙන් පස්සේ recovery verify කළා.

Argo CD:

    capstone-aiops-demo Synced / Healthy

Service selector:

    app=aiops-demo

Pod label:

    app=aiops-demo

Endpoints:

    pod-ip:80

EndpointSlice:

    pod-ip on port 80

මෙයින් service recovery confirm වුණා.

## Final verified state

Final verified state:

    AIOps demo app source-controlled
    AIOps namespace AppProject destination source-controlled
    AIOps PR remediation tool source-controlled
    GitOps validation includes AIOps demo overlay
    AIOps remediation PR created
    Human merge completed
    GitOps validation passed
    Argo CD synced
    Service endpoints recovered

## Commands - current state verify කිරීම

GitOps repo එකට යන්න:

    cd <your-local-path>/aks-capstone-gitops

Argo CD applications බලන්න:

    kubectl get applications -n argocd

AIOps demo app බලන්න:

    kubectl get application capstone-aiops-demo -n argocd

Pods බලන්න:

    kubectl get pods -n capstone-aiops-demo --show-labels

Service බලන්න:

    kubectl describe svc aiops-demo -n capstone-aiops-demo

Endpoints බලන්න:

    kubectl get endpoints aiops-demo -n capstone-aiops-demo

EndpointSlice බලන්න:

    kubectl get endpointslice -n capstone-aiops-demo

GitOps validation runs බලන්න:

    gh run list --workflow="validate-gitops-manifests.yml" --limit 5

## AIOps tool run කරන විදිහ

මෙම tool එක run කරන්න:

    cd <your-local-path>/aks-capstone-gitops

    python3 tools/aiops/service-selector-pr-remediator.py

Tool එක PR create කරන්නේ Service endpoints empty සහ selector mismatch evidence තියෙන විට පමණයි.

Service already fixed නම් tool එක මෙහෙම කියයි:

    Service already has endpoints. No remediation PR needed.

## Safety design

මෙම AIOps flow එක safe වන්නේ:

    cluster එක direct modify නොකරන නිසා
    GitOps repo එකට PR create කරන නිසා
    human review/merge අවශ්‍ය නිසා
    GitOps validation pass විය යුතු නිසා
    Argo CD controlled sync කරන නිසා
    recovery verify කරන නිසා

මෙය production-style pattern එකක්.

## Troubleshooting

### Application Unknown / Unknown නම්

AppProject destination permission බලන්න:

    kubectl describe application capstone-aiops-demo -n argocd

    kubectl get appproject capstone -n argocd -o yaml

capstone-aiops-demo namespace allowed destinations list එකේ නැත්නම් source-controlled file එක check කරන්න:

    argocd/projects/capstone-project.yaml

### Pod Running නමුත් endpoints empty නම්

Service selector සහ pod labels compare කරන්න:

    kubectl describe svc aiops-demo -n capstone-aiops-demo

    kubectl get pods -n capstone-aiops-demo --show-labels

Mismatch එකක් තිබුණොත් Service selector fix කළ යුතුයි.

### PR create නොවුණොත්

Check කරන්න:

    gh auth status
    git status
    current branch
    GitHub token permissions
    branch already exists ද
    service already recovered ද

### GitOps validation fail වුණොත්

Fail වූ job එක බලන්න:

    YAML Syntax Validation
    Kustomize Render
    Kubeconform Kubernetes Validation

YAML indentation issue එකක් තිබුණොත් first fix කරන්න. Kustomize render issue එකක් තිබුණොත් overlay path එක render කරලා බලන්න:

    kubectl kustomize apps/capstone-aiops-demo/overlays/dev

### Endpoints still empty නම්

Check කරන්න:

    Service selector
    Pod labels
    Pod Ready status
    EndpointSlice
    Argo CD sync revision

Commands:

    kubectl get application capstone-aiops-demo -n argocd

    kubectl get pods -n capstone-aiops-demo --show-labels

    kubectl describe svc aiops-demo -n capstone-aiops-demo

    kubectl get endpointslice -n capstone-aiops-demo

## Production learning points

### 1. AIOps should not blindly remediate everything

හැම incident එකකටම PR create කරන්න එපා.

Low-risk, proven, GitOps-manifest-level fixes වලට විතරක් PR create කරන්න.

### 2. Evidence first

AIOps system එක fix propose කරන්න කලින් evidence collect කරන්න ඕන.

මෙම scenario එකේ evidence:

    Service selector
    Pod labels
    Endpoints

### 3. Human approval is important

AIOps PR create කළාට merge කරන්නේ human reviewer.

මෙයින් accidental changes reduce වෙනවා.

### 4. GitOps keeps the cluster controlled

Cluster fix එක direct kubectl patch එකකින් නොකර GitOps PR එකකින් කළා.

Argo CD source of truth එක apply කළා.

### 5. Isolated incident apps are useful

Production-like demo projects වල main application break නොකර isolated incident app එකක් use කිරීම හොඳයි.

### 6. Source-control manual fixes

AppProject permission එක manual patch කළා නම් ඒක source-controlled manifest එකටත් add කරන්න ඕන.

### 7. EndpointSlice is the modern view

Kubernetes newer versions වල v1 Endpoints deprecated warning පෙන්වන්න පුළුවන්.

EndpointSlice ද බලන්න:

    kubectl get endpointslice -n capstone-aiops-demo

## Learner summary

Stage 19 වලදී අපි AIOps PR remediation workflow එක prove කළා.

අපි කළේ:

    isolated AIOps demo app එකක් add කළා
    Service selector mismatch incident එකක් create කළා
    endpoints empty බව verify කළා
    AIOps tool එක evidence collect කළා
    root cause identify කළා
    GitHub PR create කළා
    human merge කළා
    GitOps validation pass වුණා
    Argo CD sync වුණා
    endpoints recover වුණා

මෙම stage එකෙන් project එකට production-style safe AIOps remediation pattern එකක් add වුණා.

Next improvements:

    more AIOps scenarios add කිරීම
    Slack/Alertmanager notification
    confidence scoring
    high-risk scenarios සඳහා recommendation-only reports
    AIOps workflow status dashboard
