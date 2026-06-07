# Stage 21 - AIOps Alert Detection and Dashboard Visibility

මෙම stage එකේදී AIOps workflow එකට monitoring-based incident detection layer එකක් add කරනවා.

මෙම stage එකේ main goal එක වන්නේ Kubernetes Service issue එකක් Prometheus මගින් detect කරලා, Alertmanager සහ AIOps Dashboard වලින් visibility ලබාදීමයි.

මෙම workflow එකෙන් prove කරන්නේ:

    Issue එකක් ඇති වුණාම Prometheus alert fire වෙනවා.
    Alertmanager එකේ alert එක පේනවා.
    AIOps Dashboard එක Active Incident පෙන්වනවා.
    Issue එක fix කළාම alert clear වෙනවා.
    AIOps Dashboard එක No Active Incident පෙන්වනවා.

## මේ stage එකේදී කරන දේ

මෙම stage එකේදී:

1. aiops-demo Service එකට ready endpoints නැති condition එක detect කරන PrometheusRule එක add කරනවා.
2. Prometheus rule එක load වෙලාද verify කරනවා.
3. Alertmanager UI එකේ alert visibility verify කරනවා.
4. AIOps Dashboard එක Prometheus alert state එකෙන් Active Incident පෙන්වනවද verify කරනවා.
5. Service selector fix කළාම alert clear වෙනවද verify කරනවා.
6. Alert clear වුණාම dashboard එක No Active Incident පෙන්වනවද verify කරනවා.

## Architecture flow

    Service selector issue
      ↓
    EndpointSlice has no ready endpoints
      ↓
    PrometheusRule detects the issue
      ↓
    Prometheus alert fires
      ↓
    Alertmanager shows the alert
      ↓
    AIOps Dashboard reads Prometheus alert state
      ↓
    Dashboard shows Active Incident
      ↓
    GitOps fix restores the Service selector
      ↓
    Endpoints recover
      ↓
    Prometheus alert clears
      ↓
    Dashboard shows No Active Incident

## Main components

| Component | Purpose |
|---|---|
| Prometheus | Kubernetes metrics query කිරීම සහ alert evaluate කිරීම |
| PrometheusRule | aiops-demo Service endpoint issue එක define කිරීම |
| Alertmanager | Prometheus alert visibility ලබාදීම |
| AIOps Dashboard | Active Incident / No Active Incident status පෙන්වීම |
| Argo CD | GitOps desired state cluster එකට sync කිරීම |
| EndpointSlice | Service එකට ready endpoints තියෙනවද track කිරීම |

## Files added or updated

GitOps repository එකේ relevant files:

    apps/capstone-aiops-monitoring/base/prometheusrule-aiops-demo.yaml
    apps/capstone-aiops-monitoring/base/kustomization.yaml
    apps/capstone-aiops-monitoring/overlays/dev/kustomization.yaml
    argocd/applications/capstone-aiops-monitoring.yaml
    apps/capstone-aiops-dashboard/base/index.html
    apps/capstone-aiops-dashboard/base/nginx.conf
    apps/capstone-aiops-dashboard/base/kustomization.yaml
    apps/capstone-aiops-dashboard/base/deployment.yaml

## Prometheus alert rule

Alert name:

    AIOpsDemoServiceHasNoEndpoints

PromQL expression:

    kube_service_info{namespace="capstone-aiops-demo",service="aiops-demo"}
    unless on(namespace)
    kube_endpointslice_endpoints{namespace="capstone-aiops-demo",endpointslice=~"aiops-demo-.*",ready="true"}

සරල meaning එක:

    aiops-demo Service එක තියෙනවා.
    නමුත් එයට ready EndpointSlice endpoint එකක් නැහැ.

## PrometheusRule label

kube-prometheus-stack Prometheus instance එක custom rules load කරන්නේ label selector එකක් හරහා.

මෙම project එකේ custom rule එක load වීමට PrometheusRule එකේ මෙම label එක තිබිය යුතුයි:

    release: monitoring

## Local UI access

Platform repository එකෙන් local UI helper script එක run කරන්න:

    ./scripts/local-ui/start-local-uis.sh

Useful URLs:

    AIOps Dashboard: http://localhost:8088
    Grafana:         http://localhost:3000
    Prometheus:      http://localhost:9090
    Alertmanager:    http://localhost:9093

Status check:

    ./scripts/local-ui/status-local-uis.sh

Stop:

    ./scripts/local-ui/stop-local-uis.sh

## Verify monitoring stack

Monitoring stack එක running ද බලන්න:

    kubectl get pods -n monitoring
    kubectl get svc -n monitoring

Expected components:

    Grafana
    Prometheus
    Alertmanager
    kube-state-metrics
    node-exporter
    Prometheus Operator

## Verify AIOps monitoring application

Argo CD application එක verify කරන්න:

    kubectl get application capstone-aiops-monitoring -n argocd

Expected:

    capstone-aiops-monitoring   Synced   Healthy

PrometheusRule object එක verify කරන්න:

    kubectl get prometheusrule aiops-demo-service-alerts -n monitoring

Expected:

    aiops-demo-service-alerts

## Verify Prometheus loaded the rule

Prometheus API එකෙන් rule එක load වෙලාද බලන්න:

    curl -s "http://localhost:9090/api/v1/rules" \
      | python3 -c '
    import sys, json
    data=json.load(sys.stdin)
    for group in data.get("data", {}).get("groups", []):
        for rule in group.get("rules", []):
            if rule.get("name") == "AIOpsDemoServiceHasNoEndpoints":
                print(json.dumps(rule, indent=2))
    '

Healthy state එකේ rule එක inactive විය හැක.

## Create a test incident

GitOps repository එකේ aiops-demo Service selector එක temporary wrong value එකකට change කරන්න:

    python3 - <<'PY'
    from pathlib import Path

    p = Path("apps/capstone-aiops-demo/base/service.yaml")
    text = p.read_text()

    if "app: wrong-aiops-demo" in text:
        print("Test incident already exists")
    elif "app: aiops-demo" in text:
        text = text.replace("    app: aiops-demo", "    app: wrong-aiops-demo", 1)
        p.write_text(text)
        print("Created test incident: app=wrong-aiops-demo")
    else:
        raise SystemExit("Expected app selector not found")
    PY

Commit and push:

    git add apps/capstone-aiops-demo/base/service.yaml
    git commit -m "Create AIOps monitoring alert test incident"
    git push

Watch GitOps validation:

    gh run list --workflow="validate-gitops-manifests.yml" --limit 5
    gh run watch

Refresh Argo CD:

    kubectl annotate application capstone-aiops-demo -n argocd \
      argocd.argoproj.io/refresh=hard \
      --overwrite

Wait:

    sleep 90

## Verify incident state

Service selector සහ endpoints බලන්න:

    kubectl describe svc aiops-demo -n capstone-aiops-demo
    kubectl get endpoints aiops-demo -n capstone-aiops-demo
    kubectl get endpointslice -n capstone-aiops-demo --show-labels

Expected issue state:

    Selector: app=wrong-aiops-demo
    Endpoints: <none>

## Verify Prometheus alert

Prometheus alerts API එකෙන් alert එක බලන්න:

    curl -s "http://localhost:9090/api/v1/alerts" \
      | python3 -c '
    import sys, json
    data=json.load(sys.stdin)
    found=False
    for alert in data.get("data", {}).get("alerts", []):
        if alert.get("labels", {}).get("alertname") == "AIOpsDemoServiceHasNoEndpoints":
            found=True
            print(json.dumps(alert, indent=2))
    if not found:
        print("AIOpsDemoServiceHasNoEndpoints alert is not active")
    '

Expected:

    state: firing
    alertname: AIOpsDemoServiceHasNoEndpoints
    severity: warning

## Verify Alertmanager

Browser එකෙන් Alertmanager open කරන්න:

    http://localhost:9093

Expected alert:

    AIOpsDemoServiceHasNoEndpoints

## Verify AIOps Dashboard active incident

Browser එකෙන් AIOps Dashboard open කරන්න:

    http://localhost:8088

Expected:

    Current AIOps Status:
    Active Incident Detected

Dashboard එකේ පේන්න ඕන:

    Alert / Incident
    Severity
    Namespace
    Service
    Root cause explanation
    Evidence
    Action / remediation note
    Recovery expectation

## Fix the test incident

GitOps repository එකේ Service selector එක correct value එකට restore කරන්න:

    python3 - <<'PY'
    from pathlib import Path

    p = Path("apps/capstone-aiops-demo/base/service.yaml")
    text = p.read_text()

    if "app: wrong-aiops-demo" in text:
        text = text.replace("    app: wrong-aiops-demo", "    app: aiops-demo", 1)
        p.write_text(text)
        print("Fixed service selector: wrong-aiops-demo -> aiops-demo")
    else:
        print("Service selector already fixed")
    PY

Commit and push:

    git add apps/capstone-aiops-demo/base/service.yaml
    git commit -m "Restore AIOps demo service selector"
    git push

Watch validation:

    gh run list --workflow="validate-gitops-manifests.yml" --limit 5
    gh run watch

Refresh Argo CD:

    kubectl annotate application capstone-aiops-demo -n argocd \
      argocd.argoproj.io/refresh=hard \
      --overwrite

Wait:

    sleep 90

## Verify recovery

Service selector සහ endpoints නැවත verify කරන්න:

    kubectl describe svc aiops-demo -n capstone-aiops-demo
    kubectl get endpoints aiops-demo -n capstone-aiops-demo

Expected:

    Selector: app=aiops-demo
    Endpoints: <pod-ip>:80

Prometheus alert clear වෙලාද බලන්න:

    curl -s "http://localhost:9090/api/v1/alerts" \
      | python3 -c '
    import sys, json
    data=json.load(sys.stdin)
    found=False
    for alert in data.get("data", {}).get("alerts", []):
        if alert.get("labels", {}).get("alertname") == "AIOpsDemoServiceHasNoEndpoints":
            found=True
            print(json.dumps(alert, indent=2))
    if not found:
        print("AIOpsDemoServiceHasNoEndpoints alert is not active")
    '

Expected:

    AIOpsDemoServiceHasNoEndpoints alert is not active

AIOps Dashboard refresh කළාම expected:

    Current AIOps Status:
    No Active Incident

## Final verified behavior

මෙම stage එක complete වුණාම verified behavior එක:

    Issue create කළා
      ↓
    Prometheus detect කළා
      ↓
    Alertmanager alert පෙන්වුවා
      ↓
    AIOps Dashboard Active Incident පෙන්වුවා
      ↓
    Issue GitOps මගින් fix කළා
      ↓
    Endpoints recover වුණා
      ↓
    Prometheus alert clear වුණා
      ↓
    AIOps Dashboard No Active Incident පෙන්වුවා

## Troubleshooting

Alert එක fire වෙන්නේ නැත්නම් PrometheusRule label එක check කරන්න:

    kubectl get prometheusrule aiops-demo-service-alerts -n monitoring -o yaml | grep release

Expected:

    release: monitoring

Prometheus rule selector බලන්න:

    kubectl get prometheus monitoring-kube-prometheus-prometheus -n monitoring -o yaml \
      | sed -n '/ruleSelector:/,/serviceMonitorSelector:/p'

Dashboard Active Incident පෙන්වන්නේ නැත්නම් Prometheus alert API එක check කරන්න:

    curl -s "http://localhost:9090/api/v1/alerts"

Dashboard pod restart කරන්න:

    kubectl rollout restart deployment/aiops-dashboard -n capstone-aiops

Alert clear නොවුණොත් Service selector සහ endpoints check කරන්න:

    kubectl describe svc aiops-demo -n capstone-aiops-demo
    kubectl get endpoints aiops-demo -n capstone-aiops-demo

## What you completed

මෙම stage එකෙන් ඔබ complete කළේ:

    PrometheusRule මගින් AIOps demo issue detect කිරීම
    Alertmanager alert visibility verify කිරීම
    AIOps Dashboard active incident visibility verify කිරීම
    GitOps fix පසු alert clear වෙනවාද verify කිරීම
    Dashboard No Active Incident state verify කිරීම
