# Terraform Backend

මෙම document එකෙන් මෙම project එකේ Terraform state handle කරන ආකාරය පැහැදිලි කරනවා.

## Terraform state කියන්නේ මොකක්ද?

Terraform create කරන infrastructure track කරන්නේ state file එකක් භාවිතා කරලා.

State file එක Terraform ට කියනවා:

- මොන resources තියෙනවද
- Resource IDs
- Resources අතර dependencies
- Last apply එකෙන් පස්සේ වෙනස් වුණ දේවල්

Example state file name:

    terraform.tfstate

## Remote state ඕන ඇයි?

Learning වලට Terraform local state use කරන්න පුළුවන්.

Real projects වලට remote state හොඳයි.

Remote state help කරන දේවල්:

- Team collaboration
- State file එක safe තියාගැනීම
- Local machine එකෙන් state නැතිවීම avoid කිරීම
- Centralized state management
- Backend එක අනුව state locking support

මෙම project එක Azure Storage Terraform backend ලෙස use කරනවා.

## Backend type

මෙම project එක AzureRM backend use කරනවා:

    backend "azurerm"

Terraform state Azure Storage Account එකක blob container එකේ store වෙනවා.

## Backend files

Each environment එකේ තියෙනවා:

    backend.tf.example

User copy කරනවා:

    backend.tf

Example:

    cp backend.tf.example backend.tf

Real backend.tf file එක local file එකක්. ඒක commit කරන්න එපා.

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

## Backend values පැහැදිලි කිරීම

resource_group_name:

    Terraform state storage account තියෙන Azure Resource Group එක.

storage_account_name:

    Terraform state සඳහා use කරන Azure Storage Account නම.

container_name:

    State files store කරන blob container නම.

key:

    මේ environment එකේ state file නම.

use_azuread_auth:

    Storage account access keys වෙනුවට Azure AD authentication use කරනවා.

## Recommended state keys

Environment එකකට වෙනම state file එකක් use කරන්න.

Recommended:

    dev.terraform.tfstate
    qa.terraform.tfstate
    prod.terraform.tfstate

මේකෙන් dev, qa, prod එකම state file share නොකරනවා.

## Backend setup process

terraform init run කරන්න කලින් backend storage තියෙන්න ඕන.

Typical process:

1. Backend storage resources create කරන්න
2. backend.tf.example copy කරලා backend.tf හදන්න
3. backend.tf file එකේ storage account details update කරන්න
4. terraform init run කරන්න

Commands:

    cd terraform-azure-aks/environments/dev
    cp backend.tf.example backend.tf
    nano backend.tf
    terraform init

## Required Azure role

Terraform ට blob container access ඕන.

Recommended role:

    Storage Blob Data Contributor

මේ role එක Terraform run කරන user හෝ identity එකට assign වෙන්න ඕන.

## Management plane vs data plane

Azure permissions වල important layers දෙකක් තියෙනවා:

Management plane:

    Azure resources create/manage කිරීම.

Data plane:

    Service එකක් ඇතුළේ data read/write කිරීම.

Terraform state Azure Storage blobs වල තියෙන නිසා Terraform ට blob data-plane access ඕන.

ඒ නිසා Contributor හෝ Owner role එක තිබ්බත් Storage Blob Data Contributor role එක අවශ්‍ය වෙන්න පුළුවන්.

## Common backend errors

Error example:

    AuthorizationPermissionMismatch

Possible reason:

    User ට storage account manage කරන්න පුළුවන්. හැබැයි blobs read/write කරන්න permission නැහැ.

Fix:

    Storage account හෝ container scope එකට Storage Blob Data Contributor assign කරන්න.

## backend.tf commit කරන්න එපා

Commit කරන්න එපා:

    backend.tf

ඇයි?

backend.tf environment-specific backend configuration තියෙන file එකක්.

Different users හෝ environments වෙන storage accounts, containers, state keys use කරන්න පුළුවන්.

Commit කරන්න:

    backend.tf.example

Commit කරන්න එපා:

    backend.tf

## Terraform state commit කරන්න එපා

කවදාවත් commit කරන්න එපා:

    terraform.tfstate
    terraform.tfstate.backup

Terraform state file එකේ sensitive resource information තියෙන්න පුළුවන්.

.gitignore file එකෙන් මේ files ignore වෙන්න ඕන.

## qa සහ prod backend

qa සඳහා:

    key = "qa.terraform.tfstate"

prod සඳහා:

    key = "prod.terraform.tfstate"

Same storage account/container එකක් use කරලා different keys use කරන්න පුළුවන්.

නැත්නම් environment එකකට වෙනම storage account use කරන්නත් පුළුවන්.

Learning සඳහා one storage account + separate keys enough.

Production සඳහා separate backend storage per environment preferred වෙන්න පුළුවන්.

## Recommended backend strategy

මෙම practice platform එක සඳහා:

    dev  -> dev.terraform.tfstate
    qa   -> qa.terraform.tfstate
    prod -> prod.terraform.tfstate

Team හෝ production usage සඳහා:

- Storage account protect කරන්න
- අවශ්‍ය නම් soft delete හෝ versioning enable කරන්න
- RBAC වලින් access restrict කරන්න
- Environment එකකට වෙනම state file use කරන්න
- Local state files share කරන්න එපා
