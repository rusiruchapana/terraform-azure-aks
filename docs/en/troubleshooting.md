# Troubleshooting

This page lists common issues you may face while using this AKS DevOps Practice Platform.

## Terraform says there are no configuration files

Error:

    Error: No configuration files

Why this happens:

You are running Terraform from the wrong folder.

Fix:

Go to the correct environment folder:

    cd terraform-azure-aks/environments/dev
    terraform plan

## Terraform backend access denied

Common symptoms:

    AuthorizationPermissionMismatch
    storage account access denied
    failed to access state blob

Why this happens:

Terraform remote state uses Azure Storage. Azure management roles are not always enough for blob data access.

Fix:

The user or identity running Terraform needs a data-plane role on the storage account or container.

Recommended role:

    Storage Blob Data Contributor

## VM size is not available in the selected region

Common symptoms:

    SKUNotAvailable
    requested VM size is not available

Why this happens:

Not all Azure VM sizes are available in every region or subscription.

Fix:

Use another VM size or region.

Example:

    Standard_B2s_v2

Also check quota and SKU availability before applying.

## Insufficient vCPU quota

Common symptoms:

    ErrCode_InsufficientVCPUQuota
    left regional vcpu quota 0
    requested quota 2

Why this happens:

AKS node pools and temporary rotation node pools need regional vCPU quota.

Fix options:

- Request a quota increase
- Use a different Azure region
- Use smaller VM sizes
- Reduce node count
- Recreate the cluster with required settings from the beginning

## Key Vault ForbiddenByRbac

Common symptoms:

    ForbiddenByRbac
    Caller is not authorized to perform action
    Microsoft.KeyVault/vaults/secrets/setSecret/action

Why this happens:

This project uses Key Vault RBAC mode.

Azure separates permissions into two layers:

- Management plane: create/update/delete Azure resources
- Data plane: read/write secrets, keys, certificates, and data

A subscription Owner or Contributor can create a Key Vault, but cannot automatically create or read secrets.

Fix:

To create or update secrets, assign the human/operator account:

    Key Vault Secrets Officer

To let an application read secrets, assign the workload identity:

    Key Vault Secrets User

## Workload Identity login says Identity not found

Common symptoms:

    ERROR: Identity not found
    Please run az login

Why this happens:

The command below is for managed identity endpoint login:

    az login --identity

AKS Workload Identity uses a federated token file instead.

Fix:

Use federated token login from inside the pod:

    az login \
      --service-principal \
      --username "$AZURE_CLIENT_ID" \
      --tenant "$AZURE_TENANT_ID" \
      --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"

Required checks:

- ServiceAccount has azure.workload.identity/client-id annotation
- Pod has azure.workload.identity/use: "true" label
- Federated credential subject matches namespace and ServiceAccount
- Managed identity has required Key Vault role

## ImagePullBackOff

Common symptoms:

    ImagePullBackOff
    ErrImagePull

Why this happens:

Kubernetes cannot pull the container image.

Common causes:

- Wrong image name or tag
- Private registry requires credentials
- ACR AcrPull role missing
- Docker Hub rate limit or authentication issue

Fix:

Check the pod:

    kubectl describe pod <pod-name> -n <namespace>

For ACR:

- Ensure AKS kubelet identity has AcrPull on the ACR
- Ensure image uses the correct ACR login server

For external private registries:

- Create imagePullSecret
- Reference it in the Deployment

## Gateway route not working

Common symptoms:

- External IP exists but app is not reachable
- HTTPRoute is not routing traffic
- Gateway is not programmed

Checks:

    kubectl get gateway -n platform-gateway
    kubectl get httproute -A
    kubectl describe httproute <route-name> -n <namespace>
    kubectl get svc -n <app-namespace>
    kubectl get endpoints -n <app-namespace>

Common causes:

- HTTPRoute parentRef is wrong
- Service name or port is wrong
- App pods are not Ready
- Gateway listener is not allowing routes from that namespace

Expected parentRef pattern:

    name: public-gateway
    namespace: platform-gateway

## Grafana or Prometheus is not accessible

By default, Grafana and Prometheus are ClusterIP services.

This is intentional.

Use port-forward for safe local access.

Grafana:

    kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80

Prometheus:

    kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090

Do not expose Grafana or Prometheus publicly without authentication, TLS, and access controls.

## OpenTelemetry Collector is not receiving data

Checks:

    kubectl get pods -n monitoring | grep otel
    kubectl get svc -n monitoring | grep otel
    kubectl logs -n monitoring deploy/otel-collector-opentelemetry-collector

Expected OTLP endpoints inside the cluster:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317
    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318

Common causes:

- App is sending telemetry to the wrong endpoint
- OTLP protocol mismatch
- Collector config issue
- Network policy blocking traffic
