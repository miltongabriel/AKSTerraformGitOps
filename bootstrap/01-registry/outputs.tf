output "acr_name" {
  value = azurerm_container_registry.registry.name
}

output "acr_login_server" {
  value = azurerm_container_registry.registry.login_server
}

output "acr_id" {
  value = azurerm_container_registry.registry.id
}

output "resource_group_name" {
  value = azurerm_resource_group.registry.name
}
