output "Access_credentials" {
  value = "az aks get-credentials --resource-group rg-${var.project_name}-${var.environment}-${var.location} --name ${azurerm_kubernetes_cluster.aks.name} "
}