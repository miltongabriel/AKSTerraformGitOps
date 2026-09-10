data "azurerm_kubernetes_cluster" "aks" {
  name                = data.terraform_remote_state.aks.outputs.cluster_name
  resource_group_name = data.terraform_remote_state.aks.outputs.resource_group_name
}

data "azurerm_key_vault_secret" "argocd_ssh_private_key" {
  name         = "argocd-project-ssh-private-key"
  key_vault_id = data.terraform_remote_state.keyvault.outputs.key_vault_id
}
