resource "azurerm_resource_group" "registry" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "registry" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.registry.name
  location            = azurerm_resource_group.registry.location
  sku                 = var.acr_sku
  admin_enabled       = false
}
