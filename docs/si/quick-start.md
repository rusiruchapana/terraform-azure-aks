# Quick Start - ඉක්මන් ආරම්භය

මෙම guide එකෙන් මෙම repository එක භාවිතා කරලා AKS DevOps practice platform එකක් හදාගන්න ආකාරය පැහැදිලි කරනවා.

## මෙම platform එකෙන් හදන දේවල්

Terraform platform එකෙන් පහත resources හදාගන්න පුළුවන්:

- Azure Resource Group
- Virtual Network සහ AKS subnet
- outbound traffic සඳහා NAT Gateway
- AKS cluster
- System node pool
- User node pool
- Managed identities
- Optional Azure Container Registry
- Optional Azure Key Vault
- AKS OIDC issuer සහ Workload Identity
- Optional ACR pull permission

මේවාට අමතරව platform add-ons වෙනම install කරනවා:

- Gateway API
- NGINX Gateway Fabric
- Prometheus, Grafana, Alertmanager
- OpenTelemetry Collector

## අවශ්‍ය tools

Start කරන්න කලින් මේ tools install කරලා තියෙන්න ඕන:

- Azure CLI
- Terraform
- kubectl
- Helm
- Git

Azure login කරන්න:

    az login
    az account show

අවශ්‍ය නම් correct subscription එක set කරන්න:

    az account set --subscription "<subscription-id>"

## Repository එක clone කරන්න

    git clone <your-repository-url>
    cd azure_terraform/terraform-azure-aks

## Terraform backend configure කරන්න

Dev environment එකට යන්න:

    cd environments/dev

Example files වලින් local backend සහ variable files හදන්න:

    cp backend.tf.example backend.tf
    # Minimal AKS install
    cp terraform.tfvars.minimal.example terraform.tfvars

    # නැත්නම් full learning platform example
    cp terraform.tfvars.example terraform.tfvars

ඔයාගේ Azure subscription එකට සහ naming requirements වලට ගැලපෙන විදියට මේ files edit කරන්න:

    nano backend.tf
    nano terraform.tfvars

මේ files GitHub එකට commit කරන්න එපා:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- .terraform/

මේවා local environment files.

## Terraform initialize කරන්න

    terraform init

## Configuration validate කරන්න

    terraform fmt -recursive
    terraform validate

Expected result:

    Success! The configuration is valid.

## Terraform plan බලන්න

    terraform plan

Apply කරන්න කලින් plan එක හොඳට බලන්න.

Terraform unexpected destroy/replace resources පෙන්වනවා නම් continue කරන්න එපා.

## Platform එක apply කරන්න

    terraform apply

Prompt එක ආවම type කරන්න:

    yes

Apply complete උනාම Terraform outputs වල මේවා වගේ values ලැබෙනවා:

- AKS cluster name
- Resource group name
- ACR name
- Key Vault URI
- NAT Gateway public IP
- OIDC issuer URL

## AKS cluster එකට connect වෙන්න

    az aks get-credentials \
      --resource-group <resource-group-name> \
      --name <aks-cluster-name>

Nodes verify කරන්න:

    kubectl get nodes

Expected:

    STATUS   Ready

## Platform add-ons verify කරන්න

Terraform platform එකට පස්සේ Gateway API සහ monitoring add-ons install කරනවා.

Gateway API check කරන්න:

    kubectl get pods -n nginx-gateway
    kubectl get gatewayclass
    kubectl get gateway -n platform-gateway

Monitoring check කරන්න:

    kubectl get pods -n monitoring
    kubectl get svc -n monitoring

## Grafana local access

Grafana password එක ගන්න:

    kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana \
      -o jsonpath="{.data.admin-password}" | base64 -d ; echo

Grafana port-forward කරන්න:

    kubectl port-forward svc/kube-prometheus-stack-grafana \
      -n monitoring \
      3000:80

Browser එකෙන් open කරන්න:

    http://localhost:3000

Login:

    Username: admin
    Password: <command එකෙන් ලැබුණු password එක>

## වැදගත් notes

මෙම platform එක DevOps practice platform එකක්.

Specific application එකක් automatically deploy කරන්නේ නැහැ.

Usersලාට තමන්ගේම apps අරගෙන මේවා practice කරන්න පුළුවන්:

- Docker image build සහ push
- ACR හෝ Docker Hub deployment
- Gateway API routing
- Key Vault secret access
- CI/CD pipelines
- GitOps workflows
- Monitoring සහ observability
- dev / qa / prod promotion

## Cleanup

Terraform-managed infrastructure destroy කරන්න:

    terraform destroy

Environment එක remove කරන්න අවශ්‍ය බව sure නැත්නම් `terraform destroy` run කරන්න එපා.
