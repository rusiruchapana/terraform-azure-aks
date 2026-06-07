# Stage 20 - AIOps Incident Dashboard UI

## මේ stage එකේදී මොකක්ද කරන්නේ?

මේ stage එකේදී අපි AIOps incidents බලන්න වෙනම UI එකක් add කරනවා.

මෙම project එකේ UI layers තුනක් වෙනම තියෙන්න ඕන:

    Monitoring UI
    Argo CD UI
    AIOps UI

Monitoring UI එකෙන් metrics සහ alerts බලනවා.

Argo CD UI එකෙන් GitOps sync, health, revision, diff බලනවා.

AIOps UI එකෙන් incidents, evidence, root cause, remediation PR, recovery status බලනවා.

මේ stage එකේදී අපි AIOps Incident Dashboard එකක් හදලා AKS cluster එකට GitOps හරහා deploy කළා.

## මේ stage එක වැදගත් ඇයි?

Stage 19 වලදී AIOps PR remediation flow එක prove කළා.

ඒ flow එකේදී:

    incident detect වුණා
    evidence collect වුණා
    root cause identify වුණා
    GitHub PR create වුණා
    human merge වුණා
    GitOps validation pass වුණා
    Argo CD sync වුණා
    service endpoints recover වුණා

නමුත් userට ඒ incident story එක බලන්න dedicated UI එකක් තිබුණේ නැහැ.

AIOps UI එකේ purpose එක තමයි:

    මොකක්ද incident එක?
    affected namespace/service මොකක්ද?
    evidence මොකක්ද?
    root cause මොකක්ද?
    AIOps මොන decision එකක් ගත්තද?
    PR එක create කළාද?
    PR merge වුණාද?
    GitOps validation pass ද?
    Argo CD sync ද?
    recovery complete ද?

මෙම details Monitoring UI එකට හෝ Argo CD UI එකට mix කරන්න හොඳ නැහැ.

## UI separation

### Monitoring UI

Monitoring UI එකෙන් බලන්නේ:

    CPU
    memory
    pod restarts
    node health
    alerts
    Prometheus targets
    Grafana dashboards

මෙය platform/observability view එක.

### Argo CD UI

Argo CD UI එකෙන් බලන්නේ:

    application sync status
    health status
    Git revision
    manifest diff
    sync history
    application tree

මෙය GitOps/operator view එක.

### AIOps UI

AIOps UI එකෙන් බලන්නේ:

    incident status
    severity
    evidence
    root cause
    recommended action
    PR link
    PR merge status
    GitOps validation status
    Argo CD recovery status
    endpoint recovery

මෙය incident intelligence/remediation view එක.

## Stage 20 architecture

මෙම stage එකේදී lightweight static dashboard එකක් use කරනවා.

Architecture:

    incident report JSON
        ↓
    ConfigMap
        ↓
    nginx dashboard pod
        ↓
    ClusterIP Service
        ↓
    localhost access using background port-forward

මෙම design එක simple සහ low-cost.

Database එකක් නැහැ.

Backend service එකක් නැහැ.

Public internet exposure එකක් නැහැ.

## Why not public URL?

මේ stage එකේදී අපි public access දෙන්නේ නැහැ.

Reason:

    learning project එකක්
    AIOps incident details private විය හැක
    public exposure security risk එකක්
    DNS/TLS stage එක පස්සේ properly handle කරන්න පුළුවන්

දැනට access model එක:

    localhost only

AIOps dashboard URL:

    http://localhost:8088

## GitOps repo changes

GitOps repo:

    aks-capstone-gitops

AIOps dashboard app path:

    apps/capstone-aiops-dashboard

Main files:

    apps/capstone-aiops-dashboard/base/index.html
    apps/capstone-aiops-dashboard/base/incident-report.json
    apps/capstone-aiops-dashboard/base/configmap.yaml
    apps/capstone-aiops-dashboard/base/deployment.yaml
    apps/capstone-aiops-dashboard/base/service.yaml
    apps/capstone-aiops-dashboard/base/kustomization.yaml
    apps/capstone-aiops-dashboard/overlays/dev/kustomization.yaml
    argocd/applications/capstone-aiops-dashboard.yaml

Namespace:

    capstone-aiops

Argo CD Application:

    capstone-aiops-dashboard

## Dashboard content

Dashboard එකේ Stage 19 incident report එක පෙන්වනවා.

Dashboard එකේ main sections:

    Incident Status
    Incident ID
    Severity
    Namespace
    Service
    Root Cause
    Evidence
    Action Taken
    Recovery
    UI separation explanation

Report data source:

    incident-report.json

මෙම JSON file එක ConfigMap එකට mount වෙනවා.

nginx pod එක static HTML සහ JSON serve කරනවා.

## Incident report data

incident-report.json file එකේ include කළ details:

    incident_id
    status
    severity
    scenario
    summary
    affected namespace/service/deployment
    evidence
    root cause
    decision
    action
    recovery

Stage 19 incident report එකේ final status:

    Recovered

Scenario:

    Service has no endpoints

Root cause:

    Service selector mismatch

Before fix:

    Service selector app=wrong-aiops-demo
    Pod label app=aiops-demo
    Endpoints none

After fix:

    Service selector app=aiops-demo
    Endpoints available

## AIOps dashboard deployment

Dashboard deployment එක nginx image එක use කරනවා.

Static content mount කරන්නේ ConfigMap එකෙන්:

    aiops-dashboard-content

Deployment:

    aiops-dashboard

Service:

    aiops-dashboard

Service type:

    ClusterIP

ClusterIP use කරන්නේ public exposure avoid කරන්න.

## Argo CD AppProject permission

AIOps dashboard namespace එක වෙනම නිසා capstone AppProject එකට destination permission add කළා.

Source-controlled file:

    argocd/projects/capstone-project.yaml

Added namespace:

    capstone-aiops

මෙම permission එක live cluster AppProject object එකට apply කළා.

Reason:

    Argo CD Application එක capstone-aiops namespace එකට deploy කරන්න allowed destination එකක් අවශ්‍යයි.

Permission නැතිනම් error එක:

    application destination server and namespace do not match any allowed destinations in project capstone

## GitOps validation update

GitOps validation workflow එකට dashboard overlay path එක add කළා.

Added path:

    apps/capstone-aiops-dashboard/overlays/dev

ඒ නිසා GitOps validation දැන් මේ paths validate කරනවා:

    capstone-store base/overlays
    capstone-aiops-demo overlay
    capstone-aiops-dashboard overlay

Validation jobs:

    YAML Syntax Validation
    Kustomize Render
    Kubeconform Kubernetes Validation
    GitOps Validation Summary

Final GitOps validation passed.

## Localhost UI access

Public URL එකක් නොදී localhost access use කරනවා.

Problem එක:

    kubectl port-forward direct terminal එකක run කළොත් terminal close වුණාම access නැති වෙනවා.

Solution එක:

    background port-forward helper scripts

These scripts live in:

    terraform-azure-aks/scripts/local-ui

Scripts:

    start-local-uis.sh
    status-local-uis.sh
    stop-local-uis.sh

## Start AIOps dashboard UI

terraform repo එකට යන්න:

    cd <your-local-path>/terraform-azure-aks

Start කරන්න:

    ./scripts/local-ui/start-local-uis.sh

AIOps UI open කරන්න:

    http://localhost:8088

## Check local UI status

    ./scripts/local-ui/status-local-uis.sh

Expected:

    aiops-dashboard running with PID

## Stop local UI

    ./scripts/local-ui/stop-local-uis.sh

## Why background port-forward?

මෙය public access දෙන්නේ නැහැ.

නමුත් normal port-forward terminal එක වගේ fragile නැහැ.

Terminal tab එක close වුණත් background process එක run වෙන්න පුළුවන්.

Mac restart වුණොත් නැවත start script එක run කරන්න ඕන.

## Runtime files

Local UI scripts create කරන runtime files:

    .local-ui-pids
    .local-ui-logs

මෙම folders git ignore කළා.

Reason:

    PID files local machine specific
    log files local runtime data
    repository එකට commit කරන්න ඕන නැහැ

## Final verified state

GitOps validation:

    Add AIOps incident dashboard UI passed

Argo CD:

    capstone-aiops-dashboard Synced / Healthy

Pod:

    aiops-dashboard 1/1 Running

Service:

    aiops-dashboard ClusterIP

Access:

    http://localhost:8088

Public exposure:

    none

## Commands - dashboard verify කිරීම

GitOps repo එකට යන්න:

    cd <your-local-path>/aks-capstone-gitops

Argo CD application බලන්න:

    kubectl get application capstone-aiops-dashboard -n argocd

Pods බලන්න:

    kubectl get pods -n capstone-aiops

Service බලන්න:

    kubectl get svc -n capstone-aiops

Dashboard service details බලන්න:

    kubectl describe svc aiops-dashboard -n capstone-aiops

## Commands - GitOps validation බලන්න

    gh run list --workflow="validate-gitops-manifests.yml" --limit 5

Expected latest run:

    Add AIOps incident dashboard UI passed

## Commands - local UI start/status/stop

terraform repo එකට යන්න:

    cd <your-local-path>/terraform-azure-aks

Start:

    ./scripts/local-ui/start-local-uis.sh

Status:

    ./scripts/local-ui/status-local-uis.sh

Stop:

    ./scripts/local-ui/stop-local-uis.sh

## Troubleshooting

### Dashboard Application Unknown නම්

Application describe කරන්න:

    kubectl describe application capstone-aiops-dashboard -n argocd

If allowed destination error එකක් තිබුණොත් AppProject check කරන්න:

    kubectl get appproject capstone -n argocd -o yaml

Source-controlled project file check කරන්න:

    argocd/projects/capstone-project.yaml

Live cluster object update කරන්න:

    kubectl apply -f argocd/projects/capstone-project.yaml

### Namespace not found නම්

Argo CD Application sync වෙලාද බලන්න:

    kubectl get application capstone-aiops-dashboard -n argocd

Application Unknown නම් AppProject destination permission issue එකක් විය හැක.

### Pod Running නොවුණොත්

Pod describe කරන්න:

    kubectl describe pod -n capstone-aiops -l app=aiops-dashboard

Events බලන්න:

    kubectl get events -n capstone-aiops --sort-by='.lastTimestamp'

### localhost open වෙන්නේ නැත්නම්

Port-forward status බලන්න:

    ./scripts/local-ui/status-local-uis.sh

Logs බලන්න:

    cat .local-ui-logs/aiops-dashboard.log

Port already used නම් stop කරලා restart කරන්න:

    ./scripts/local-ui/stop-local-uis.sh
    ./scripts/local-ui/start-local-uis.sh

### JSON load error එකක් dashboard එකේ පේනවා නම්

ConfigMap content verify කරන්න:

    kubectl get configmap aiops-dashboard-content -n capstone-aiops -o yaml

Pod restart කරන්න:

    kubectl rollout restart deployment/aiops-dashboard -n capstone-aiops

## Production learning points

### 1. Different tools need different UIs

Monitoring UI, Argo CD UI, AIOps UI එකම thing එකක් නෙවෙයි.

ඒවායේ purpose වෙනස්.

### 2. AIOps UI explains why and what action was taken

Monitoring tool එක “something is wrong” කියලා පෙන්වයි.

Argo CD “Git state synced” කියලා පෙන්වයි.

AIOps UI “root cause එක මොකක්ද, PR එක මොකක්ද, recovery වුණාද” කියලා පෙන්වයි.

### 3. Public exposure should be intentional

Internal tools public expose කරන්න කලින් authentication, DNS, TLS, access control හිතන්න ඕන.

මෙම stage එකේදී localhost-only access use කළා.

### 4. Static dashboard is a good first version

Database/backend නැතුව static dashboard එකකින් incident visibility provide කරන්න පුළුවන්.

Later this can evolve to:

    API backend
    incident history
    Slack notifications
    Alertmanager integration
    multiple incidents
    authentication

### 5. GitOps still controls the dashboard

Dashboard app එකත් GitOps repo එකෙන් deploy වෙනවා.

Manual kubectl deployment නෙවෙයි.

### 6. AppProject permissions matter

Argo CD projects restrict destinations.

New namespace එකකට app deploy කරන විට AppProject allowed destinations update කරන්න ඕන.

## Learner summary

Stage 20 වලදී අපි AIOps incident dashboard එකක් add කළා.

අපි කළේ:

    AIOps dashboard app එක GitOps repo එකට add කළා
    incident report JSON define කළා
    dashboard HTML create කළා
    ConfigMap හරහා content serve කළා
    nginx pod එකෙන් dashboard serve කළා
    Argo CD Application create කළා
    capstone-aiops namespace permission add කළා
    GitOps validation workflow update කළා
    dashboard deploy verify කළා
    localhost background port-forward scripts add කළා

Final result:

    Monitoring UI වෙනම
    Argo CD UI වෙනම
    AIOps Incident Dashboard වෙනම

AIOps Dashboard URL:

    http://localhost:8088

Next improvements:

    AIOps tool එක incident-report.json automatically update කිරීම
    multiple incidents history
    Slack notification
    Alertmanager integration
    dashboard authentication
    DNS and TLS stage එකේදී aiops subdomain
