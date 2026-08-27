data "azurerm_container_registry" "acr" {
  name                = "gbenettiregistry"
  resource_group_name = "aksterraformgitops"
}
