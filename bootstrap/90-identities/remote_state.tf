data "terraform_remote_state" "registry" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.resource_group_name
    storage_account_name = local.terraform_state_storage_account_name
    container_name       = local.terraform_state_container_name
    key                  = "bootstrap/registry.tfstate"
    subscription_id      = var.subscription_id
  }
}

data "terraform_remote_state" "keyvault" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.resource_group_name
    storage_account_name = local.terraform_state_storage_account_name
    container_name       = local.terraform_state_container_name
    key                  = "bootstrap/keyvault.tfstate"
    subscription_id      = var.subscription_id
  }
}
