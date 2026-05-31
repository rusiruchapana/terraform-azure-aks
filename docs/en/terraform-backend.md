# Terraform Backend

This document explains how Terraform state is handled in this project.

## What is Terraform state?

Terraform keeps track of created infrastructure using a state file.

The state file tells Terraform:

- What resources exist
- Resource IDs
- Dependencies between resources
- What changed since the last apply

Example state file name:

    terraform.tfstate

## Why remote state?

For learning, Terraform can use local state.

For real projects, remote state is better.

Remote state helps with:

- Team collaboration
- Safer state storage
- Avoiding local state loss
- Centralized state management
- State locking support depending on backend

This project uses Azure Storage as the Terraform backend.

## Backend type

This project uses the AzureRM backend:

    backend "azurerm"

Terraform state is stored in an Azure Storage Account blob container.

## Backend files in this project

Each environment has:

    backend.tf.example

Users copy it to:

    backend.tf

Example:

    cp backend.tf.example backend.tf

The real backend.tf file is local and should not be committed.

## Example backend configuration

Example:

    terraform {
      backend "azurerm" {
        resource_group_name  = "replace-with-tfstate-resource-group"
        storage_account_name = "replacewithuniquetfstate"
        container_name       = "tfstate"
        key                  = "dev.terraform.tfstate"
        use_azuread_auth     = true
      }
    }

## Backend values explained

resource_group_name:

    The Azure Resource Group that contains the Terraform state storage account.

storage_account_name:

    The Azure Storage Account name used for Terraform state.

container_name:

    The blob container where state files are stored.

key:

    The state file name for this environment.

use_azuread_auth:

    Uses Azure AD authentication instead of storage account access keys.

## Recommended state keys

Use a separate state file per environment.

Recommended:

    dev.terraform.tfstate
    qa.terraform.tfstate
    prod.terraform.tfstate

This prevents dev, qa, and prod from sharing the same state file.

## Backend setup process

Before running terraform init, make sure the backend storage exists.

Typical process:

1. Create backend storage resources
2. Copy backend.tf.example to backend.tf
3. Update backend.tf with your storage account details
4. Run terraform init

Commands:

    cd terraform-azure-aks/environments/dev
    cp backend.tf.example backend.tf
    nano backend.tf
    terraform init

## Required Azure role

Terraform needs access to the blob container.

Recommended role:

    Storage Blob Data Contributor

This role should be assigned to the user or identity running Terraform.

## Management plane vs data plane

Azure permissions have two important layers:

Management plane:

    Create or manage Azure resources.

Data plane:

    Read or write data inside a service.

For Terraform state stored in Azure Storage, Terraform needs data-plane access to blobs.

That is why Storage Blob Data Contributor may be required even if you already have Contributor or Owner permissions.

## Common backend errors

Error example:

    AuthorizationPermissionMismatch

Possible reason:

    The user can manage the storage account, but cannot read or write blobs.

Fix:

    Assign Storage Blob Data Contributor on the storage account or container.

## Do not commit backend.tf

Do not commit:

    backend.tf

Why?

backend.tf contains environment-specific backend configuration.

Different users or environments may use different storage accounts, containers, or state keys.

Commit:

    backend.tf.example

Do not commit:

    backend.tf

## Do not commit Terraform state

Never commit:

    terraform.tfstate
    terraform.tfstate.backup

Terraform state may contain sensitive resource information.

The .gitignore file should ignore these files.

## Backend for qa and prod

For qa:

    key = "qa.terraform.tfstate"

For prod:

    key = "prod.terraform.tfstate"

You can use the same storage account and container with different keys, or separate storage accounts per environment.

For learning, one storage account with separate keys is usually enough.

For production, separate backend storage per environment may be preferred.

## Recommended backend strategy

For this practice platform:

    dev  -> dev.terraform.tfstate
    qa   -> qa.terraform.tfstate
    prod -> prod.terraform.tfstate

For team or production usage:

- Protect the storage account
- Enable soft delete or versioning where appropriate
- Restrict access with RBAC
- Use separate state files per environment
- Avoid sharing local state files
