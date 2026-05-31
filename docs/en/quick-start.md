# Quick Start

This guide shows how to use this repository to create an AKS DevOps practice platform.

## What this platform creates

The Terraform platform can create:

- Azure Resource Group
- Virtual Network and AKS subnet
- NAT Gateway for outbound traffic
- AKS cluster
- System node pool
- User node pool
- Managed identities
- Optional Azure Container Registry
- Optional Azure Key Vault
- AKS OIDC issuer and Workload Identity
- Optional ACR pull permission

Additional platform add-ons are installed separately:

- Gateway API
- NGINX Gateway Fabric
- Prometheus, Grafana, and Alertmanager
- OpenTelemetry Collector

## Prerequisites

Install these tools before starting:

- Azure CLI
- Terraform
- kubectl
- Helm
- Git

Login to Azure:

    az login
    az account show

Set the correct subscription if needed:

    az account set --subscription "<subscription-id>"

## Clone the repository

    git clone <your-repository-url>
    cd azure_terraform/terraform-azure-aks

## Configure Terraform backend

Go to the dev environment:

    cd environments/dev

Create local backend and variable files from examples:

    cp backend.tf.example backend.tf
    cp terraform.tfvars.example terraform.tfvars

Edit these files for your Azure subscription and naming requirements:

    nano backend.tf
    nano terraform.tfvars

Do not commit these files:

- backend.tf
- terraform.tfvars
- terraform.tfstate
- .terraform/

They are local environment files.

## Initialize Terraform

    terraform init

## Validate the configuration

    terraform fmt -recursive
    terraform validate

Expected result:

    Success! The configuration is valid.

## Review the plan

    terraform plan

Check carefully before applying.

Do not continue if Terraform plans to destroy or replace resources unexpectedly.

## Apply the platform

    terraform apply

Type:

    yes

After completion, Terraform prints outputs such as:

- AKS cluster name
- Resource group name
- ACR name
- Key Vault URI
- NAT Gateway public IP
- OIDC issuer URL

## Connect to AKS

    az aks get-credentials \
      --resource-group <resource-group-name> \
      --name <aks-cluster-name>

Verify nodes:

    kubectl get nodes

Expected:

    STATUS   Ready

## Verify platform add-ons

Gateway API and monitoring add-ons are installed after the Terraform platform.

Check Gateway API:

    kubectl get pods -n nginx-gateway
    kubectl get gatewayclass
    kubectl get gateway -n platform-gateway

Check monitoring:

    kubectl get pods -n monitoring
    kubectl get svc -n monitoring

## Access Grafana locally

Get the Grafana password:

    kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana \
      -o jsonpath="{.data.admin-password}" | base64 -d ; echo

Port-forward Grafana:

    kubectl port-forward svc/kube-prometheus-stack-grafana \
      -n monitoring \
      3000:80

Open:

    http://localhost:3000

Login:

    Username: admin
    Password: <password-from-command>

## Important notes

This platform is designed as a DevOps practice platform.

It does not deploy a specific application automatically.

Users can bring their own applications and practice:

- Docker image build and push
- ACR or Docker Hub deployment
- Gateway API routing
- Key Vault secret access
- CI/CD pipelines
- GitOps workflows
- Monitoring and observability
- dev / qa / prod promotion

## Cleanup

To destroy the Terraform-managed infrastructure:

    terraform destroy

Do not run destroy unless you are sure you want to remove the environment.
