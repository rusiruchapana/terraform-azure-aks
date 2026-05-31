# Troubleshooting - ගැටළු විසඳීම

මෙම page එකේ AKS DevOps Practice Platform එක use කරනකොට එන්න පුළුවන් common issues explain කරනවා.

## Terraform කියනවා configuration files නැහැ කියලා

Error:

    Error: No configuration files

ඇයි මෙහෙම වෙන්නේ?

ඔයා Terraform command එක run කරන්නේ වැරදි folder එකකින්.

Fix:

Correct environment folder එකට යන්න:

    cd terraform-azure-aks/environments/dev
    terraform plan

## Terraform backend access denied

Common symptoms:

    AuthorizationPermissionMismatch
    storage account access denied
    failed to access state blob

ඇයි මෙහෙම වෙන්නේ?

Terraform remote state Azure Storage එකේ තියෙනවා. Azure management roles තියෙන එක blob data access සඳහා හැමවෙලාවෙම enough නෙවෙයි.

Fix:

Terraform run කරන user එකට හෝ identity එකට Storage blob data-plane role එකක් ඕන.

Recommended role:

    Storage Blob Data Contributor

## VM size එක selected region එකේ available නැහැ

Common symptoms:

    SKUNotAvailable
    requested VM size is not available

ඇයි මෙහෙම වෙන්නේ?

Azure VM sizes හැම region එකකම හෝ හැම subscription එකකම available නැහැ.

Fix:

වෙන VM size එකක් හෝ region එකක් use කරන්න.

Example:

    Standard_B2s_v2

Apply කරන්න කලින් quota සහ SKU availability check කරන්න.

## vCPU quota මදි

Common symptoms:

    ErrCode_InsufficientVCPUQuota
    left regional vcpu quota 0
    requested quota 2

ඇයි මෙහෙම වෙන්නේ?

AKS node pools වලට සහ temporary rotation node pools වලට regional vCPU quota ඕන.

Fix options:

- Azure quota increase request කරන්න
- වෙන Azure region එකක් use කරන්න
- smaller VM size එකක් use කරන්න
- node count අඩු කරන්න
- learning environment එකක් නම් cluster එක recreate කරන්න

## Key Vault ForbiddenByRbac

Common symptoms:

    ForbiddenByRbac
    Caller is not authorized to perform action
    Microsoft.KeyVault/vaults/secrets/setSecret/action

ඇයි මෙහෙම වෙන්නේ?

මෙම project එක Key Vault RBAC mode එක use කරනවා.

Azure permissions layers දෙකක් තියෙනවා:

- Management plane: Azure resource create/update/delete
- Data plane: secrets, keys, certificates, data read/write

Subscription Owner හෝ Contributor කෙනෙක්ට Key Vault resource එක create කරන්න පුළුවන්. හැබැයි secrets create/read කරන්න automatically permission ලැබෙන්නේ නැහැ.

Fix:

Secrets create/update කරන්න human/operator account එකට assign කරන්න:

    Key Vault Secrets Officer

Application එකට secrets read කරන්න workload identity එකට assign කරන්න:

    Key Vault Secrets User

## Workload Identity login එක Identity not found කියනවා

Common symptoms:

    ERROR: Identity not found
    Please run az login

ඇයි මෙහෙම වෙන්නේ?

මේ command එක managed identity endpoint login සඳහා:

    az login --identity

AKS Workload Identity use කරන්නේ federated token file එකක්.

Fix:

Pod එක ඇතුළේ federated token login use කරන්න:

    az login \
      --service-principal \
      --username "$AZURE_CLIENT_ID" \
      --tenant "$AZURE_TENANT_ID" \
      --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"

Check කරන්න:

- ServiceAccount එකට azure.workload.identity/client-id annotation තියෙනවද
- Pod එකට azure.workload.identity/use: "true" label තියෙනවද
- Federated credential subject එක namespace සහ ServiceAccount එකට match වෙනවද
- Managed identity එකට required Key Vault role තියෙනවද

## ImagePullBackOff

Common symptoms:

    ImagePullBackOff
    ErrImagePull

ඇයි මෙහෙම වෙන්නේ?

Kubernetes ට container image එක pull කරන්න බැරි වෙලා.

Common causes:

- Image name හෝ tag වැරදියි
- Private registry credentials ඕන
- ACR AcrPull role missing
- Docker Hub rate limit හෝ auth issue

Fix:

Pod එක describe කරන්න:

    kubectl describe pod <pod-name> -n <namespace>

ACR සඳහා:

- AKS kubelet identity එකට ACR scope එකේ AcrPull තියෙනවද බලන්න
- Image එක correct ACR login server එක use කරනවද බලන්න

External private registries සඳහා:

- imagePullSecret create කරන්න
- Deployment එකට imagePullSecrets add කරන්න

## Gateway route වැඩ කරන්නේ නැහැ

Common symptoms:

- External IP තියෙනවා, හැබැයි app access වෙන්නේ නැහැ
- HTTPRoute traffic route කරන්නේ නැහැ
- Gateway programmed වෙලා නැහැ

Checks:

    kubectl get gateway -n platform-gateway
    kubectl get httproute -A
    kubectl describe httproute <route-name> -n <namespace>
    kubectl get svc -n <app-namespace>
    kubectl get endpoints -n <app-namespace>

Common causes:

- HTTPRoute parentRef වැරදියි
- Service name හෝ port වැරදියි
- App pods Ready නෙවෙයි
- Gateway listener එක route namespace allow කරන්නේ නැහැ

Expected parentRef pattern:

    name: public-gateway
    namespace: platform-gateway

## Grafana හෝ Prometheus access වෙන්නේ නැහැ

Default විදියට Grafana සහ Prometheus ClusterIP services.

මේක intentional.

Safe local access සඳහා port-forward use කරන්න.

Grafana:

    kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80

Prometheus:

    kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090

Authentication, TLS, access controls නැතුව Grafana හෝ Prometheus public expose කරන්න එපා.

## OpenTelemetry Collector telemetry receive කරන්නේ නැහැ

Checks:

    kubectl get pods -n monitoring | grep otel
    kubectl get svc -n monitoring | grep otel
    kubectl logs -n monitoring deploy/otel-collector-opentelemetry-collector

Expected OTLP endpoints inside the cluster:

    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317
    otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318

Common causes:

- App එක wrong endpoint එකට telemetry send කරනවා
- OTLP protocol mismatch
- Collector config issue
- Network policy block කරනවා
