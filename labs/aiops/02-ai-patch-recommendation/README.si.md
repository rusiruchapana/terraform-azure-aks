# AI Ops Lab 02 - AI Patch Recommendation

මෙම lab එකේදී ඔබ incident analysis වලින් patch recommendation දක්වා AIOps controller එක extend කරයි.

Lab 01 එකේදී controller එක incident detect කරලා Kubernetes evidence collect කරලා Azure OpenAI call කර RCA report එකක් ලිව්වා.

Lab 02 එක GitOps-safe patch recommendation එකක් add කරයි.

Controller එක තවමත් cluster එක direct patch කරන්නේ නැහැ. Git commit කරන්නේ නැහැ. එය human review සඳහා unified diff එකක් generate කරයි.

## What this lab does

මෙම lab එක `aiops-controller` version `0.2.0` deploy කරයි.

Controller එක `incident-demo` namespace එක watch කරලා supported failures detect කරයි:

- `ImagePullBackOff`, `ErrImagePull`, හෝ `BackOff`
- empty Service endpoints ඇති කරන Service selector mismatch

Incident එකක් detect වුණාම controller එක:

- compact Kubernetes evidence collect කරයි
- Azure OpenAI වෙත evidence යවයි
- structured root cause analysis ලබාගනී
- deterministic GitOps-safe patch recommendation එකක් add කරයි
- full report එක ConfigMap එකකට ලියයි
- `/aiops` dashboard එකෙන් result එක expose කරයි

Latest report එක store කරන තැන:

```text
aiops-system/aiops-latest-incident-report
```

Patch recommendation policy එක:

```text
recommend only -> human reviews -> human applies through Git -> GitOps reconciles
```

Controller එක මෙම workflow එක run කරන්නේ නැහැ:

```text
detect -> AI decides -> direct kubectl patch
```

## What you will learn

ඔබ ඉගෙනගන්න දේවල්:

- AIOps patch recommendation controller එක deploy කිරීම
- Incident RCA සඳහා Azure OpenAI භාවිතා කිරීම
- GitOps-safe unified diff එකක් generate කිරීම
- Dashboard එකක patch recommendation පෙන්වීම
- Remediation path එකේ human approval තබා ගැනීම
- AI controller එක direct cluster changes නොකරන බව verify කිරීම
- Lab එක create/use කළ Kubernetes resources සියල්ල clean කිරීම

## Architecture

```text
incident-demo namespace
  Deployment
  Service
  Endpoints
  Events
  HTTPRoute
        |
        v
aiops-controller 0.2.0 in aiops-system
        |
        | compact Kubernetes evidence
        v
Azure OpenAI
        |
        v
AI RCA JSON
        |
        v
Patch recommendation builder
        |
        v
ConfigMap: aiops-latest-incident-report
        |
        v
Dashboard: /aiops
```

Patch output එක unified diff එකක්.

Example:

```diff
--- a/k8s/incident/service.yaml
+++ b/k8s/incident/service.yaml
@@
 spec:
   type: ClusterIP
   selector:
-    app: wrong-incident-demo
+    app: incident-demo
```

## Components

| Component | Purpose |
|---|---|
| Azure OpenAI | structured incident RCA produce කරයි |
| `aiops-controller` | incidents detect කර Azure OpenAI call කර patch recommendations add කරයි |
| `aiops-system` | controller එක run වන namespace එක |
| `incident-demo` | controller එක watch කරන namespace එක |
| ConfigMap | latest RCA සහ patch recommendation store කරයි |
| Argo CD | Git වලින් controller deploy කරයි |
| Docker Hub | controller image එක store කරයි |
| HTTPRoute | dashboard path expose කරයි |

මෙම lab එකේ controller image එක:

```text
docker.io/andrewferdi/aiops-controller:0.2.0
```

මෙම lab එකේ sample app branch එක:

```text
aiops-lab-02-patch-recommendation
```

## What this lab requires

මෙම lab එක ආරම්භ කිරීමට පෙර අවශ්‍ය දේවල්:

- platform setup එකෙන් ඇති AKS cluster එක
- Argo CD installed and working
- Gateway API / NGINX Gateway Fabric installed
- Azure CLI installed and logged in
- Azure OpenAI setup completed
- Docker installed
- `kubectl` ඔබගේ AKS cluster එකට configured
- Sample GitOps repo cloned locally
- Platform repo cloned locally

මෙම lab එක clean cluster state එකකින් start විය යුතුයි. Lab 01 වල Kubernetes leftovers මත depend වෙන්න බැහැ.

## Set lab variables

ඔබගේ local folder layout එක වෙනස් නම් paths update කරන්න.

```bash
export WORKDIR="$HOME/aks-labs"

export SAMPLE_REPO="$WORKDIR/aks-gitops-sample-app"
export PLATFORM_REPO="$WORKDIR/terraform-azure-aks"

export AIOPS_NAMESPACE="aiops-system"
export WATCH_NAMESPACE="incident-demo"
export AIOPS_REPORT_CONFIGMAP="aiops-latest-incident-report"

export DOCKERHUB_USER="<your-dockerhub-username>"
export AIOPS_IMAGE="docker.io/$DOCKERHUB_USER/aiops-controller:0.2.0"
```

Verify කරන්න:

```bash
echo "$SAMPLE_REPO"
echo "$PLATFORM_REPO"
echo "$AIOPS_IMAGE"
```

## Azure OpenAI prerequisite

මෙම lab එකට Azure OpenAI අවශ්‍යයි.

Continue කිරීමට පෙර shared Azure OpenAI setup guide එක follow කරන්න:

```text
../../shared/azure-openai-setup.si.md
```

Shared setup එක complete කළාට පසු ඔබගේ terminal එකේ මේ values තිබිය යුතුයි:

```bash
AZURE_OPENAI_ENDPOINT
AZURE_OPENAI_KEY
AZURE_OPENAI_DEPLOYMENT
AZURE_OPENAI_API_VERSION
```

Verify කරන්න:

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_API_VERSION"
test -n "$AZURE_OPENAI_KEY" && echo "AZURE_OPENAI_KEY is set"
```

Azure OpenAI keys Git වලට commit කරන්න එපා.

## Verify clean start

මෙම lab එක old lab namespaces නැතුව start විය යුතුයි.

```bash
kubectl get ns | grep -E 'aiops-system|incident-demo' || true
kubectl get pods -A | grep -E 'aiops|incident-demo' || true
```

Expected result: output නැහැ.

Dashboard port එක free ද බලන්න.

```bash
lsof -iTCP:8088 -sTCP:LISTEN || true
```

Port `8088` වෙන process එකක් use කරනවා නම්, continue කිරීමට පෙර ඒ old process එක stop කරන්න.

## Create the Kubernetes secret

හැම lab එකක්ම තමන්ගේ Kubernetes Secret එක create කරයි. වෙන lab එකකින් ඉතිරි වූ secret එකක් reuse කරන්න එපා.

```bash
kubectl create namespace "$AIOPS_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic aiops-openai-secret \
  -n "$AIOPS_NAMESPACE" \
  --from-literal=AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
  --from-literal=AZURE_OPENAI_KEY="$AZURE_OPENAI_KEY" \
  --from-literal=AZURE_OPENAI_DEPLOYMENT="$AZURE_OPENAI_DEPLOYMENT" \
  --from-literal=AZURE_OPENAI_API_VERSION="$AZURE_OPENAI_API_VERSION" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Verify කරන්න:

```bash
kubectl get secret aiops-openai-secret -n "$AIOPS_NAMESPACE"
```

## Deploy the incident app

```bash
cd "$SAMPLE_REPO"

kubectl apply -k k8s/incident
```

Healthy state verify කරන්න:

```bash
kubectl rollout status deploy/incident-demo -n "$WATCH_NAMESPACE" --timeout=120s
kubectl get pods,svc,endpoints -n "$WATCH_NAMESPACE"
```

Service එකට endpoints තිබිය යුතුයි.

## Deploy the AIOps controller

Lab test එකට controller එක direct deploy කළ හැක:

```bash
cd "$SAMPLE_REPO"

kubectl apply -k k8s/aiops-controller
```

නැත්නම් platform Argo CD application එක භාවිතා කරන්න:

```bash
cd "$PLATFORM_REPO"

kubectl apply -f labs/aiops/02-ai-patch-recommendation/argocd/application.yaml
```

Verify කරන්න:

```bash
kubectl rollout status deploy/aiops-controller -n "$AIOPS_NAMESPACE" --timeout=120s
kubectl get pods -n "$AIOPS_NAMESPACE"
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

## Open the dashboard

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8088:80
```

Open කරන්න:

```text
http://localhost:8088/aiops
```

Healthy state එක මෙවගේ පෙන්විය යුතුයි:

```text
status: healthy
incident_type: none
patch_recommendation: null
```

## Incident - Bad Service selector

Service selector එක විතරක් break කරන්න.

```bash
cd "$SAMPLE_REPO"

python3 - <<'PY'
from pathlib import Path

p = Path("k8s/incident/service.yaml")
text = p.read_text()

old = """spec:
  type: ClusterIP
  selector:
    app: incident-demo
"""

new = """spec:
  type: ClusterIP
  selector:
    app: wrong-incident-demo
"""

if old not in text:
    raise SystemExit("Expected healthy selector block not found")

p.write_text(text.replace(old, new))
PY

kubectl apply -k k8s/incident
```

Incident එක verify කරන්න:

```bash
kubectl get svc -n "$WATCH_NAMESPACE" incident-demo -o yaml | grep -A5 selector
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

Expected symptom:

```text
selector:
  app: wrong-incident-demo

ENDPOINTS   <none>
```

Controller poll cycle එකකට wait කරලා dashboard refresh කරන්න.

```bash
sleep 45
```

Open කරන්න:

```text
http://localhost:8088/aiops
```

මෙවගේ output එකක් පෙන්විය යුතුයි:

```text
status: incident_detected
incident_type: service_empty_endpoints
confidence: high
apply_mode: manual_gitops_only
human_review_required: true
```

Patch recommendation එක මෙවගේ විය යුතුයි:

```diff
--- a/k8s/incident/service.yaml
+++ b/k8s/incident/service.yaml
@@
 spec:
   type: ClusterIP
   selector:
-    app: wrong-incident-demo
+    app: incident-demo
```

Raw report එක ConfigMap එකෙන් බලන්න:

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

## Fix the incident

Local GitOps file එකේ Service selector එක restore කරන්න.

```bash
cd "$SAMPLE_REPO"

python3 - <<'PY'
from pathlib import Path

p = Path("k8s/incident/service.yaml")
text = p.read_text()

text = text.replace(
"""spec:
  type: ClusterIP
  selector:
    app: wrong-incident-demo
""",
"""spec:
  type: ClusterIP
  selector:
    app: incident-demo
"""
)

text = text.replace("labels:\n    app: wrong-incident-demo", "labels:\n    app: incident-demo")

p.write_text(text)
PY

kubectl apply -k k8s/incident
kubectl get pods,svc,endpoints -n "$WATCH_NAMESPACE"
```

Endpoints return වෙන්න ඕන.

GitOps desired state එක intentionally change කළා නම් පමණක් fix එක commit කරන්න.

## Troubleshooting checklist

### Dashboard does not open

Port `8088` වෙන process එකක් use කරනවද check කරන්න.

```bash
lsof -iTCP:8088 -sTCP:LISTEN || true
```

Old process එක stop කරන්න හෝ වෙන free local port එකක් තෝරන්න.

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8099:80
```

Then open:

```text
http://localhost:8099/aiops
```

### Azure OpenAI analysis does not run

Secret එක තියෙනවද check කරන්න.

```bash
kubectl get secret aiops-openai-secret -n "$AIOPS_NAMESPACE"
```

Controller logs check කරන්න.

```bash
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

Secret recreate කිරීමට පෙර terminal values verify කරන්න.

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_API_VERSION"
test -n "$AZURE_OPENAI_KEY" && echo "AZURE_OPENAI_KEY is set"
```

### Report does not update immediately

Controller එක seconds 30 කට වරක් poll කරයි සහ repeat incident analysis throttle කරයි.

```text
POLL_SECONDS=30
INCIDENT_COOLDOWN_SECONDS=120
```

Wait කරලා dashboard refresh කරන්න.

```bash
sleep 45
```

### Service endpoints are not empty

ඔබ `metadata.labels.app` විතරක් වෙනස් කරලා නැතිව `spec.selector.app` වෙනස් කළාද බලන්න.

```bash
kubectl get svc -n "$WATCH_NAMESPACE" incident-demo -o yaml | grep -A5 selector
```

## Cleanup

මෙම lab එක අවසන් වූ පසු cluster එක lab එක ආරම්භ කිරීමට පෙර තිබූ minimal state එකටම යා යුතුයි.

Local port-forward terminal එකක් open නම් `Ctrl+C` press කර stop කරන්න.

Testing අතරතුර local files වෙනස් වුණා නම් restore කරන්න.

```bash
cd "$SAMPLE_REPO"

python3 - <<'PY'
from pathlib import Path

p = Path("k8s/incident/service.yaml")
text = p.read_text()

text = text.replace(
"""spec:
  type: ClusterIP
  selector:
    app: wrong-incident-demo
""",
"""spec:
  type: ClusterIP
  selector:
    app: incident-demo
"""
)

text = text.replace("labels:\n    app: wrong-incident-demo", "labels:\n    app: incident-demo")

p.write_text(text)
PY

git status
```

Argo CD application එක භාවිතා කළා නම් remove කරන්න.

```bash
cd "$PLATFORM_REPO"

kubectl delete -f labs/aiops/02-ai-patch-recommendation/argocd/application.yaml --ignore-not-found=true
```

මෙම lab එක create/use කළ namespaces remove කරන්න.

```bash
kubectl delete namespace "$AIOPS_NAMESPACE" --ignore-not-found=true
kubectl delete namespace "$WATCH_NAMESPACE" --ignore-not-found=true
```

Cleanup verify කරන්න:

```bash
kubectl get application -n argocd aiops-patch-recommendation 2>/dev/null || true
kubectl get ns | grep -E 'aiops-system|incident-demo' || true
kubectl get pods -A | grep -E 'aiops|incident-demo' || true
```

ඔබ Azure OpenAI resource එක AI Ops labs සඳහා පමණක් create කරලා තව labs continue නොකරනවා නම්, shared setup guide එකේ cloud cleanup section එක follow කරන්න:

```text
../../shared/azure-openai-setup.si.md
```

## What you completed

ඔබ deploy කළ AIOps controller එකට දැන් හැකියාව තියෙනවා:

- Service selector incident detect කිරීම
- Kubernetes evidence collect කිරීම
- RCA සඳහා Azure OpenAI call කිරීම
- GitOps-safe unified diff generate කිරීම
- recommendation එක ConfigMap එකකට ලියීම
- browser dashboard එකක patch recommendation පෙන්වීම
- human review require කිරීම
- direct cluster changes avoid කිරීම
- lab එක create/use කළ Kubernetes resources clean කිරීම
