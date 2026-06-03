# AI Ops Labs

These labs add AI-assisted operations patterns to the AKS platform.

The goal is not to use AI as a chat assistant beside the platform. The goal is to integrate AI into infrastructure operations so that cluster events, Kubernetes evidence, GitOps state, and safe remediation workflows can be connected.

## Shared setup

Before running any AI Ops lab that calls Azure OpenAI, follow the shared setup guide:

- [Azure OpenAI setup](../shared/azure-openai-setup.md)
- [Azure OpenAI setup - Sinhala](../shared/azure-openai-setup.si.md)

Each AI Ops lab still creates and cleans its own Kubernetes resources.

## Labs

| Lab | Topic | Status |
|---|---|---|
| 01 | Event-driven Incident Analyzer | Available |
| 02 | AI Patch Recommendation | Available |
| 03 | GitHub PR Remediation | Planned |
| 04 | Alert Enrichment | Planned |
| 05 | Canary Decision Support | Planned |
| 06 | Security Finding Remediation | Planned |
| 07 | FinOps Cost Analyzer | Planned |
| 08 | Predictive Scaling Recommendations | Planned |

## Principles

- AI observes infrastructure events and evidence.
- AI does not directly patch production workloads.
- Fixes are recommended as GitOps-safe changes.
- A human reviews the recommendation before changing Git.
- Secrets are kept out of Git.

## Image usage

The GitHub sample repository can be read or forked by learners.

Docker Hub is different. Learners should not push images to the author's Docker Hub namespace.

Labs may provide two modes:

- Fast path: use the author-tested public image.
- Build path: build the image and push it to your own Docker Hub account.
