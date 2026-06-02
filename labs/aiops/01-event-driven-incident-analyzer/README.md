# AI Ops Lab 01 - Event-driven Incident Analyzer

In this lab, you deploy an AIOps controller into AKS.

The controller watches the `incident-demo` namespace, detects supported incidents, collects live Kubernetes evidence, sends compact evidence to Azure OpenAI, and writes the latest root cause analysis report to a Kubernetes ConfigMap.

This lab does not use AI as a separate prompt assistant. AI is integrated into the infrastructure workflow. The controller is triggered by live cluster state and produces a GitOps-safe recommendation.

The controller does not patch production resources directly.

## What this lab does

This lab deploys an `aiops-controller` workload into the `aiops-system` namespace.

The controller continuously checks the `incident-demo` namespace for supported failures:

- A bad container image that causes `ImagePullBackOff`, `ErrImagePull`, or `BackOff`
- A bad Service selector that causes empty Service endpoints

When it detects an incident, it collects compact evidence from Kubernetes resources, sends that evidence to Azure OpenAI, and stores the structured RCA result in this ConfigMap:

```text
aiops-system/aiops-latest-incident-report
```

The report includes:

- incident type
- affected resource
- symptom
- root cause
- GitOps repository
- file to fix
- current wrong value
- expected value
- recommended safe next steps
- confidence

The controller also exposes a simple browser dashboard at:

```text
/aiops
```

## What you will learn

You will learn how to:

- Run an event-driven AIOps controller inside AKS
- Detect Kubernetes incidents from live cluster state
- Collect evidence from pods, deployments, services, endpoints, events, and HTTPRoutes
- Send compact structured evidence to Azure OpenAI
- Store the AI-generated RCA report in Kubernetes
- View the latest RCA through a browser dashboard
- Keep remediation safe by recommending GitOps changes instead of direct cluster patches
- Test two common incident patterns:
  - bad image tag
  - Service selector mismatch

## Architecture

```text
GitOps sample app repo
  k8s/incident/
  k8s/aiops-controller/
        |
        v
Argo CD
        |
        v
AKS cluster

incident-demo namespace
  Deployment
  Service
  Endpoints
  Events
  HTTPRoute
        |
        v
aiops-controller in aiops-system
        |
        | compact Kubernetes evidence
        | no secrets
        | no large logs
        v
Azure OpenAI deployment
        |
        v
Structured RCA JSON
        |
        v
ConfigMap: aiops-latest-incident-report
        |
        v
Browser dashboard: /aiops
```

The controller is intentionally safe:

```text
detect -> collect evidence -> analyze -> recommend -> human reviews -> GitOps fix
```

It does not run this workflow:

```text
detect -> AI decides -> direct kubectl patch
```

## Components

This lab uses the following components.

| Component | Purpose |
|---|---|
| `aiops-controller` | Python FastAPI controller that detects incidents and calls Azure OpenAI |
| `aiops-system` | Namespace where the AIOps controller runs |
| `incident-demo` | Namespace watched by the controller |
| Azure OpenAI | Generates the structured RCA report from Kubernetes evidence |
| ConfigMap | Stores the latest RCA report |
| Argo CD | Deploys the AIOps controller from Git |
| Docker Hub | Stores the controller image |
| HTTPRoute | Exposes the `/aiops` dashboard through the platform gateway path |

The sample app repository is:

```text
https://github.com/andrewferdinandus/aks-gitops-sample-app.git
```

This lab supports two image modes.

**Option A - Fast path**

Use the author-tested public image already referenced by the sample repo:

```text
docker.io/andrewferdi/aiops-controller:0.1.0
```

Use this option when you want to focus on the AIOps workflow instead of the container build workflow.

**Option B - Build path**

Build the controller image yourself and push it to your own Docker Hub account:

```text
docker.io/<your-dockerhub-username>/aiops-controller:0.1.0
```

Do not push to the author's Docker Hub namespace.

If you use Option B with Argo CD, fork the sample repo, update `k8s/aiops-controller/deployment.yaml` to your image, push the fork, and point the Argo CD application to your fork.

## What this lab requires

Before starting this lab, you need:

- AKS cluster from the previous labs
- Argo CD installed and working
- Gateway API / NGINX Gateway Fabric already installed
- `incident-demo` manifests available in the sample GitOps repo
- Azure OpenAI resource already created
- Azure OpenAI deployment already working
- Option A: access to the author-tested public image
- Option B: your own Docker Hub account and fork of the sample repo

This lab uses the existing Azure OpenAI deployment:

```text
Resource group: <your-aiops-resource-group>
Azure OpenAI account: <your-azure-openai-account>
Deployment: <your-azure-openai-deployment>
Model: gpt-4.1-nano or another supported chat model
API version: 2024-10-21
```

The real Azure OpenAI key must not be committed to Git.

## Set lab variables

Set these variables in your terminal.

```bash
export SAMPLE_REPO="/Users/andrewferdinandus/projcts/aks-gitops-sample-app"
export PLATFORM_REPO="/Users/andrewferdinandus/projcts/terraform-azure-aks"

export AIOPS_NAMESPACE="aiops-system"
export WATCH_NAMESPACE="incident-demo"
export AIOPS_REPORT_CONFIGMAP="aiops-latest-incident-report"

export AZURE_OPENAI_ENDPOINT="<your-azure-openai-endpoint>"
export AZURE_OPENAI_DEPLOYMENT="<your-azure-openai-deployment>"
export AZURE_OPENAI_API_VERSION="2024-10-21"

export DOCKERHUB_USER="<your-dockerhub-username>"
export AIOPS_IMAGE="docker.io/$DOCKERHUB_USER/aiops-controller:0.1.0"

export GITHUB_USER="<your-github-username>"
export SAMPLE_REPO_FORK_URL="https://github.com/$GITHUB_USER/aks-gitops-sample-app.git"
```

Verify:

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AIOPS_IMAGE"
echo "$SAMPLE_REPO_FORK_URL"
```

Choose your image mode.

### Option A - Use the author-tested image

No image build is required.

The sample repo already references:

```text
docker.io/andrewferdi/aiops-controller:0.1.0
```

Continue to the Azure OpenAI secret step.

### Option B - Build and push your own image

Use this option when you want to build the controller image yourself.

Go to the sample repo.

```bash
cd "$SAMPLE_REPO"
```

Build and push to your own Docker Hub account.

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t "$AIOPS_IMAGE" \
  ./aiops-controller \
  --push
```

Update the deployment manifest to use your image.

```bash
sed -i.bak "s#image: .*aiops-controller:0.1.0#image: $AIOPS_IMAGE#" k8s/aiops-controller/deployment.yaml
rm -f k8s/aiops-controller/deployment.yaml.bak

grep -n "image:" k8s/aiops-controller/deployment.yaml
```

If you are using GitOps with your own image, fork the sample repo and push the manifest change to your fork.

```bash
git add k8s/aiops-controller/deployment.yaml
git commit -m "Use my AIOps controller image"
git push
```

Then update the Argo CD application `repoURL` to your fork.

```bash
sed -i.bak "s#repoURL: https://github.com/andrewferdinandus/aks-gitops-sample-app.git#repoURL: $SAMPLE_REPO_FORK_URL#" "$PLATFORM_REPO/labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml"
rm -f "$PLATFORM_REPO/labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml.bak"

grep -n "repoURL" "$PLATFORM_REPO/labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml"
```

Create the Azure OpenAI secret.

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

## Verify healthy desired state

Make sure the sample incident app is deployed in a healthy state.

```bash
cd "$SAMPLE_REPO"

kubectl apply -k k8s/incident
```

Check the namespace and workload.

```bash
kubectl get ns "$WATCH_NAMESPACE"
kubectl get pods,svc,endpoints -n "$WATCH_NAMESPACE"
kubectl get httproute -n "$WATCH_NAMESPACE"
```

The Service should have ready endpoints.

```bash
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

Expected result:

```text
NAME            ENDPOINTS
incident-demo   <pod-ip>:80
```

Your Kubernetes version may show this warning:

```text
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
```

That warning is safe for this lab.

You can also check EndpointSlices.

```bash
kubectl get endpointslice -n "$WATCH_NAMESPACE"
```

## Deploy with Argo CD

Go to the platform repo.

```bash
cd "$PLATFORM_REPO"
```

Apply the Argo CD application.

```bash
kubectl apply -f labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml
```

Check the Argo CD application.

```bash
kubectl get application -n argocd aiops-controller
kubectl describe application -n argocd aiops-controller
```

Check the controller pod.

```bash
kubectl get pods -n "$AIOPS_NAMESPACE"
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

Check the latest report.

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

A healthy result should look similar to this:

```json
{
  "status": "healthy",
  "message": "No supported incident detected.",
  "watch_namespace": "incident-demo"
}
```

Open the dashboard locally.

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8088:80
```

Open this URL in the browser:

```text
http://localhost:8088/aiops
```

## Incident 1 - Bad image tag

This incident simulates an application deployment with a bad image.

Go to the sample repo.

```bash
cd "$SAMPLE_REPO"
```

Change the incident demo image to an invalid tag.

```bash
perl -0pi -e 's#image: nginx:1.27-alpine#image: nginx:does-not-exist-aiops-lab#' k8s/incident/deployment.yaml
```

Apply the broken state.

```bash
kubectl apply -k k8s/incident
```

Check the pod status.

```bash
kubectl get pods -n "$WATCH_NAMESPACE"
kubectl describe pods -n "$WATCH_NAMESPACE"
```

You should see a waiting reason such as:

```text
ImagePullBackOff
ErrImagePull
BackOff
```

Wait for the controller poll cycle, then check the AI report.

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

The report should identify a bad image pull incident and recommend a GitOps-safe change in:

```text
k8s/incident/deployment.yaml
```

## Fix Incident 1

Restore the healthy image.

```bash
perl -0pi -e 's#image: nginx:does-not-exist-aiops-lab#image: nginx:1.27-alpine#' k8s/incident/deployment.yaml
```

Apply the healthy state.

```bash
kubectl apply -k k8s/incident
```

Verify the pod returns to Running.

```bash
kubectl get pods -n "$WATCH_NAMESPACE"
```

Commit and push the fix if this change was made in Git.

```bash
git add k8s/incident/deployment.yaml
git commit -m "Restore incident demo image"
git push
```

## Incident 2 - Bad Service selector

This incident simulates a Service selector mismatch.

The pods are healthy, but the Service cannot route traffic because its selector does not match the pod labels.

Go to the sample repo.

```bash
cd "$SAMPLE_REPO"
```

Break the Service selector.

```bash
perl -0pi -e 's/app: incident-demo/app: wrong-incident-demo/' k8s/incident/service.yaml
```

Apply the broken state.

```bash
kubectl apply -k k8s/incident
```

Check the Service selector.

```bash
kubectl get svc -n "$WATCH_NAMESPACE" incident-demo -o yaml | grep -A5 selector
```

Check the endpoints.

```bash
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

Expected symptom:

```text
ENDPOINTS   <none>
```

Wait for the controller poll cycle, then check the AI report.

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

Expected RCA details:

```json
{
  "incident_type": "service_empty_endpoints",
  "affected_resource": "Service/incident-demo",
  "fix_location": {
    "repository": "aks-gitops-sample-app",
    "file": "k8s/incident/service.yaml",
    "field": "spec.selector",
    "current_value": {
      "app": "wrong-incident-demo"
    },
    "expected_value": {
      "app": "incident-demo"
    }
  },
  "confidence": "high"
}
```

## Fix Incident 2

Restore the Service selector.

```bash
perl -0pi -e 's/app: wrong-incident-demo/app: incident-demo/g' k8s/incident/service.yaml
```

Apply the healthy state.

```bash
kubectl apply -k k8s/incident
```

Verify endpoints return.

```bash
kubectl get pods,svc,endpoints -n "$WATCH_NAMESPACE"
```

Commit and push the fix if this change was made in Git.

```bash
git add k8s/incident/service.yaml
git commit -m "Restore incident demo service selector"
git push
```

After the next controller poll cycle, the report should return to healthy.

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

## Troubleshooting checklist

### Controller pod is not running

Check the pod and events.

```bash
kubectl get pods -n "$AIOPS_NAMESPACE"
kubectl describe pod -n "$AIOPS_NAMESPACE" -l app=aiops-controller
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

Common causes:

- Docker image name is wrong
- Docker image was not pushed
- Secret is missing
- RBAC was not applied

### Azure OpenAI analysis does not run

Check the secret.

```bash
kubectl get secret aiops-openai-secret -n "$AIOPS_NAMESPACE"
```

Check the controller logs.

```bash
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

Remember that this lab uses a low Azure OpenAI quota:

```text
1 request per minute
1000 tokens per minute
```

The controller also throttles repeat analysis for the same incident.

```text
INCIDENT_COOLDOWN_SECONDS=120
```

### Report still shows the old incident

Wait for the next poll cycle.

```bash
sleep 30
```

Then check the report again.

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

### Dashboard does not open

Check the service.

```bash
kubectl get svc -n "$AIOPS_NAMESPACE" aiops-controller
```

Use port-forward for local access.

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8088:80
```

Open:

```text
http://localhost:8088/aiops
```

### Service endpoints stay empty after restoring the selector

Check the Service selector and pod labels.

```bash
kubectl get svc -n "$WATCH_NAMESPACE" incident-demo -o yaml | grep -A5 selector
kubectl get pods -n "$WATCH_NAMESPACE" --show-labels
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

The Service selector must match the pod labels.

## Cleanup

This lab should leave the cluster in the same minimal state it had before the lab started.

Stop any local port-forward terminal with `Ctrl+C`.

Remove the AIOps Argo CD application.

```bash
cd "$PLATFORM_REPO"

kubectl delete -f labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml --ignore-not-found=true
```

Remove the namespaces created or used by this lab.

```bash
kubectl delete namespace "$AIOPS_NAMESPACE" --ignore-not-found=true
kubectl delete namespace "$WATCH_NAMESPACE" --ignore-not-found=true
```

Verify that no lab resources remain in the cluster.

```bash
kubectl get application -n argocd aiops-controller 2>/dev/null || true
kubectl get ns | grep -E 'aiops-system|incident-demo' || true
kubectl get pods -A | grep -E 'aiops|incident-demo' || true
```

The commands above clean the Kubernetes resources used by this lab.

If you created an Azure OpenAI resource only for this lab and you are not continuing to the next AIOps lab, delete that Azure resource or resource group from your own Azure subscription.

Do not use the author's Azure OpenAI endpoint or key. Each learner must use their own Azure OpenAI resource and deployment.

## What you completed

You deployed an AIOps controller into AKS and verified that it can:

- watch a namespace for incidents
- detect image pull failures
- detect Service selector mismatches
- collect live Kubernetes evidence
- call Azure OpenAI for root cause analysis
- write the latest RCA to a ConfigMap
- expose the result through a browser dashboard
- recommend GitOps-safe fixes without directly patching workloads

You now have the foundation for the next AIOps labs, where the recommendation flow can be extended into patch generation and human-approved pull requests.
