terraform {
  # backend "local" {}
  backend "azurerm" {
    resource_group_name  = "terraform"
    storage_account_name = "devenvironment8861"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
    # subscription_id       = "<your_subscription_id>"   # Your Azure Subscription ID
    # client_id             = "<your_client_id>"         # The App ID of the Service Principal
    # client_secret         = "<your_client_secret>"     # The Password of the Service Principal
    # tenant_id             = "<your_tenant_id>"         # Your Azure Tenant ID
  }

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.33.0"

    }
  }
}
