# Stage 01 - Terraform Platform Provisioning

## මේ stage එකේදී මොකක්ද වෙන්නේ?

මෙම stage එකේදී Terraform use කරලා Azure AKS platform foundation එක create කරනවා.

මෙහිදී app එක deploy කරන්නේ නැහැ.

මුලින් platform එක හදනවා.

## මේ stage එකෙන් create වෙන resources

- Resource Group
- VNet
- AKS Subnet
- NAT Gateway
- Public IP
- AKS Managed Identity
- AKS Cluster
- System Node Pool
- User Node Pool
- Azure Container Registry
- Azure Key Vault
- Workload Identity related managed identity
- Federated identity credential
- Role assignments

## ඇයි Terraform use කරන්නේ?

Production වල cloud resources portal එකෙන් click කරලා හදන එක maintain කරන්න අමාරුයි.

Terraform use කළාම:

- infrastructure code එකක් විදිහට තියෙනවා
- review කරන්න පුළුවන්
- repeat කරන්න පුළුවන්
- destroy කරන්න පුළුවන්
- environment එක නැවත හදන්න පුළුවන්

## Platform foundation එකේ meaning එක

මේ stage එකෙන් AKS cluster එකක් විතරක් නෙවෙයි, secure platform foundation එකක් හදනවා.

ACR එක Docker images store කරන්න.

Key Vault එක secrets store කරන්න.

Workload Identity එක pods වලට Azure resources access දෙන්න.

VNet/Subnet/NAT Gateway networking control කරන්න.

AKS cluster එක workloads run කරන්න.

## Region decision

මුලින් eastus use කරන්න try කළා.

නමුත් subscription එකේ eastus region එකේ Standard_D2s_v5 VM size එක allowed නැති නිසා AKS create failed වුණා.

ඒ නිසා project එක Australia East region එකට move කළා.

Final region:

australiaeast

Reason:

- New Zealand ට closer
- Standard_D2s_v5 available
- project resources cleanව fresh provision කරන්න පුළුවන්

## Important issue learned

Cloud project එකක Terraform plan clean වුණත් apply වෙද්දී region/SKU restrictions නිසා fail වෙන්න පුළුවන්.

Correct workflow:

1. Error එක කියවන්න
2. Root cause identify කරන්න
3. Terraform config එක fix කරන්න
4. Partial resources destroy/reuse decision ගන්න
5. Re-plan කරන්න
6. Controlled apply කරන්න

Manual portal changes කරන්න එපා.

## Quota decision

Australia East region එකේ AKS cluster එක create වුණාට පස්සේ user node pool එක මුලින් min 2 ලෙස create කරන්න ගියවිට vCPU quota issue එකක් ආවා.

Learning/free subscription mode නිසා user node pool එක min 1, max 2 ලෙස adjust කළා.

Production ideal:

- user node pool min 2 or more
- high availability සඳහා multiple nodes

Learning mode:

- system node pool min 1
- user node pool min 1
- quota and cost control සඳහා max 2

## Current selected values

Resource group:

rg-aks-capstone-ae-001

Region:

australiaeast

AKS cluster:

aks-capstone-ae-001

VNet:

vnet-aks-capstone-ae-001

Subnet:

snet-aks-capstone-ae-001

Subnet CIDR:

10.50.0.0/23

ACR:

acrakscapstoneae9954

Key Vault:

kv-aks-capstone-ae9954

Node size:

Standard_D2s_v5

System node pool:

min 1, max 2

User node pool:

min 1, max 2

## මේ stage එකෙන් මතක තියාගන්න ඕන දේ

Terraform provisioning කියන්නේ resources create කරන command එකක් විතරක් නෙවෙයි.

මේක production platform එකේ base layer එක.

මෙම base layer එක හරි නැත්නම් පස්සේ GitOps, monitoring, security, AIOps කිසිදෙයක් stable වෙන්නේ නැහැ.
