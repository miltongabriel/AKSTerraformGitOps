output "storage_container" {
  value = "https://${azurerm_storage_account.terraform_state.name}.blob.core.windows.net/${azurerm_storage_container.terraform_state.name}/"
}

output "storage_account" {
  value = azurerm_storage_account.terraform_state.name
}

output "resource_group" {
  value = azurerm_resource_group.resource_group.name
}

output "container_name" {
  value = azurerm_storage_container.terraform_state.name
}
