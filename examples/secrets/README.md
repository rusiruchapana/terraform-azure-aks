# Secrets Examples

This folder contains examples for handling secrets in AKS.

## Planned examples

- Workload Identity
- External Secrets Operator
- Secrets Store CSI Driver

## Learning purpose

Use these examples to understand how applications can access secrets without hardcoding sensitive values in manifests or container images.

## Recommended direction

For Azure-native scenarios, prefer:

- Azure Key Vault
- AKS Workload Identity
- Least privilege Azure RBAC

## Important note

Do not commit real secrets to Git.

Never commit passwords, tokens, client secrets, private keys, or production secret values.
