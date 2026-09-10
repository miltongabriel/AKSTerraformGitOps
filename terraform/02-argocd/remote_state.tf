data "terraform_remote_state" "aks" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.tfstate_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = "terraform/aks.tfstate"
    subscription_id      = var.subscription_id
  }
}

data "terraform_remote_state" "keyvault" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.tfstate_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = "bootstrap/keyvault.tfstate"
    subscription_id      = var.subscription_id
  }
}
