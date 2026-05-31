# Known Issues

This page documents known limitations, design notes, and provider compatibility notes.

## System node pool only critical add-ons

Recommended setting:

    system_node_only_critical_addons_enabled = true

Why it matters:

This keeps the system node pool focused on Kubernetes/system workloads. User applications should run on the user node pool.

Known issue:

Changing this setting on an existing AKS cluster can require default node pool rotation.

That rotation may create a temporary node pool and require extra regional vCPU quota.

If quota is not available, Azure may return:

    ErrCode_InsufficientVCPUQuota

Recommended options:

- Enable this from the beginning for new clusters
- Request quota increase
- Use a different region
- Recreate the cluster if this is only a learning environment

## AzureRM provider deprecation warnings

Some AzureRM provider versions show deprecation warnings for certain arguments.

Known examples:

    enable_rbac_authorization

Use:

    rbac_authorization_enabled

For federated identity credential, some provider versions still expect:

    audience
    parent_id

But may show warnings for:

    resource_group_name
    parent_id

This is provider-version dependent.

Recommendation:

- Keep the working provider-compatible configuration
- Document the warning
- Update the block when upgrading to a newer major AzureRM provider version

## Key Vault uses RBAC mode

This project uses:

    rbac_authorization_enabled = true

That means Key Vault access policies are not used.

Access is controlled through Azure RBAC roles.

Important roles:

- Key Vault Secrets Officer: create/update/delete secrets
- Key Vault Secrets User: read secrets

Subscription Owner or Contributor does not automatically mean secret read/write access.

## Terraform backend uses Azure Storage

Azure Storage has management-plane and data-plane permissions.

For Terraform state blob access, the user or identity usually needs:

    Storage Blob Data Contributor

Contributor or Storage Account Contributor may not be enough for blob data operations.

## ACR is optional

This platform supports both Azure Container Registry and external registries.

If ACR is enabled:

    enable_acr = true

The platform creates ACR and AcrPull permission for AKS.

If ACR is disabled:

    enable_acr = false

You can still use public images from Docker Hub, GHCR, Quay, or other public registries.

Private external registries require Kubernetes imagePullSecret.

## Gateway API was installed manually

Current state:

- Gateway API CRDs were installed manually
- NGINX Gateway Fabric was installed manually with Helm
- Shared Gateway was created manually

This is acceptable for the current learning platform.

Future improvement:

Move Gateway API and NGINX Gateway Fabric installation into documented add-on manifests or GitOps-managed configuration.

## Monitoring was installed manually

Current state:

- kube-prometheus-stack installed with Helm
- OpenTelemetry Collector installed with Helm
- Values files are stored under platform-addons/monitoring

Future improvement:

Move monitoring installation into GitOps-managed platform add-ons.

## Grafana and Prometheus are not public by default

Grafana and Prometheus use ClusterIP services.

This is intentional for safety.

Use port-forward for learning.

Expose Grafana publicly only with:

- TLS
- Authentication
- Access control
- SSO or OAuth
- Network restrictions

Prometheus should usually remain internal.

## Local Terraform files are not committed

The following files are local and should not be committed:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- terraform.tfstate.backup
- .terraform/

Use example files instead:

- backend.tf.example
- terraform.tfvars.example
