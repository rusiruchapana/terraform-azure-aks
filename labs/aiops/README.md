# AI Ops Labs

AI Ops labs show how to integrate AI into AKS operations safely.

These labs are not about using AI as a separate chat assistant. The controller runs inside the cluster, watches real Kubernetes state, collects evidence, asks Azure OpenAI for root cause analysis, and produces GitOps-safe recommendations.

The safety rule is simple:

    AI helps investigate and prepare the fix.
    Humans approve the production change.
    GitOps applies the final change.

## Shared setup

Before running any AI Ops lab that calls Azure OpenAI, follow the shared setup guide:

- [Azure OpenAI setup](../shared/azure-openai-setup.md)
- [Azure OpenAI setup - Sinhala](../shared/azure-openai-setup.si.md)

## Current AI Ops flow

| Lab | Name | Status | Guide |
|---|---|---|---|
| 01 | Event-driven Incident Analyzer | Available | [English](01-event-driven-incident-analyzer/README.md) / [Sinhala](01-event-driven-incident-analyzer/README.si.md) |
| 02 | AI Patch Recommendation | Available | [English](02-ai-patch-recommendation/README.md) / [Sinhala](02-ai-patch-recommendation/README.si.md) |
| 03 | GitHub PR Remediation | Available | [English](03-github-pr-remediation/README.md) / [Sinhala](03-github-pr-remediation/README.si.md) |

## How the labs build up

    Lab 01
      Detect incident
      Collect evidence
      Ask Azure OpenAI for RCA
      Write report to ConfigMap
      Show report in dashboard

    Lab 02
      Everything from Lab 01
      Add patch recommendation
      Show unified diff
      Keep manual GitOps apply mode

    Lab 03
      Everything from Lab 02
      Create GitHub remediation branch
      Open Pull Request
      Human reviews and merges
      Argo CD applies the fix

## Image usage

Each lab uses an immutable controller image tag.

    Lab 01 -> docker.io/andrewferdi/aiops-controller:0.1.0
    Lab 02 -> docker.io/andrewferdi/aiops-controller:0.2.0
    Lab 03 -> docker.io/andrewferdi/aiops-controller:0.3.1

Do not use latest in lab guides. Do not overwrite old lab image tags.

## Cleanup rule

Each lab must clean the Kubernetes resources it creates or uses.

After a lab, the cluster should return to the minimal shared platform state. AI Ops lab namespaces such as aiops-system and incident-demo should not be left behind unless the next lab explicitly asks for them.
