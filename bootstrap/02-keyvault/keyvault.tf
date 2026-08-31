# Key Vault + segredo da chave privada SSH do ArgoCD.
#
# O resource group ja existe de verdade (criado e gerenciado pelo state de
# bootstrap/00-backend), entao aqui so LEMOS ele via data source para pegar
# o ID/location — nao o recriamos/possuimos neste modulo.

data "azurerm_resource_group" "terraform_managed" {
  name = "rg-${var.project_name}-${var.environment}-${var.location}"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                = "kv-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.terraform_managed.location
  resource_group_name = data.azurerm_resource_group.terraform_managed.name
  tenant_id           = var.tenant_id
  sku_name            = "premium"

  rbac_authorization_enabled = true

  purge_protection_enabled = false
}

resource "azurerm_role_assignment" "operator_secrets_officer" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Secrets Officer"
  scope                = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "argocd_ssh_private_key" {
  name         = "argocd-project-ssh-private-key"
  value        = file(var.argocd_project_ssh_private_key_path)
  key_vault_id = azurerm_key_vault.vault.id

  depends_on = [azurerm_role_assignment.operator_secrets_officer]
}
