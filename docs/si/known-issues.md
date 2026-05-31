# Known Issues - දන්නා ගැටළු

මෙම page එකේ known limitations, design notes, provider compatibility notes තියෙනවා.

## System node pool only critical add-ons

Recommended setting:

    system_node_only_critical_addons_enabled = true

ඇයි මේක වැදගත්?

මෙම setting එකෙන් system node pool එක Kubernetes/system workloads සඳහා වෙන් කරලා තියාගන්න පුළුවන්. User applications user node pool එකේ run වෙන්න ඕන.

Known issue:

Existing AKS cluster එකක මෙම setting එක change කරනකොට default node pool rotation අවශ්‍ය වෙන්න පුළුවන්.

ඒ rotation එකට temporary node pool එකක් create වෙන්න පුළුවන්. ඒකට extra regional vCPU quota ඕන.

Quota නැත්නම් Azure මෙහෙම error දෙන්න පුළුවන්:

    ErrCode_InsufficientVCPUQuota

Recommended options:

- New clusters වලට මේ setting එක මුලින්ම enable කරන්න
- Quota increase request කරන්න
- වෙන region එකක් use කරන්න
- Learning environment එකක් නම් cluster recreate කරන්න

## AzureRM provider deprecation warnings

සමහර AzureRM provider versions වල සමහර arguments වලට deprecation warnings එන්න පුළුවන්.

Known example:

    enable_rbac_authorization

Use:

    rbac_authorization_enabled

Federated identity credential සඳහා සමහර provider versions තවම expect කරන්නේ:

    audience
    parent_id

හැබැයි warnings පෙන්වන්න පුළුවන්:

    resource_group_name
    parent_id

මේක provider version එක අනුව වෙනස් වෙන්න පුළුවන්.

Recommendation:

- දැනට වැඩ කරන provider-compatible configuration එක තියාගන්න
- Warning එක docs වල note කරන්න
- Future AzureRM major version upgrade එකකදී block එක update කරන්න

## Key Vault RBAC mode

මෙම project එක use කරන්නේ:

    rbac_authorization_enabled = true

ඒකෙන් Key Vault access policies use වෙන්නේ නැහැ.

Access control වෙන්නේ Azure RBAC roles වලින්.

Important roles:

- Key Vault Secrets Officer: secrets create/update/delete කරන්න
- Key Vault Secrets User: secrets read කරන්න

Subscription Owner හෝ Contributor කියන්නේ automatically secret read/write access තියෙනවා කියන එක නෙවෙයි.

## Terraform backend Azure Storage use කරනවා

Azure Storage වල management-plane permissions සහ data-plane permissions වෙනම තියෙනවා.

Terraform state blob access සඳහා user/identity එකට සාමාන්‍යයෙන් මේ role එක ඕන:

    Storage Blob Data Contributor

Contributor හෝ Storage Account Contributor blob data operations සඳහා enough නැති වෙන්න පුළුවන්.

## ACR optional

මෙම platform එක Azure Container Registry සහ external registries දෙකම support කරනවා.

ACR enable නම්:

    enable_acr = true

Platform එක ACR සහ AKS සඳහා AcrPull permission create කරනවා.

ACR disable නම්:

    enable_acr = false

Docker Hub, GHCR, Quay වගේ public registries තවම use කරන්න පුළුවන්.

Private external registries සඳහා Kubernetes imagePullSecret ඕන.

## Gateway API manual install

Current state:

- Gateway API CRDs manually install කළා
- NGINX Gateway Fabric Helm වලින් manually install කළා
- Shared Gateway manually create කළා

Current learning platform එකට මේක OK.

Future improvement:

Gateway API සහ NGINX Gateway Fabric installation documented add-on manifests හෝ GitOps-managed configuration එකකට move කරන්න.

## Monitoring manual install

Current state:

- kube-prometheus-stack Helm වලින් install කළා
- OpenTelemetry Collector Helm වලින් install කළා
- Values files platform-addons/monitoring යටතේ තියෙනවා

Future improvement:

Monitoring installation GitOps-managed platform add-ons වලට move කරන්න.

## Grafana සහ Prometheus public නැහැ

Grafana සහ Prometheus ClusterIP services ලෙස තියෙනවා.

මේක safety reason එකක් නිසා intentional.

Learning වලට port-forward use කරන්න.

Grafana public expose කරනවා නම් මේවා තියෙන්න ඕන:

- TLS
- Authentication
- Access control
- SSO හෝ OAuth
- Network restrictions

Prometheus සාමාන්‍යයෙන් internal තියාගන්න හොඳයි.

## Local Terraform files commit කරන්නේ නැහැ

පහත files local files:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- terraform.tfstate.backup
- .terraform/

ඒවා commit කරන්න එපා.

Instead example files use කරන්න:

- backend.tf.example
- terraform.tfvars.example
