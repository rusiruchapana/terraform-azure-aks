# GitOps Platform Add-ons

This folder is reserved for platform add-ons managed through GitOps.

## Purpose

Use this folder when you want Argo CD or Flux to manage platform add-ons from Git.

## Planned add-ons

- Gateway API and NGINX Gateway Fabric
- Monitoring with Prometheus, Grafana, and OpenTelemetry
- Secrets integrations such as External Secrets Operator or CSI Driver
- GitOps tool configuration
- Policy or security add-ons

## Current project state

The current cluster was bootstrapped manually for learning.

Manually installed add-ons include:

- Gateway API CRDs
- NGINX Gateway Fabric
- kube-prometheus-stack
- OpenTelemetry Collector

Later labs can move these add-ons into GitOps-managed manifests.

## Difference from platform-addons/

This folder:

    gitops/platform-addons/

is for desired state managed by GitOps.

This folder:

    platform-addons/

is for install values, Helm values, and add-on setup notes.

## Important note

Do not move everything into GitOps too early.

First understand the manual install flow.

Then practice converting add-ons into GitOps-managed resources.
