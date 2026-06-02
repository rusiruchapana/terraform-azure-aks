# AI Ops Lab 01 - Event-driven Incident Analyzer

මෙම lab එකේදී ඔබ AKS තුළ AIOps controller එකක් deploy කරයි.

Controller එක `incident-demo` namespace එක watch කරයි, supported incidents detect කරයි, live Kubernetes evidence collect කරයි, compact evidence Azure OpenAI වෙත යවයි, සහ latest root cause analysis report එක Kubernetes ConfigMap එකකට ලියයි.

මෙම lab එක AI එක වෙනම prompt assistant එකක් ලෙස භාවිතා කිරීමක් නොවේ. AI එක infrastructure workflow එක තුළට integrate කරයි. Controller එක live cluster state එකෙන් trigger වෙලා GitOps-safe recommendation එකක් produce කරයි.

Controller එක production resources direct patch කරන්නේ නැහැ.

## What this lab does

මෙම lab එක `aiops-controller` workload එක `aiops-system` namespace එකට deploy කරයි.

Controller එක `incident-demo` namespace එකේ supported failures check කරයි:

- `ImagePullBackOff`, `ErrImagePull`, හෝ `BackOff` ඇති කරන bad container image එකක්
- empty Service endpoints ඇති කරන bad Service selector එකක්

Incident එකක් detect වුණාම, controller එක Kubernetes resources වලින් compact evidence collect කරයි, ඒ evidence Azure OpenAI වෙත යවයි, සහ structured RCA result එක මෙම ConfigMap එකේ store කරයි:

```text
aiops-system/aiops-latest-incident-report
```

Report එකේ අඩංගු දේවල්:

- incident type
- affected resource
- symptom
- root cause
- GitOps repository
- fix කළ යුතු file එක
- current wrong value
- expected value
- recommended safe next steps
- confidence

Controller එක simple browser dashboard එකක් expose කරයි:

```text
/aiops
```

## What you will learn

ඔබ ඉගෙනගන්න දේවල්:

- AKS තුළ event-driven AIOps controller එකක් run කිරීම
- Live cluster state එකෙන් Kubernetes incidents detect කිරීම
- pods, deployments, services, endpoints, events, HTTPRoutes වලින් evidence collect කිරීම
- compact structured evidence Azure OpenAI වෙත යැවීම
- AI-generated RCA report එක Kubernetes තුළ store කිරීම
- browser dashboard එකක් හරහා latest RCA බලීම
- direct cluster patches වෙනුවට GitOps changes recommend කර remediation safe තබා ගැනීම
- common incident patterns දෙකක් test කිරීම:
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

Controller එක intentionally safe:

```text
detect -> collect evidence -> analyze -> recommend -> human reviews -> GitOps fix
```

මෙම unsafe workflow එක run කරන්නේ නැහැ:

```text
detect -> AI decides -> direct kubectl patch
```

## Components

මෙම lab එකේ components:

| Component | Purpose |
|---|---|
| `aiops-controller` | incidents detect කර Azure OpenAI call කරන Python FastAPI controller |
| `aiops-system` | AIOps controller එක run වන namespace එක |
| `incident-demo` | Controller එක watch කරන namespace එක |
| Azure OpenAI | Kubernetes evidence වලින් structured RCA report generate කරයි |
| ConfigMap | latest RCA report එක store කරයි |
| Argo CD | Git වලින් AIOps controller deploy කරයි |
| Docker Hub | controller image එක store කරයි |
| HTTPRoute | platform gateway path හරහා `/aiops` dashboard expose කරයි |

Sample app repository එක:

```text
https://github.com/andrewferdinandus/aks-gitops-sample-app.git
```

මෙම lab එක image modes දෙකක් support කරයි.

**Option A - Fast path**

Sample repo එකේ already reference කර ඇති author-tested public image එක භාවිතා කරන්න:

```text
docker.io/andrewferdi/aiops-controller:0.1.0
```

Container build workflow එකට වඩා AIOps workflow එක focus කරන්න අවශ්‍ය නම් මේ option එක භාවිතා කරන්න.

**Option B - Build path**

Controller image එක ඔබම build කරලා ඔබගේ Docker Hub account එකට push කරන්න:

```text
docker.io/<your-dockerhub-username>/aiops-controller:0.1.0
```

Authorගේ Docker Hub namespace එකට push කරන්න එපා.

Option B Argo CD සමඟ භාවිතා කරනවා නම්, sample repo එක fork කරන්න, `k8s/aiops-controller/deployment.yaml` ඔබගේ image එකට update කරන්න, fork එකට push කරන්න, සහ Argo CD application එක ඔබගේ fork එකට point කරන්න.

## What this lab requires

මෙම lab එක ආරම්භ කිරීමට පෙර අවශ්‍ය දේවල්:

- පෙර labs වලින් ඇති AKS cluster එක
- Argo CD installed and working
- Gateway API / NGINX Gateway Fabric installed
- sample GitOps repo එකේ `incident-demo` manifests
- Azure OpenAI resource already created
- Azure OpenAI deployment already working
- Option A: author-tested public image එක pull කිරීමට access
- Option B: ඔබගේ Docker Hub account එක සහ sample repo fork එකක්

මෙම lab එක existing Azure OpenAI deployment එක භාවිතා කරයි:

```text
Resource group: rg-aks-aiops
Azure OpenAI account: aiops-openai-9954
Deployment: gpt-4-1-nano
Model: gpt-4.1-nano
API version: 2024-10-21
```

Real Azure OpenAI key එක Git වලට commit කරන්න එපා.

## Set lab variables

Terminal එකේ මේ variables set කරන්න.

```bash
export SAMPLE_REPO="/Users/andrewferdinandus/projcts/aks-gitops-sample-app"
export PLATFORM_REPO="/Users/andrewferdinandus/projcts/terraform-azure-aks"

export AIOPS_NAMESPACE="aiops-system"
export WATCH_NAMESPACE="incident-demo"
export AIOPS_REPORT_CONFIGMAP="aiops-latest-incident-report"

export AZURE_OPENAI_ENDPOINT="https://aiops-openai-9954-17090.openai.azure.com/"
export AZURE_OPENAI_DEPLOYMENT="gpt-4-1-nano"
export AZURE_OPENAI_API_VERSION="2024-10-21"

export DOCKERHUB_USER="<your-dockerhub-username>"
export AIOPS_IMAGE="docker.io/$DOCKERHUB_USER/aiops-controller:0.1.0"

export GITHUB_USER="<your-github-username>"
export SAMPLE_REPO_FORK_URL="https://github.com/$GITHUB_USER/aks-gitops-sample-app.git"
```

Verify කරන්න:

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AIOPS_IMAGE"
echo "$SAMPLE_REPO_FORK_URL"
```

Image mode එක තෝරන්න.

### Option A - Use the author-tested image

Image build කිරීම අවශ්‍ය නැහැ.

Sample repo එක already reference කරන්නේ:

```text
docker.io/andrewferdi/aiops-controller:0.1.0
```

Azure OpenAI secret step එකට යන්න.

### Option B - Build and push your own image

Controller image එක ඔබම build කරන්න අවශ්‍ය නම් මේ option එක භාවිතා කරන්න.

Sample repo එකට යන්න.

```bash
cd "$SAMPLE_REPO"
```

ඔබගේ Docker Hub account එකට build and push කරන්න.

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t "$AIOPS_IMAGE" \
  ./aiops-controller \
  --push
```

Deployment manifest එක ඔබගේ image එකට update කරන්න.

```bash
sed -i.bak "s#image: .*aiops-controller:0.1.0#image: $AIOPS_IMAGE#" k8s/aiops-controller/deployment.yaml
rm -f k8s/aiops-controller/deployment.yaml.bak

grep -n "image:" k8s/aiops-controller/deployment.yaml
```

GitOps සමඟ ඔබගේ image එක භාවිතා කරනවා නම්, sample repo fork එකට manifest change එක push කරන්න.

```bash
git add k8s/aiops-controller/deployment.yaml
git commit -m "Use my AIOps controller image"
git push
```

ඉන්පසු Argo CD application එකේ `repoURL` ඔබගේ fork එකට update කරන්න.

```bash
sed -i.bak "s#repoURL: https://github.com/andrewferdinandus/aks-gitops-sample-app.git#repoURL: $SAMPLE_REPO_FORK_URL#" "$PLATFORM_REPO/labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml"
rm -f "$PLATFORM_REPO/labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml.bak"

grep -n "repoURL" "$PLATFORM_REPO/labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml"
```

Azure OpenAI secret එක create කරන්න.

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

## Verify healthy desired state

Sample incident app එක healthy state එකේ deploy වෙලා තියෙනවද බලන්න.

```bash
cd "$SAMPLE_REPO"

kubectl apply -k k8s/incident
```

Namespace සහ workload check කරන්න.

```bash
kubectl get ns "$WATCH_NAMESPACE"
kubectl get pods,svc,endpoints -n "$WATCH_NAMESPACE"
kubectl get httproute -n "$WATCH_NAMESPACE"
```

Service එකට ready endpoints තිබිය යුතුයි.

```bash
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

Expected result:

```text
NAME            ENDPOINTS
incident-demo   <pod-ip>:80
```

ඔබගේ Kubernetes version එක මේ warning එක පෙන්විය හැක:

```text
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
```

මෙම warning එක මෙම lab එකට safe.

EndpointSlices check කරන්නත් පුළුවන්:

```bash
kubectl get endpointslice -n "$WATCH_NAMESPACE"
```

## Deploy with Argo CD

Platform repo එකට යන්න.

```bash
cd "$PLATFORM_REPO"
```

Argo CD application එක apply කරන්න.

```bash
kubectl apply -f labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml
```

Argo CD application එක check කරන්න.

```bash
kubectl get application -n argocd aiops-controller
kubectl describe application -n argocd aiops-controller
```

Controller pod එක check කරන්න.

```bash
kubectl get pods -n "$AIOPS_NAMESPACE"
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

Latest report එක check කරන්න.

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

Healthy result එක මෙවගේ විය යුතුයි:

```json
{
  "status": "healthy",
  "message": "No supported incident detected.",
  "watch_namespace": "incident-demo"
}
```

Dashboard එක locally open කරන්න.

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8088:80
```

Browser එකේ open කරන්න:

```text
http://localhost:8088/aiops
```

## Incident 1 - Bad image tag

මෙම incident එක bad image සහිත application deployment එකක් simulate කරයි.

Sample repo එකට යන්න.

```bash
cd "$SAMPLE_REPO"
```

Incident demo image එක invalid tag එකකට change කරන්න.

```bash
perl -0pi -e 's#image: nginx:1.27-alpine#image: nginx:does-not-exist-aiops-lab#' k8s/incident/deployment.yaml
```

Broken state එක apply කරන්න.

```bash
kubectl apply -k k8s/incident
```

Pod status එක check කරන්න.

```bash
kubectl get pods -n "$WATCH_NAMESPACE"
kubectl describe pods -n "$WATCH_NAMESPACE"
```

මෙවැනි waiting reason එකක් පෙනෙන්න ඕන:

```text
ImagePullBackOff
ErrImagePull
BackOff
```

Controller poll cycle එකකට පසු AI report එක check කරන්න.

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

Report එක bad image pull incident එක identify කරලා GitOps-safe change එක මෙහි recommend කළ යුතුයි:

```text
k8s/incident/deployment.yaml
```

## Fix Incident 1

Healthy image එක restore කරන්න.

```bash
perl -0pi -e 's#image: nginx:does-not-exist-aiops-lab#image: nginx:1.27-alpine#' k8s/incident/deployment.yaml
```

Healthy state එක apply කරන්න.

```bash
kubectl apply -k k8s/incident
```

Pod එක Running state එකට ආවද verify කරන්න.

```bash
kubectl get pods -n "$WATCH_NAMESPACE"
```

මෙම change එක Git වල කරලා තියෙනවා නම් commit and push කරන්න.

```bash
git add k8s/incident/deployment.yaml
git commit -m "Restore incident demo image"
git push
```

## Incident 2 - Bad Service selector

මෙම incident එක Service selector mismatch එකක් simulate කරයි.

Pods healthy නමුත් Service selector එක pod labels වලට match නොවන නිසා Service එකට traffic route කරන්න බැහැ.

Sample repo එකට යන්න.

```bash
cd "$SAMPLE_REPO"
```

Service selector එක break කරන්න.

```bash
perl -0pi -e 's/app: incident-demo/app: wrong-incident-demo/' k8s/incident/service.yaml
```

Broken state එක apply කරන්න.

```bash
kubectl apply -k k8s/incident
```

Service selector එක check කරන්න.

```bash
kubectl get svc -n "$WATCH_NAMESPACE" incident-demo -o yaml | grep -A5 selector
```

Endpoints check කරන්න.

```bash
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

Expected symptom:

```text
ENDPOINTS   <none>
```

Controller poll cycle එකකට පසු AI report එක check කරන්න.

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

Service selector එක restore කරන්න.

```bash
perl -0pi -e 's/app: wrong-incident-demo/app: incident-demo/g' k8s/incident/service.yaml
```

Healthy state එක apply කරන්න.

```bash
kubectl apply -k k8s/incident
```

Endpoints return වෙනවද verify කරන්න.

```bash
kubectl get pods,svc,endpoints -n "$WATCH_NAMESPACE"
```

මෙම change එක Git වල කරලා තියෙනවා නම් commit and push කරන්න.

```bash
git add k8s/incident/service.yaml
git commit -m "Restore incident demo service selector"
git push
```

Next controller poll cycle එකෙන් පසු report එක healthy වෙන්න ඕන.

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

## Troubleshooting checklist

### Controller pod is not running

Pod සහ events check කරන්න.

```bash
kubectl get pods -n "$AIOPS_NAMESPACE"
kubectl describe pod -n "$AIOPS_NAMESPACE" -l app=aiops-controller
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

Common causes:

- Docker image name වැරදියි
- Docker image push වෙලා නැහැ
- Secret missing
- RBAC apply වෙලා නැහැ

### Azure OpenAI analysis does not run

Secret එක check කරන්න.

```bash
kubectl get secret aiops-openai-secret -n "$AIOPS_NAMESPACE"
```

Controller logs check කරන්න.

```bash
kubectl logs -n "$AIOPS_NAMESPACE" deploy/aiops-controller --tail=100
```

මෙම lab එක low Azure OpenAI quota එකක් භාවිතා කරයි:

```text
1 request per minute
1000 tokens per minute
```

Controller එක same incident එකකට repeat analysis throttle කරයි.

```text
INCIDENT_COOLDOWN_SECONDS=120
```

### Report still shows the old incident

Next poll cycle එක wait කරන්න.

```bash
sleep 30
```

Report එක නැවත check කරන්න.

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

### Dashboard does not open

Service එක check කරන්න.

```bash
kubectl get svc -n "$AIOPS_NAMESPACE" aiops-controller
```

Local access සඳහා port-forward භාවිතා කරන්න.

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8088:80
```

Open කරන්න:

```text
http://localhost:8088/aiops
```

### Service endpoints stay empty after restoring the selector

Service selector සහ pod labels check කරන්න.

```bash
kubectl get svc -n "$WATCH_NAMESPACE" incident-demo -o yaml | grep -A5 selector
kubectl get pods -n "$WATCH_NAMESPACE" --show-labels
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

Service selector එක pod labels වලට match විය යුතුයි.

## Cleanup

Incident app එක healthy desired state එකට restore කරන්න.

```bash
cd "$SAMPLE_REPO"

perl -0pi -e 's#image: nginx:does-not-exist-aiops-lab#image: nginx:1.27-alpine#g' k8s/incident/deployment.yaml
perl -0pi -e 's/app: wrong-incident-demo/app: incident-demo/g' k8s/incident/service.yaml

kubectl apply -k k8s/incident
```

Optional: AIOps controller Argo CD application එක remove කරන්න.

```bash
cd "$PLATFORM_REPO"

kubectl delete -f labs/aiops/01-event-driven-incident-analyzer/argocd/application.yaml
```

Optional: AIOps namespace එක remove කරන්න.

```bash
kubectl delete namespace "$AIOPS_NAMESPACE"
```

Next AIOps labs continue කරන්න අදහස් කරනවා නම් Azure OpenAI resource එක delete කරන්න එපා.

## What you completed

ඔබ AKS තුළ AIOps controller එකක් deploy කරලා, එය පහත දේවල් කරන්න පුළුවන් බව verify කළා:

- incidents සඳහා namespace එකක් watch කිරීම
- image pull failures detect කිරීම
- Service selector mismatches detect කිරීම
- live Kubernetes evidence collect කිරීම
- root cause analysis සඳහා Azure OpenAI call කිරීම
- latest RCA ConfigMap එකකට ලියීම
- browser dashboard එකක් හරහා result expose කිරීම
- workloads direct patch නොකර GitOps-safe fixes recommend කිරීම

දැන් ඔබට next AIOps labs සඳහා foundation එක තියෙනවා. ඊළඟ labs වලදී මෙම recommendation flow එක patch generation සහ human-approved pull requests දක්වා extend කළ හැක.
