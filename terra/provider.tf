provider "azurerm" {
  features {
  }
  use_oidc                        = false
  resource_provider_registrations = "none"
  subscription_id                 = "86bdb61f-551b-4581-bd9d-d6d174e744dc"
  environment                     = "public"
  use_msi                         = false
  use_cli                         = true
}
provider "azuread" {}
