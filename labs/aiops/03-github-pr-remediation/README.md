# AI Ops Lab 03 - GitHub PR Remediation

In this lab, you build a safe AIOps remediation workflow for AKS.

The AIOps controller watches the cluster, detects a real incident, asks Azure OpenAI for root cause analysis, builds a GitOps-safe patch, and opens a GitHub Pull Request with the recommended fix.

The controller does not patch the cluster directly. It does not auto-merge the Pull Request. A human must review and merge the PR. After the PR is merged, Argo CD syncs the fixed Git state back to the cluster.

## What this lab does

This lab uses the `aiops-controller` image:

```text
docker.io/andrewferdi/aiops-controller:0.3.1
```

The controller watches the `incident-demo` namespace.

When the Service selector is wrong, the Service has no endpoints. The controller detects that issue and creates a remediation PR.

The workflow looks like this:

```text
Bad Git config
  -> Argo CD syncs it to AKS
  -> Service endpoints become empty
  -> AIOps controller detects the issue
  -> Azure OpenAI explains the root cause
  -> Controller builds a safe patch
  -> Controller opens a GitHub PR
  -> Human reviews and merges the PR
  -> Argo CD syncs the fixed config
  -> Cluster becomes healthy again
```

This is not a prompt-only AI lab. The AI is part of the infrastructure workflow.

## What you will learn

You will learn how to:

- Run an AIOps controller inside AKS
- Detect a real Kubernetes Service incident
- Collect live cluster evidence
- Use Azure OpenAI for root cause analysis
- Generate a GitOps-safe patch
- Create a GitHub Pull Request automatically
- Keep human review in the remediation path
- Let Argo CD apply the fix after the PR is merged
- Verify the workflow from the dashboard, GitHub UI, Argo CD, and Kubernetes

## Architecture

```text
GitHub repo branch
  |
  | Argo CD sync
  v
AKS cluster
  |
  | incident happens
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

The safety boundary is important:

```text
AI does not patch the cluster.
AI does not merge the PR.
Human review is required.
GitOps applies the final change.
```

## Components

| Component | Purpose |
|---|---|
| AKS | Runs the demo workload and AIOps controller |
| Argo CD | Syncs Git desired state into the cluster |
| Azure OpenAI | Produces the root cause analysis |
| AIOps controller | Detects incidents, creates patch recommendations, and opens PRs |
| GitHub | Stores the GitOps files and receives remediation PRs |
| ConfigMap | Stores the latest AIOps report |
| Dashboard | Shows incident, patch, and PR status |

## What this lab requires

Before you start, you need:

- AKS cluster from this platform
- Argo CD installed and working
- Gateway API / NGINX Gateway Fabric installed
- Azure OpenAI setup completed
- Your own fork of the sample GitOps repo
- A GitHub fine-grained token for your fork
- Docker installed only if you want to build your own image
- `kubectl` configured for your AKS cluster

This lab should start from a clean cluster state. Do not depend on Kubernetes leftovers from previous labs.

## Prepare your sample repo fork

This lab creates a GitHub PR. Because of that, you must use your own fork of the sample repo.

Set your GitHub username:

```bash
export GITHUB_USER="<your-github-username>"
```

Clone your fork:

```bash
export WORKDIR="$HOME/aks-labs"
mkdir -p "$WORKDIR"

cd "$WORKDIR"

git clone "https://github.com/$GITHUB_USER/aks-gitops-sample-app.git"
cd aks-gitops-sample-app
```

Add the upstream repo:

```bash
git remote add upstream https://github.com/andrewferdinandus/aks-gitops-sample-app.git || true
git fetch upstream
```

Create the Lab 03 branch from the author-tested branch and push it to your fork:

```bash
git checkout -B aiops-lab-03-github-pr-remediation upstream/aiops-lab-03-github-pr-remediation
git push -u origin aiops-lab-03-github-pr-remediation
```

Verify:

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

## Set lab variables

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

Verify:

```bash
echo "$SAMPLE_REPO"
echo "$PLATFORM_REPO"
echo "$SAMPLE_REPO_FORK_URL"
echo "$GITHUB_BASE_BRANCH"
```

## Azure OpenAI prerequisite

This lab needs Azure OpenAI.

Follow the shared setup guide first:

```text
../../shared/azure-openai-setup.md
```

After that, your terminal should have:

```bash
AZURE_OPENAI_ENDPOINT
AZURE_OPENAI_KEY
AZURE_OPENAI_DEPLOYMENT
AZURE_OPENAI_API_VERSION
```

Verify without printing the key:

```bash
echo "$AZURE_OPENAI_ENDPOINT"
echo "$AZURE_OPENAI_DEPLOYMENT"
echo "$AZURE_OPENAI_API_VERSION"
test -n "$AZURE_OPENAI_KEY" && echo "AZURE_OPENAI_KEY is set"
```

## Create a GitHub token

Create a fine-grained GitHub token for your fork.

Required access:

```text
Repository: your fork of aks-gitops-sample-app
Contents: Read and write
Pull requests: Read and write
Metadata: Read-only
```

Do not commit this token. Do not paste it into documentation or chat.

Export it only in your terminal:

```bash
export GITHUB_TOKEN="<your-github-token>"
```

Verify without printing it:

```bash
test -n "$GITHUB_TOKEN" && echo "GITHUB_TOKEN is set"
```

Test GitHub access:

```bash
curl -s \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("full_name")); print("permissions:", d.get("permissions"))'
```

You should see your repo name and write permission.

## Verify clean start

```bash
kubectl get ns | grep -E 'aiops-system|incident-demo' || true
kubectl get pods -A | grep -E 'aiops|incident-demo' || true
kubectl get application -n argocd | grep -E 'aiops-pr' || true
```

Expected: no Lab 03 resources.

Also check that local port `8088` is free:

```bash
lsof -iTCP:8088 -sTCP:LISTEN || true
```

## Create Kubernetes secrets

Each lab creates its own secrets. Do not reuse secrets left behind by another lab.

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

Verify the secrets exist without printing values:

```bash
kubectl get secret aiops-openai-secret -n "$AIOPS_NAMESPACE"
kubectl get secret aiops-github-secret -n "$AIOPS_NAMESPACE"
```

## Create Argo CD applications

This lab uses two Argo CD applications:

- one for the `incident-demo` app
- one for the AIOps controller

Update the repo URL in the application files to your fork:

```bash
cd "$PLATFORM_REPO"

sed -i.bak "s#https://github.com/andrewferdinandus/aks-gitops-sample-app.git#$SAMPLE_REPO_FORK_URL#g" \
  labs/aiops/03-github-pr-remediation/argocd/*.yaml

rm -f labs/aiops/03-github-pr-remediation/argocd/*.bak
```

Apply the apps:

```bash
kubectl apply -f labs/aiops/03-github-pr-remediation/argocd/incident-demo-application.yaml
kubectl apply -f labs/aiops/03-github-pr-remediation/argocd/controller-application.yaml
```

Check status:

```bash
kubectl get application -n argocd aiops-pr-incident-demo
kubectl get application -n argocd aiops-pr-controller
```

Wait for the pods:

```bash
kubectl rollout status deploy/incident-demo -n "$WATCH_NAMESPACE" --timeout=120s
kubectl rollout status deploy/aiops-controller -n "$AIOPS_NAMESPACE" --timeout=120s

kubectl get pods -n "$WATCH_NAMESPACE"
kubectl get pods -n "$AIOPS_NAMESPACE"
```

## Open the dashboard

Run this in a separate terminal:

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8088:80
```

Open:

```text
http://localhost:8088/aiops
```

At the start, the dashboard should show:

```text
status: healthy
patch_recommendation: null
pull_request_recommendation: null
```

## Create a GitOps incident

Now create the issue from Git.

Break the Service selector in your Lab 03 branch:

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

Argo CD will sync the bad desired state to the cluster.

Refresh Argo CD and verify the incident:

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

## Watch the AIOps result

Wait for the controller:

```bash
sleep 75
```

Refresh the dashboard:

```text
http://localhost:8088/aiops
```

The dashboard should now show:

```text
status: incident_detected
patch recommendation: available
pull request recommendation status: created
PR URL: https://github.com/...
auto merge: not performed
```

You can also read the raw report:

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

The important part is:

```text
pull_request_recommendation.status = created
pull_request_recommendation.url = GitHub PR URL
human_review_required = true
auto_merge = not_performed
direct_cluster_changes = not_performed
```

## Review and merge the PR

Open the PR URL shown in the dashboard.

In GitHub, check:

```text
Base branch: aiops-lab-03-github-pr-remediation
Source branch: aiops-remediation/...
Changed file: k8s/incident/service.yaml
```

The diff should be:

```diff
-    app: wrong-incident-demo
+    app: incident-demo
```

Merge the PR manually.

This is the approval point. The controller does not merge it for you.

## Verify Argo CD fixes the cluster

After merging the PR, refresh Argo CD:

```bash
kubectl annotate application aiops-pr-incident-demo -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate application aiops-pr-controller -n argocd argocd.argoproj.io/refresh=hard --overwrite

sleep 45
```

Check Argo CD:

```bash
kubectl get application -n argocd aiops-pr-incident-demo
kubectl get application -n argocd aiops-pr-controller
```

Check the Service:

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

Wait for the controller to return to healthy:

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

The dashboard should also return to healthy.

## Troubleshooting

### Dashboard does not open

Check the local port:

```bash
lsof -iTCP:8088 -sTCP:LISTEN || true
```

Use another port if needed:

```bash
kubectl port-forward -n "$AIOPS_NAMESPACE" svc/aiops-controller 8099:80
```

Open:

```text
http://localhost:8099/aiops
```

### PR is not created

Check the report:

```bash
kubectl get cm -n "$AIOPS_NAMESPACE" "$AIOPS_REPORT_CONFIGMAP" \
  -o jsonpath='{.data.report\.json}'; echo
```

Common causes:

```text
GitHub token is missing
GitHub token does not have Contents write permission
GitHub token does not have Pull requests write permission
The GitHub base branch does not contain the broken value
Controller is still in cooldown
```

The GitHub base branch must contain the broken value before the controller can create a fix PR.

### Too many PRs were created

During testing, restarting the controller or repeatedly triggering the same incident can create duplicate PRs.

Use the dashboard report as the source of truth. Merge the PR shown in:

```text
pull_request_recommendation.url
```

Close the duplicate PRs manually in GitHub.

### Argo CD says Progressing but the pod is running

Check the real workload state:

```bash
kubectl get pods -n "$AIOPS_NAMESPACE"
kubectl get pods -n "$WATCH_NAMESPACE"
kubectl get endpoints -n "$WATCH_NAMESPACE" incident-demo
```

For this lab, the most important checks are:

```text
PR merged
Service endpoints returned
AIOps report is healthy
Dashboard is healthy
```

## Cleanup

Stop the port-forward terminal with `Ctrl+C`.

Delete the Argo CD applications:

```bash
cd "$PLATFORM_REPO"

kubectl delete -f labs/aiops/03-github-pr-remediation/argocd/controller-application.yaml --ignore-not-found=true
kubectl delete -f labs/aiops/03-github-pr-remediation/argocd/incident-demo-application.yaml --ignore-not-found=true
```

Delete the namespaces used by this lab:

```bash
kubectl delete namespace "$AIOPS_NAMESPACE" --ignore-not-found=true
kubectl delete namespace "$WATCH_NAMESPACE" --ignore-not-found=true
```

Verify cleanup:

```bash
kubectl get application -n argocd | grep -E 'aiops-pr' || true
kubectl get ns | grep -E 'aiops-system|incident-demo' || true
kubectl get pods -A | grep -E 'aiops|incident-demo' || true
```

Clean local sample repo state:

```bash
cd "$SAMPLE_REPO"

git checkout "$GITHUB_BASE_BRANCH"
git pull

grep -n "app:" k8s/incident/service.yaml
git status
```

If you created a temporary GitHub token only for this lab, revoke it from GitHub after the lab.

If you created Azure OpenAI only for the AI Ops labs and you are not continuing, follow the cloud cleanup section in:

```text
../../shared/azure-openai-setup.md
```

## What you completed

You built a full GitOps-safe AIOps remediation workflow:

```text
Git issue
-> Argo CD syncs issue
-> Cluster breaks
-> AIOps detects the issue
-> Azure OpenAI explains root cause
-> AIOps creates a GitHub PR
-> Human merges PR
-> Argo CD fixes the cluster
-> Dashboard returns healthy
```

This pattern keeps automation useful and safe. The AI helps investigate and prepare the fix, but humans still approve the production change.
