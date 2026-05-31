#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-aks-dev-001}"
AKS_NAME="${AKS_NAME:-aks-dev-001}"
MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"

echo "== AKS cluster =="
az aks show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_NAME" \
  --query "{name:name, resourceGroup:resourceGroup, location:location, kubernetesVersion:kubernetesVersion, powerState:powerState.code}" \
  --output table

echo
echo "== Current Kubernetes context =="
kubectl config current-context

echo
echo "== Nodes =="
kubectl get nodes -o wide

echo
echo "== Node metrics =="
kubectl top nodes || true

echo
echo "== kube-system pods =="
kubectl get pods -n kube-system

echo
echo "== Metrics server =="
kubectl get deployment metrics-server -n kube-system || true

echo
echo "== Recent events =="
kubectl get events --all-namespaces --sort-by=.lastTimestamp | tail -20 || true

echo
echo "== Azure Monitor addon status =="
az aks show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_NAME" \
  --query "addonProfiles.omsagent" \
  --output json

echo
echo "== In-cluster monitoring namespace =="
kubectl get namespace "$MONITORING_NAMESPACE" || true

echo
echo "== In-cluster monitoring pods =="
kubectl get pods -n "$MONITORING_NAMESPACE" || true

echo
echo "== In-cluster monitoring services =="
kubectl get svc -n "$MONITORING_NAMESPACE" || true

echo
echo "== Helm releases in monitoring namespace =="
helm list -n "$MONITORING_NAMESPACE" || true
