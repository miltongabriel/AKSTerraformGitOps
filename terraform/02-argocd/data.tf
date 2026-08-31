data "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.project_name}-${var.environment}-${var.location}"
  resource_group_name = "rg-${var.project_name}-${var.environment}-${var.location}"
}

data "azurerm_key_vault" "vault" {
  name                = "kv-${var.project_name}-${var.environment}"
  resource_group_name = "rg-${var.project_name}-${var.environment}-${var.location}"
}

data "azurerm_key_vault_secret" "argocd_ssh_private_key" {
  name         = "argocd-project-ssh-private-key"
  key_vault_id = data.azurerm_key_vault.vault.id
}
