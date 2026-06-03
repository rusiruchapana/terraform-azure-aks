# AI Ops Lab 02 - AI Patch Recommendation

In this lab, you extend the AIOps controller from incident analysis to patch recommendation.

Lab 01 detected a supported incident, collected Kubernetes evidence, called Azure OpenAI, and wrote a root cause analysis report.

Lab 02 adds a GitOps-safe patch recommendation.

The controller still does not patch the cluster directly. It does not commit to Git. It generates a human-reviewed unified diff that can be applied through the normal GitOps workflow.

## What this lab does

This lab deploys `aiops-controller` version `0.2.0`.

The controller watches the `incident-demo` namespace and detects supported failures:

- `ImagePullBackOff`, `ErrImagePull`, or `BackOff`
- Service selector mismatch that causes empty Service endpoints

When an incident is detected, the controller:

- collects compact Kubernetes evidence
- sends the evidence to Azure OpenAI
- receives a structured root cause analysis
- adds a deterministic GitOps-safe patch recommendation
- writes the full report to a ConfigMap
- exposes the result through the `/aiops` dashboard

The latest report is stored in:

```text
aiops-system/aiops-latest-incident-report
```

The patch recommendation uses this policy:

```text
recommend only -> human reviews -> human applies through Git -> GitOps reconciles
```

The controller does not run this workflow:

```text
detect -> AI decides -> direct kubectl patch
```

## What you will learn

You will learn how to:

- Deploy the AIOps patch recommendation controller
- Use Azure OpenAI for incident RCA
- Generate a GitOps-safe unified diff
- Display patch recommendations in a dashboard
- Keep human approval in the remediation path
- Verify that no direct cluster changes are performed by the AI controller
- Clean all Kubernetes resources created or used by the lab

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

The patch output is a unified diff.

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
| Azure OpenAI | Produces the structured incident RCA |
| `aiops-controller` | Detects incidents, calls Azure OpenAI, and adds patch recommendations |
| `aiops-system` | Namespace where the controller runs |
| `incident-demo` | Namespace watched by the controller |
| ConfigMap | Stores the latest RCA and patch recommendation |
| Argo CD | Deploys the controller from Git |
| Docker Hub | Stores the controller image |
| HTTPRoute | Exposes the dashboard path |

The controller image for this lab is:

```text
docker.io/andrewferdi/aiops-controller:0.2.0
```

The sample app branch for this lab is:

```text
aiops-lab-02-patch-recommendation
```

## What this lab requires

Before starting this lab, you need:

- AKS cluster from the platform setup
- Argo CD installed and working
- Gateway API / NGINX Gateway Fabric installed
- Azure CLI installed and logged in
- Azure OpenAI setup completed
- Docker installed
- `kubectl` configured for your AKS cluster
- Sample GitOps repo cloned locally
- Platform repo cloned locally

This lab starts from a clean cluster state. It must not depend on Kubernetes resources left behind by Lab 01.

## Set lab variables

Adjust paths if your local folder layout is different.

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

Verify:

```bash
echo "$SAMPLE_REPO"
echo "$PLATFORM_REPO"
echo "$AIOPS_IMAGE"
```

## Azure OpenAI prerequisite

This lab requires Azure OpenAI.

Follow the shared Azure OpenAI setup guide before continuing:

```text
../../shared/azure-openai-setup.md
```

After completing the shared setup, your terminal must have these values:

```bash
AZURE_OPENAI_ENDPOINT
AZURE_OPENAI_KEY
AZURE_OPENAI_DEPLOYMENT
AZURE_OPENAI_API_VERSION
```

Verify:

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_API_VERSION"
test -n "$AZURE_OPENAI_KEY" && echo "AZURE_OPENAI_KEY is set"
```

Do not commit Azure OpenAI keys to Git.

## Verify clean start

This lab should start without old lab namespaces.

```bash
kubectl get ns | grep -E 'aiops-system|incident-demo' || true
kubectl get pods -A | grep -E 'aiops|incident-demo' || true
```

Expected result: no output.

Also make sure the dashboard port is free.

```bash
lsof -iTCP:8088 -sTCP:LISTEN || true
```

If another local process is using port `8088`, stop that old process before continuing.

## Create the Kubernetes secret

Each lab creates its own Kubernetes Secret. Do not reuse a secret left behind by another lab.

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

Verify:

```bash
kubectl get secret aiops-openai-secret -n "$AIOPS_NAMESPACE"
```

## Deploy the incident app

```bash
cd "$SAMPLE_REPO"

kubectl apply -k k8s/incident
```

Verify healthy state:

```bash
kubectl rollout status deploy/incident-demo -n "$WATCH_NAMESPACE" --timeout=120s
kubectl get pods,svc,endpoints -n "$WATCH_NAMESPACE"
```

The Service should have endpoints.

## Deploy the AIOps controller

You can deploy the controller directly for the lab test:

```bash
cd "$SAMPLE_REPO"

kubectl apply -k k8s/aiops-controller
```

Or deploy it with the platform Argo CD application:

```bash
cd "$PLATFORM_REPO"

kubectl apply -f labs/aiops/02-ai-patch-recommendation/argocd/application.yaml
```

Verify:

```bash
kubectl rollout status deploy/aiops-controller -n "$AIOPS_NAMESPACE" --timeout=120s
kubectl get pods -n "$AIOPS_NAMESPACE"
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

## Open the dashboard

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8088:80
```

Open:

```text
http://localhost:8088/aiops
```

Healthy state should show:

```text
status: healthy
incident_type: none
patch_recommendation: null
```

## Incident - Bad Service selector

Break only the Service selector.

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

Verify the incident:

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

Wait for the controller poll cycle, then refresh the dashboard.

```bash
sleep 45
```

Open:

```text
http://localhost:8088/aiops
```

You should see:

```text
status: incident_detected
incident_type: service_empty_endpoints
confidence: high
apply_mode: manual_gitops_only
human_review_required: true
```

The patch recommendation should look like:

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

You can also read the raw report from the ConfigMap:

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

## Fix the incident

Restore the Service selector in the local GitOps file.

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

The endpoints should return.

Commit the fix only if you intentionally changed the GitOps desired state.

## Troubleshooting checklist

### Dashboard does not open

Check whether another process is using port `8088`.

```bash
lsof -iTCP:8088 -sTCP:LISTEN || true
```

Stop the old process or choose another free local port.

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8099:80
```

Then open:

```text
http://localhost:8099/aiops
```

### Azure OpenAI analysis does not run

Check that the secret exists.

```bash
kubectl get secret aiops-openai-secret -n "$AIOPS_NAMESPACE"
```

Check controller logs.

```bash
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

Verify your terminal values before recreating the secret.

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_API_VERSION"
test -n "$AZURE_OPENAI_KEY" && echo "AZURE_OPENAI_KEY is set"
```

### Report does not update immediately

The controller polls every 30 seconds and throttles repeat incident analysis.

```text
POLL_SECONDS=30
INCIDENT_COOLDOWN_SECONDS=120
```

Wait and refresh the dashboard.

```bash
sleep 45
```

### Service endpoints are not empty

Make sure you changed `spec.selector.app`, not only `metadata.labels.app`.

```bash
kubectl get svc -n "$WATCH_NAMESPACE" incident-demo -o yaml | grep -A5 selector
```

## Cleanup

This lab should leave the cluster in the same minimal state it had before the lab started.

Stop any local port-forward terminal with `Ctrl+C`.

Restore local files if you changed them during testing.

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

Remove the Argo CD application if you used it.

```bash
cd "$PLATFORM_REPO"

kubectl delete -f labs/aiops/02-ai-patch-recommendation/argocd/application.yaml --ignore-not-found=true
```

Remove the namespaces created or used by this lab.

```bash
kubectl delete namespace "$AIOPS_NAMESPACE" --ignore-not-found=true
kubectl delete namespace "$WATCH_NAMESPACE" --ignore-not-found=true
```

Verify cleanup:

```bash
kubectl get application -n argocd aiops-patch-recommendation 2>/dev/null || true
kubectl get ns | grep -E 'aiops-system|incident-demo' || true
kubectl get pods -A | grep -E 'aiops|incident-demo' || true
```

If you created Azure OpenAI only for the AI Ops labs and you are not continuing, follow the cloud cleanup section in the shared setup guide:

```text
../../shared/azure-openai-setup.md
```

## What you completed

You deployed an AIOps controller that can:

- detect a Service selector incident
- collect Kubernetes evidence
- call Azure OpenAI for RCA
- generate a GitOps-safe unified diff
- write the recommendation to a ConfigMap
- show the patch recommendation in a browser dashboard
- require human review
- avoid direct cluster changes
- clean all Kubernetes resources created or used by the lab
