
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">=3.80.0" }
    databricks = { source = "databricks/databricks", version = ">=1.27.0" }
    random = { source = "hashicorp/random", version = ">=3.6.0" }
  }
  backend "azurerm" {}
}

provider "azurerm" { features {} }
provider "databricks" {}
