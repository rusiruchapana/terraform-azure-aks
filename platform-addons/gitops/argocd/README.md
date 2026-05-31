# Argo CD Add-on

Argo CD can be installed as an optional GitOps lab.

This project keeps Argo CD outside the core Terraform platform so users can choose whether they want GitOps installed.

## Why Argo CD is optional

The core Terraform platform creates the Azure infrastructure and AKS cluster.

Argo CD is a platform add-on that runs on top of AKS.

Not every learner or project needs Argo CD from the beginning.

## Values file

This folder includes:

    values.yaml

The values file keeps Argo CD internal by default.

Recommended safe learning access:

- Keep Argo CD service as ClusterIP
- Use kubectl port-forward for local access
- Do not expose Argo CD publicly without TLS, authentication, and access controls

## Install example

Add Helm repo:

    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update

Install Argo CD:

    helm install argocd argo/argo-cd \
      --namespace argocd \
      --create-namespace \
      -f platform-addons/gitops/argocd/values.yaml \
      --wait

## Verify

Check pods:

    kubectl get pods -n argocd

Check services:

    kubectl get svc -n argocd

## Access locally

Port-forward:

    kubectl port-forward svc/argocd-server -n argocd 8080:443

Open:

    https://localhost:8080

## Future lab topics

Planned Argo CD labs:

- Install Argo CD
- Connect this Git repository
- Deploy one app from Git
- Use app-of-apps
- Practice drift detection
- Practice rollback
- Practice dev to qa to prod promotion
