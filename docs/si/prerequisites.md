# අවශ්‍ය දේවල්

මෙම page එකෙන් AKS DevOps Practice Platform එක use කරන්න කලින් අවශ්‍ය tools, Azure permissions, සහ preparation පැහැදිලි කරනවා.

## අවශ්‍ය tools

Local machine එකේ මේ tools install කරලා තියෙන්න ඕන:

- Git
- Azure CLI
- Terraform
- kubectl
- Helm

## Recommended tool versions

Recent stable versions use කරන්න.

Installed versions check කරන්න:

    git --version
    az version
    terraform version
    kubectl version --client
    helm version

## Azure CLI login

Azure login කරන්න:

    az login

Active account සහ subscription check කරන්න:

    az account show

අවශ්‍ය නම් correct subscription එක set කරන්න:

    az account set --subscription "<subscription-id>"

## Azure subscription

ඔයාට Azure subscription එකක resources create කරන්න permission තියෙන්න ඕන.

Create කරන resources වගේ දේවල්:

- Resource groups
- Virtual networks
- Public IP addresses
- NAT Gateways
- AKS clusters
- Managed identities
- Role assignments
- Azure Container Registry
- Azure Key Vault
- Terraform state සඳහා Storage account

## Azure permissions

Terraform run කරන user හෝ identity එකට Azure resources create/manage කරන්න permission ඕන.

Learning environment එකකට Subscription Owner role එක simple option එකක්.

හැබැයි සමහර services වලට data-plane permissions වෙනම ඕන.

## Terraform backend permissions

Terraform remote state Azure Storage එකේ store කරනවා.

Blob state access සඳහා Terraform run කරන user හෝ identity එකට මේ role එක ඕන:

    Storage Blob Data Contributor

මේක normal Azure resource management permission එකෙන් වෙනස්.

## Key Vault permissions

මෙම project එක Key Vault RBAC mode use කරනවා.

Secrets create/update කරන්න human/operator account එකට ඕන:

    Key Vault Secrets Officer

Application එකට secrets read කරන්න workload identity එකට ඕන:

    Key Vault Secrets User

Important:

Subscription Owner හෝ Contributor කියන්නේ automatically Key Vault secret read/write access තියෙනවා කියන එක නෙවෙයි.

## AKS quota requirements

AKS node pools සඳහා regional vCPU quota ඕන.

Terraform apply කරන්න කලින් selected Azure region එකේ vCPU quota enough ද බලන්න.

Quota වැදගත් වෙන්නේ:

- AKS node pools create කරනකොට
- Node pools scale කරනකොට
- System node pool rotation කරනකොට
- Updates වලදී temporary node pools use කරනකොට

Quota අඩු නම් Azure මෙහෙම error දෙන්න පුළුවන්:

    ErrCode_InsufficientVCPUQuota

Fix options:

- Quota increase request කරන්න
- වෙන Azure region එකක් use කරන්න
- Smaller VM sizes use කරන්න
- Node count අඩු කරන්න

## VM SKU availability

හැම VM size එකම හැම Azure region එකකම හෝ subscription එකකම available නැහැ.

VM size එක available නැත්නම් වෙන size එකක් choose කරන්න.

මෙම project එකේ low-cost example එකක්:

    Standard_B2s_v2

## Naming requirements

සමහර Azure resource names globally unique වෙන්න ඕන.

Examples:

- Azure Container Registry name
- Azure Key Vault name
- Storage account name

terraform.tfvars file එකේ ඔයාගේම unique names use කරන්න.

## Local files

Example files වලින් local files create කරනවා:

    backend.tf.example       -> backend.tf
    terraform.tfvars.example -> terraform.tfvars

Real local files commit කරන්න එපා:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- terraform.tfstate.backup
- .terraform/

## Kubernetes access

AKS cluster එක create උනාට පස්සේ kubectl configure කරන්න:

    az aks get-credentials \
      --resource-group <resource-group-name> \
      --name <aks-cluster-name>

Verify කරන්න:

    kubectl get nodes

## Helm access

Helm use කරන්නේ platform add-ons install කරන්න.

Examples:

- NGINX Gateway Fabric
- kube-prometheus-stack
- OpenTelemetry Collector

Helm check කරන්න:

    helm version

## Recommended starting environment

First-time usersලාට recommend කරන්නේ:

    environments/dev

dev setup එක හොඳට තේරෙනකම් qa හෝ prod apply කරන්න එපා.

## Cost warning

AKS, NAT Gateway, public IPs, ACR, Key Vault, සහ monitoring components Azure cost create කරන්න පුළුවන්.

Learning සඳහා:

- Small VM sizes use කරන්න
- Low node counts use කරන්න
- අවශ්‍ය නැති වෙලාවට environment destroy කරන්න
- Azure costs regularly review කරන්න

## Continue කරන්න කලින්

terraform apply run කරන්න කලින් check කරන්න:

- Correct Azure subscription එකට login වෙලාද
- Terraform backend storage තියෙනවද
- Terraform state සඳහා Storage Blob Data Contributor තියෙනවද
- terraform.tfvars වල unique resource names තියෙනවද
- Region එක selected VM sizes support කරනවද
- Subscription එකේ enough vCPU quota තියෙනවද
