data "terraform_remote_state" "registry" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.tfstate_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = "bootstrap/registry.tfstate"
    subscription_id      = var.subscription_id
    use_azuread_auth     = true
  }
}
