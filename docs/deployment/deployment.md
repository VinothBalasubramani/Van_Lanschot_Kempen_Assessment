# STRADA IaC Deployment with Terraform + Azure DevOps

## Prerequisites
1. Azure DevOps project created.
2. Service connection to Azure (`azurerm` type).
3. Azure Storage Account + Container for Terraform remote state.
4. Azure Key Vault containing secrets (SP credentials, SQL passwords).

## Setup
1. Clone this repo and unzip `iac-azure-strada-starter-v3-final.zip`.
2. Place the provided `azure-pipelines.yml` in the repo root.
3. Configure pipeline variables:
   - `TF_STATE_STORAGE`
   - `TF_STATE_RG`
   - `AZ_SUBSCRIPTION`
   - `environment` (dev / tst / prd)

## Deployment
1. Commit & push changes.
2. Azure DevOps will trigger pipeline on `main`.
3. Review `Terraform Plan` stage output.
4. Approve manual intervention (if required).
5. `Terraform Apply` will provision resources:
   - Databricks
   - Storage Account
   - Data Factory
   - SQL Server
   - Key Vault
   - Unity Catalog + RBAC setup

## Multi-Environment
- Configurable via `environments/dev.tfvars`, `tst.tfvars`, `prd.tfvars`.
- Pipeline uses `-var-file="environments/$(environment).tfvars"`.