# Both roles are needed, not redundant: 
#    Cluster User Role is what lets `az aks get-credentials` fetch the kubeconfig at all.
#    RBAC Cluster Admin governs what's authorized once connected.

resource "azurerm_role_assignment" "operator_aks_rbac_cluster_admin" {
  for_each             = toset(var.operator_aad_object_ids)
  principal_id         = each.value
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = data.azurerm_resource_group.terraform_managed.id
}

resource "azurerm_role_assignment" "operator_aks_cluster_user" {
  for_each             = toset(var.operator_aad_object_ids)
  principal_id         = each.value
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  scope                = data.azurerm_resource_group.terraform_managed.id
}
