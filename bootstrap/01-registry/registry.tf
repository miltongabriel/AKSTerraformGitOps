# Traduzido de setup_registry.sh
#
# Resource Group + Container Registry usados pelo workflow build-push-app.yml
# (via o app de registry criado em bootstrap/02-identities) e, futuramente,
# pelo AKS para dar pull das imagens.

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
