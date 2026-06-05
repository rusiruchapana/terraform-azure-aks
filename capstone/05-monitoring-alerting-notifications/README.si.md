# Stage 05 - Monitoring, Alerting, and Notifications

## මේ stage එකේදී මොකක්ද වෙන්නේ?

මෙම stage එකේදී AKS platform එකට monitoring foundation එක install කරනවා.

අපි install කරන main tools:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter

මෙම stage එකේදී app-specific dashboards/alerts තවම හදන්නේ නැහැ.

මුලින් cluster monitoring foundation එක ready කරනවා.

## ඇයි monitoring වැදගත්?

Production platform එකක app එක run වෙනවා කියලා assume කරන්න බැහැ.

අපිට බලන්න ඕන:

- nodes healthy ද?
- pods running ද?
- CPU/memory usage කොහොමද?
- pods restart වෙනවද?
- deployments available ද?
- cluster components healthy ද?

Monitoring නැත්නම් incident එකක් වෙලා පස්සේ තමයි දැනගන්න වෙන්නේ.

## Prometheus කියන්නේ මොකක්ද?

Prometheus කියන්නේ metrics collect කරන monitoring system එකක්.

සරලව:

Prometheus cluster එකේ components වලින් metrics scrape කරනවා.

Examples:

- node CPU
- node memory
- pod restarts
- deployment replicas
- container resource usage

## Grafana කියන්නේ මොකක්ද?

Grafana කියන්නේ dashboards බලන්න use කරන tool එකක්.

Prometheus collect කරන metrics Grafana dashboards වලින් visual විදිහට බලන්න පුළුවන්.

Examples:

- cluster overview dashboard
- node resource dashboard
- pod health dashboard
- application dashboard

## Alertmanager කියන්නේ මොකක්ද?

Alertmanager කියන්නේ Prometheus alerts receive කරලා notification channels වලට route කරන tool එක.

Examples:

- Slack
- Email
- PagerDuty
- Microsoft Teams

මෙම capstone එකේ notification layer එකට Slack webhook use කරන්න plan කරනවා.

## Dashboard බලන එක විතරක් monitoring නෙවෙයි

Production වල engineer කෙනෙක් හැම වෙලාවෙම Grafana dashboard එක බල බල ඉන්නේ නැහැ.

ඒ නිසා critical condition එකක් detect වුණාම notification එකක් යවන්න ඕන.

Flow එක:

Prometheus alert detect කරනවා
→ Alertmanager alert receive කරනවා
→ Slack/email notification යවනවා
→ engineer හෝ AIOps workflow එක action ගන්නවා

## AIOps සමඟ connection එක

Monitoring layer එක AIOps වලට evidence source එකක්.

AIOps incident analyse කරනකොට මේවා බලන්න පුළුවන්:

- pod restart count
- deployment unavailable
- node not ready
- high CPU/memory
- OOMKilled
- service endpoint issue
- Gateway route health

AIOps flow එක:

Alert fires
→ evidence collect
→ root cause analyse
→ Slack update
→ GitHub PR remediation if safe
→ Argo CD recovery

## Notification design

මෙම project එකේ notification flow එක මෙහෙම design කරනවා:

Critical alert
→ Alertmanager
→ Slack notification

AIOps workflow status
→ AIOps controller
→ Slack notification

Example AIOps status messages:

- Incident detected
- Evidence collected
- AI analysis completed
- Remediation PR created
- Waiting for human approval
- Argo CD sync completed
- Incident recovered

## Slack webhook safety

Slack webhook එක secret එකක්.

ඒක public Git repo එකට commit කරන්න හොඳ නැහැ.

Learning mode එකේ Kubernetes Secret එකක් use කරන්න පුළුවන්.

Production-style final version එකේ Azure Key Vault + Workload Identity හරහා webhook secret manage කරනවා.

## Commands used in this stage

Helm repo add කිරීම:

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

Monitoring install කිරීම:

    helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
      --namespace monitoring \
      --create-namespace \
      --values platform/monitoring/kube-prometheus-stack-values.yaml \
      --wait \
      --timeout 10m

Verify කිරීම:

    kubectl get pods -n monitoring
    kubectl get svc -n monitoring
    kubectl get prometheus -n monitoring
    kubectl get alertmanager -n monitoring
    kubectl get servicemonitor -n monitoring

## Grafana access

Grafana local machine එකට port-forward කරන්න:

    kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

Browser එකෙන් open කරන්න:

    http://localhost:3000

Default username:

    admin

Password:

    kube-prometheus-stack-values.yaml file එකේ configured admin password එක.

## Prometheus access

Prometheus local machine එකට port-forward කරන්න:

    kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090

Browser:

    http://localhost:9090

## Alertmanager access

Alertmanager local machine එකට port-forward කරන්න:

    kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093

Browser:

    http://localhost:9093

## Expected result

Monitoring namespace එකේ pods Running විය යුතුයි.

Expected components:

- Grafana
- Prometheus
- Alertmanager
- kube-state-metrics
- node-exporter
- Prometheus operator

## Troubleshooting

### Pods Pending නම්

Node capacity බලන්න:

    kubectl get nodes
    kubectl describe pod -n monitoring <pod-name>

Learning cluster එකේ nodes අඩු නිසා resource pressure එන්න පුළුවන්.

### Helm install timeout නම්

Check:

    kubectl get pods -n monitoring
    kubectl get events -n monitoring --sort-by=.lastTimestamp

### Grafana login issue නම්

Admin password value file එකේ check කරන්න.

### Alertmanager Slack not working නම්

Slack webhook secret configure කරලා තියෙනවද බලන්න.

Never commit real webhook URL to Git.

## Production meaning

මෙම stage එකෙන් platform එකට visibility ලැබෙනවා.

Monitoring නැතුව platform එක blind.

Prometheus metrics collect කරනවා.

Grafana dashboards display කරනවා.

Alertmanager critical alerts notify කරනවා.

AIOps layer එක මේ evidence use කරලා incident root cause analyse කරනවා.

## මේ stage එකෙන් මතක තියාගන්න ඕන දේ

Monitoring කියන්නේ dashboard එකක් open කරන එක විතරක් නෙවෙයි.

Production monitoring වලට metrics, dashboards, alerts, notifications, and incident response workflow එකක් ඕන.

මෙම stage එකෙන් ඒ foundation එක build වෙනවා.
