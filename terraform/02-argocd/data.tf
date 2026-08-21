data "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.project_name}-${var.environment}-${var.location}"
  resource_group_name = "rg-${var.project_name}-${var.environment}-${var.location}"
}
