# AI Ops Lab 03 - GitHub PR Remediation

මේ lab එකේ අපි AKS වලට safe AIOps remediation workflow එකක් හදනවා.

AIOps controller එක cluster එක බලමින් ඉන්නවා. Issue එකක් ආවොත් එය detect කරනවා, Azure OpenAI එකෙන් root cause එක හොයාගන්නවා, GitOps-safe patch එකක් හදනවා, පසුව GitHub Pull Request එකක් open කරනවා.

Controller එක cluster එක direct patch කරන්නේ නැහැ. PR එක auto merge කරන්නේත් නැහැ. User කෙනෙක් PR එක බලලා merge කළාට පස්සේ Argo CD fixed Git state එක cluster එකට sync කරනවා.

## මේ lab එකේ වෙන්නේ මොකක්ද?

මේ lab එකේ අපි මේ controller image එක use කරනවා:

```text
docker.io/andrewferdi/aiops-controller:0.3.1
```

Controller එක `incident-demo` namespace එක බලමින් ඉන්නවා.

Service selector එක වැරදි වුණොත් Service එකට endpoints නැතිවෙනවා. Controller එක ඒ issue එක detect කරලා fix එකට GitHub PR එකක් open කරනවා.

Flow එක සරලව මෙහෙමයි:

```text
Git වල bad config එකක් තියෙනවා
  -> Argo CD ඒක AKS වලට sync කරනවා
  -> Service endpoints empty වෙනවා
  -> AIOps controller issue එක detect කරනවා
  -> Azure OpenAI root cause එක explain කරනවා
  -> Controller safe patch එකක් හදනවා
  -> Controller GitHub PR එකක් open කරනවා
  -> User PR එක review කරලා merge කරනවා
  -> Argo CD fixed config එක sync කරනවා
  -> Cluster එක ආයෙත් healthy වෙනවා
```

මේක prompt එකක් අහලා answer එකක් ගන්න lab එකක් නෙවෙයි. AI එක infrastructure workflow එකේම කොටසක් විදිහට වැඩ කරනවා.

## ඔබ ඉගෙනගන්න දේවල්

මේ lab එකෙන් ඔබ ඉගෙනගන්නේ:

- AKS ඇතුළේ AIOps controller එකක් run කරන විදිහ
- Real Kubernetes Service issue එකක් detect කරන විදිහ
- Live cluster evidence collect කරන විදිහ
- Azure OpenAI use කරලා root cause analysis කරන විදිහ
- GitOps-safe patch එකක් හදන විදිහ
- GitHub Pull Request එකක් automatically open කරන විදිහ
- Human review එක remediation path එකේ තියාගන්න විදිහ
- PR merge වුණාට පස්සේ Argo CD cluster එක fix කරන විදිහ
- Dashboard, GitHub UI, Argo CD, Kubernetes වලින් status verify කරන විදිහ

## Architecture

```text
GitHub repo branch
  |
  | Argo CD sync
  v
AKS cluster
  |
  | issue happens
  v
AIOps controller
  |
  | collect evidence
  v
Azure OpenAI
  |
  | RCA + fix location
  v
AIOps controller
  |
  | GitHub API
  v
GitHub Pull Request
  |
  | human merge
  v
Argo CD sync
  |
  v
AKS cluster fixed
```

මෙතන safety boundary එක වැදගත්:

```text
AI cluster එක direct patch කරන්නේ නැහැ.
AI PR එක merge කරන්නේ නැහැ.
Human review එක අවශ්‍යයි.
GitOps තමයි final change එක cluster එකට apply කරන්නේ.
```

## Components

| Component | Purpose |
|---|---|
| AKS | demo workload එක සහ AIOps controller එක run කරනවා |
| Argo CD | Git desired state එක cluster එකට sync කරනවා |
| Azure OpenAI | root cause analysis එක හදනවා |
| AIOps controller | incident detect කරලා patch සහ PR හදනවා |
| GitHub | GitOps files සහ remediation PRs තියෙන තැන |
| ConfigMap | latest AIOps report එක store කරනවා |
| Dashboard | incident, patch, PR status පෙන්වනවා |

## අවශ්‍ය දේවල්

Start කරන්න කලින් ඔබට මේවා ඕන:

- මේ platform එකෙන් provision කරපු AKS cluster එක
- Argo CD installed and working
- Gateway API / NGINX Gateway Fabric installed
- Azure OpenAI setup complete
- sample GitOps repo එකේ ඔබගේ fork එක
- ඔබගේ fork එකට write කරන්න පුළුවන් GitHub fine-grained token එකක්
- Docker installed, ඔබ image එක build කරන්න යනවා නම්
- `kubectl` ඔබගේ AKS cluster එකට configured

මේ lab එක clean cluster state එකකින් start වෙන්න ඕන. කලින් lab එකක Kubernetes leftovers මත depend වෙන්න එපා.

## ඔබගේ sample repo fork එක prepare කිරීම

මේ lab එක GitHub PR එකක් create කරන නිසා ඔබගේම fork එක use කරන්න ඕන.

ඔබගේ GitHub username එක set කරන්න:

```bash
export GITHUB_USER="<your-github-username>"
```

ඔබගේ fork එක clone කරන්න:

```bash
export WORKDIR="$HOME/aks-labs"
mkdir -p "$WORKDIR"

cd "$WORKDIR"

git clone "https://github.com/$GITHUB_USER/aks-gitops-sample-app.git"
cd aks-gitops-sample-app
```

Upstream repo එක add කරන්න:

```bash
git remote add upstream https://github.com/andrewferdinandus/aks-gitops-sample-app.git || true
git fetch upstream
```

Author-tested Lab 03 branch එකෙන් ඔබගේ fork එකට branch එක create කර push කරන්න:

```bash
git checkout -B aiops-lab-03-github-pr-remediation upstream/aiops-lab-03-github-pr-remediation
git push -u origin aiops-lab-03-github-pr-remediation
```

Verify කරන්න:

```bash
git branch --show-current
grep -n "image:" k8s/aiops-controller/deployment.yaml
grep -n "app:" k8s/incident/service.yaml
```

Expected:

```text
aiops-lab-03-github-pr-remediation
image: docker.io/andrewferdi/aiops-controller:0.3.1
app: incident-demo
app: incident-demo
```

## Lab variables set කිරීම

```bash
export SAMPLE_REPO="$WORKDIR/aks-gitops-sample-app"
export PLATFORM_REPO="$WORKDIR/terraform-azure-aks"

export AIOPS_NAMESPACE="aiops-system"
export WATCH_NAMESPACE="incident-demo"
export AIOPS_REPORT_CONFIGMAP="aiops-latest-incident-report"

export GITHUB_OWNER="$GITHUB_USER"
export GITHUB_REPO="aks-gitops-sample-app"
export GITHUB_BASE_BRANCH="aiops-lab-03-github-pr-remediation"
export GITHUB_PR_BRANCH_PREFIX="aiops-remediation"

export SAMPLE_REPO_FORK_URL="https://github.com/$GITHUB_OWNER/$GITHUB_REPO.git"
```

Verify කරන්න:

```bash
echo "$SAMPLE_REPO"
echo "$PLATFORM_REPO"
echo "$SAMPLE_REPO_FORK_URL"
echo "$GITHUB_BASE_BRANCH"
```

## Azure OpenAI prerequisite

මේ lab එකට Azure OpenAI ඕන.

මුලින් මේ shared setup guide එක follow කරන්න:

```text
../../shared/azure-openai-setup.si.md
```

ඊට පස්සේ ඔබගේ terminal එකේ මේ values තියෙන්න ඕන:

```bash
AZURE_OPENAI_ENDPOINT
AZURE_OPENAI_KEY
AZURE_OPENAI_DEPLOYMENT
AZURE_OPENAI_API_VERSION
```

Key එක print නොකර verify කරන්න:

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_API_VERSION"
test -n "$AZURE_OPENAI_KEY" && echo "AZURE_OPENAI_KEY is set"
```

## GitHub token එකක් create කිරීම

ඔබගේ fork එකට fine-grained GitHub token එකක් create කරන්න.

අවශ්‍ය access:

```text
Repository: ඔබගේ aks-gitops-sample-app fork එක
Contents: Read and write
Pull requests: Read and write
Metadata: Read-only
```

Token එක Git වලට commit කරන්න එපා. Chat එකට paste කරන්නත් එපා.

Terminal එකේ විතරක් export කරන්න:

```bash
export GITHUB_TOKEN="<your-github-token>"
```

Token value එක print නොකර verify කරන්න:

```bash
test -n "$GITHUB_TOKEN" && echo "GITHUB_TOKEN is set"
```

GitHub access test කරන්න:

```bash
curl -s \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("full_name")); print("permissions:", d.get("permissions"))'
```

Repo name එක සහ write permission පේන්න ඕන.

## Clean start verify කිරීම

```bash
kubectl get ns | grep -E 'aiops-system|incident-demo' || true
kubectl get pods -A | grep -E 'aiops|incident-demo' || true
kubectl get application -n argocd | grep -E 'aiops-pr' || true
```

Expected: Lab 03 resources නැතිවෙන්න ඕන.

Local port `8088` free ද බලන්න:

```bash
lsof -iTCP:8088 -sTCP:LISTEN || true
```

## Kubernetes secrets create කිරීම

හැම lab එකක්ම තමන්ට අවශ්‍ය secrets create කරගන්නවා. කලින් lab එකක secret reuse කරන්න එපා.

```bash
kubectl create namespace "$AIOPS_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic aiops-openai-secret \
  -n "$AIOPS_NAMESPACE" \
  --from-literal=AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
  --from-literal=AZURE_OPENAI_KEY="$AZURE_OPENAI_KEY" \
  --from-literal=AZURE_OPENAI_DEPLOYMENT="$AZURE_OPENAI_DEPLOYMENT" \
  --from-literal=AZURE_OPENAI_API_VERSION="$AZURE_OPENAI_API_VERSION" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic aiops-github-secret \
  -n "$AIOPS_NAMESPACE" \
  --from-literal=GITHUB_TOKEN="$GITHUB_TOKEN" \
  --from-literal=GITHUB_OWNER="$GITHUB_OWNER" \
  --from-literal=GITHUB_REPO="$GITHUB_REPO" \
  --from-literal=GITHUB_BASE_BRANCH="$GITHUB_BASE_BRANCH" \
  --from-literal=GITHUB_PR_BRANCH_PREFIX="$GITHUB_PR_BRANCH_PREFIX" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Secret values print නොකර verify කරන්න:

```bash
kubectl get secret aiops-openai-secret -n "$AIOPS_NAMESPACE"
kubectl get secret aiops-github-secret -n "$AIOPS_NAMESPACE"
```

## Argo CD applications create කිරීම

මේ lab එකේ Argo CD applications දෙකක් use කරනවා:

- `incident-demo` app එකට එකක්
- AIOps controller එකට එකක්

Application files වල repo URL එක ඔබගේ fork එකට update කරන්න:

```bash
cd "$PLATFORM_REPO"

sed -i.bak "s#https://github.com/andrewferdinandus/aks-gitops-sample-app.git#$SAMPLE_REPO_FORK_URL#g" \
  labs/aiops/03-github-pr-remediation/argocd/*.yaml

rm -f labs/aiops/03-github-pr-remediation/argocd/*.bak
```

Apps apply කරන්න:

```bash
kubectl apply -f labs/aiops/03-github-pr-remediation/argocd/incident-demo-application.yaml
kubectl apply -f labs/aiops/03-github-pr-remediation/argocd/controller-application.yaml
```

Status බලන්න:

```bash
kubectl get application -n argocd aiops-pr-incident-demo
kubectl get application -n argocd aiops-pr-controller
```

Pods ready වෙනකම් wait කරන්න:

```bash
kubectl rollout status deploy/incident-demo -n "$WATCH_NAMESPACE" --timeout=120s
kubectl rollout status deploy/aiops-controller -n "$AIOPS_NAMESPACE" --timeout=120s

kubectl get pods -n "$WATCH_NAMESPACE"
kubectl get pods -n "$AIOPS_NAMESPACE"
```

## Dashboard open කිරීම

වෙන terminal එකක මේක run කරන්න:

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8088:80
```

Browser එකේ open කරන්න:

```text
http://localhost:8088/aiops
```

Start එකේ dashboard එකේ මෙහෙම පේන්න ඕන:

```text
status: healthy
patch_recommendation: null
pull_request_recommendation: null
```

## GitOps incident එකක් create කිරීම

දැන් issue එක Git වලින්ම create කරමු.

Lab 03 branch එකේ Service selector එක break කරන්න:

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

git status
git add k8s/incident/service.yaml
git commit -m "Break incident service selector for AIOps PR test"
git push
```

Argo CD bad desired state එක cluster එකට sync කරයි.

Argo CD refresh කරලා incident එක verify කරන්න:

```bash
kubectl annotate application aiops-pr-incident-demo -n argocd argocd.argoproj.io/refresh=hard --overwrite

sleep 45

kubectl get svc -n "$WATCH_NAMESPACE" incident-demo -o yaml | grep -A5 selector
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

Expected:

```text
selector:
  app: wrong-incident-demo

ENDPOINTS   <none>
```

## AIOps result බලන්න

Controller එකට ටිකක් වෙලා දෙන්න:

```bash
sleep 75
```

Dashboard එක refresh කරන්න:

```text
http://localhost:8088/aiops
```

Dashboard එකේ මෙවගේ පේන්න ඕන:

```text
status: incident_detected
patch recommendation: available
pull request recommendation status: created
PR URL: https://github.com/...
auto merge: not performed
```

Raw report එක බලන්න ඕන නම්:

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

වැදගත් part එක:

```text
pull_request_recommendation.status = created
pull_request_recommendation.url = GitHub PR URL
human_review_required = true
auto_merge = not_performed
direct_cluster_changes = not_performed
```

## PR එක review කර merge කිරීම

Dashboard එකේ පෙන්වන PR URL එක open කරන්න.

GitHub UI එකේ මේවා බලන්න:

```text
Base branch: aiops-lab-03-github-pr-remediation
Source branch: aiops-remediation/...
Changed file: k8s/incident/service.yaml
```

Diff එක මෙහෙම වෙන්න ඕන:

```diff
-    app: wrong-incident-demo
+    app: incident-demo
```

PR එක manually merge කරන්න.

මෙතන තමයි human approval step එක. Controller එක PR එක merge කරන්නේ නැහැ.

## Argo CD cluster එක fix කරනවද බලන්න

PR එක merge කළාට පස්සේ Argo CD refresh කරන්න:

```bash
kubectl annotate application aiops-pr-incident-demo -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate application aiops-pr-controller -n argocd argocd.argoproj.io/refresh=hard --overwrite

sleep 45
```

Argo CD status බලන්න:

```bash
kubectl get application -n argocd aiops-pr-incident-demo
kubectl get application -n argocd aiops-pr-controller
```

Service එක බලන්න:

```bash
kubectl get svc -n "$WATCH_NAMESPACE" incident-demo -o yaml | grep -A5 selector
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

Expected:

```text
selector:
  app: incident-demo

ENDPOINTS:
<pod-ip>:80,<pod-ip>:80
```

Controller report එක healthy වෙනකම් wait කරන්න:

```bash
sleep 45

kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

Expected:

```text
status: healthy
message: No supported incident detected.
patch_recommendation: null
pull_request_recommendation: null
```

Dashboard එකත් healthy වෙන්න ඕන.

## Troubleshooting

### Dashboard එක open වෙන්නේ නැත්නම්

Port එක busy ද බලන්න:

```bash
lsof -iTCP:8088 -sTCP:LISTEN || true
```

වෙන port එකක් use කරන්න:

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8099:80
```

Open කරන්න:

```text
http://localhost:8099/aiops
```

### PR එක create නොවුණොත්

Report එක බලන්න:

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

Common reasons:

```text
GitHub token missing
GitHub token එකට Contents write permission නැහැ
GitHub token එකට Pull requests write permission නැහැ
GitHub base branch එකේ broken value එක නැහැ
Controller cooldown එකේ ඉන්නවා
```

PR එක create වෙන්න නම් GitHub base branch එකේ broken value එක තියෙන්න ඕන.

### PRs ගොඩක් create වුණොත්

Testing අතරතුර controller restart කළොත් හෝ issue එක නැවත නැවත trigger කළොත් duplicate PRs create වෙන්න පුළුවන්.

Dashboard report එකේ තියෙන PR URL එක source of truth එක කරගන්න.

```text
pull_request_recommendation.url
```

ඒ PR එක merge කරලා, duplicate PRs GitHub UI එකෙන් close කරන්න.

### Argo CD Progressing කියලා පෙන්වුණත් pod Running නම්

Real workload state එක බලන්න:

```bash
kubectl get pods -n "$AIOPS_NAMESPACE"
kubectl get pods -n "$WATCH_NAMESPACE"
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

මේ lab එකේ important checks:

```text
PR merged
Service endpoints returned
AIOps report healthy
Dashboard healthy
```

## Cleanup

Port-forward terminal එක `Ctrl+C` කරලා stop කරන්න.

Argo CD applications delete කරන්න:

```bash
cd "$PLATFORM_REPO"

kubectl delete -f labs/aiops/03-github-pr-remediation/argocd/controller-application.yaml --ignore-not-found=true
kubectl delete -f labs/aiops/03-github-pr-remediation/argocd/incident-demo-application.yaml --ignore-not-found=true
```

මේ lab එක use කළ namespaces delete කරන්න:

```bash
kubectl delete namespace "$AIOPS_NAMESPACE" --ignore-not-found=true
kubectl delete namespace "$WATCH_NAMESPACE" --ignore-not-found=true
```

Cleanup verify කරන්න:

```bash
kubectl get application -n argocd | grep -E 'aiops-pr' || true
kubectl get ns | grep -E 'aiops-system|incident-demo' || true
kubectl get pods -A | grep -E 'aiops|incident-demo' || true
```

Local sample repo state clean කරගන්න:

```bash
cd "$SAMPLE_REPO"

git checkout "$GITHUB_BASE_BRANCH"
git pull

grep -n "app:" k8s/incident/service.yaml
git status
```

GitHub cleanup:

- Dashboard/report එකේ පෙන්වන PR එක විතරක් merge කරන්න.
- Testing අතරතුර duplicate AIOps remediation PRs create වුණා නම් ඒවා GitHub UI එකෙන් close කරන්න.
- අවශ්‍ය නැති `aiops-remediation/*` branches delete කරන්න.
- මෙම lab එකට temporary GitHub token එකක් create කළා නම්, lab එකෙන් පස්සේ GitHub UI එකෙන් revoke කරන්න.

ඔබ Azure OpenAI resource එක AI Ops labs සඳහා පමණක් create කරලා තව labs continue නොකරනවා නම්, shared setup guide එකේ cloud cleanup section එක follow කරන්න:

```text
../../shared/azure-openai-setup.si.md
```

## ඔබ complete කළ දේ

ඔබ දැන් full GitOps-safe AIOps remediation workflow එකක් build කළා:

```text
Git issue
-> Argo CD issue එක sync කරනවා
-> Cluster එක break වෙනවා
-> AIOps issue එක detect කරනවා
-> Azure OpenAI root cause එක explain කරනවා
-> AIOps GitHub PR එකක් create කරනවා
-> Human PR එක merge කරනවා
-> Argo CD cluster එක fix කරනවා
-> Dashboard එක healthy වෙනවා
```

මේ pattern එක safe automation එකක්. AI investigation සහ fix preparation වලට help කරනවා. Production change එක approve කරන්නේ human.
