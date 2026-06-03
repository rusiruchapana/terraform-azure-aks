# Capstone Platform Terraform Environment

This Terraform environment is reserved for the final AKS capstone project.

It provisions one shared AKS platform for the capstone. Inside that cluster, the application is promoted through three Kubernetes namespaces:

- `capstone-dev`
- `capstone-qa`
- `capstone-prod`

This keeps cloud cost lower while still teaching the dev -> qa -> prod GitOps promotion pattern.

In a real enterprise setup, dev, qa, and prod may be separate clusters, subscriptions, or landing zones.

## What this platform is for

The capstone platform is sized to run:

- Argo CD
- Gateway API / NGINX Gateway Fabric
- Prometheus, Grafana, and OpenTelemetry
- dev / qa / prod app namespaces
- a 3-tier capstone app
- optional services such as Redis and RabbitMQ
- AIOps controller and remediation workflow
- load testing jobs

## Cost note

Do not provision this environment until you are ready to start the capstone project.

The capstone profile uses:

- system node pool: `Standard_D2s_v5`, min 1, max 2
- user node pool: `Standard_D2s_v5`, min 2, max 5

If more capacity is needed during load testing, change the user node VM size to `Standard_D4s_v5`.

## How to use

Copy the example tfvars file:

    cp terraform.tfvars.example terraform.tfvars

Edit these values before applying:

    acr_name
    keyvault_name

Then run Terraform:

    terraform init
    terraform plan
    terraform apply

## Important

Do not commit `terraform.tfvars`.

This environment is for the final project only. Destroy it when the capstone work is complete.
