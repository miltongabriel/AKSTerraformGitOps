# Traduzido de setup_appRegistrationTerraform.sh
#
# App Registration + federated credential (OIDC) usado pelo job
# "apply-on-approval" (GitHub Environment var.gh_environment) do workflow
# tf-plan-approve-apply.yaml. Least privilege: nenhuma role na subscription —
# todo o acesso do app fica escopado ao resource group do terraform/ + ao ACR.
#
# O resource group ja existe de verdade (criado e gerenciado pelo state de
# bootstrap/00-backend — terraform/01-aks so referencia o nome, nao o
# possui), entao aqui so LEMOS ele via data source para pegar o ID — nao o
# recriamos/possuimos neste modulo. Se algum dia voce partir de um ambiente
# novo do zero, o bootstrap/00-backend precisa rodar antes deste modulo, ja
# que a data source abaixo falha se o RG nao existir ainda.

resource "azuread_application" "terraform_apply" {
  display_name = var.terraform_apply_app_name
}

resource "azuread_service_principal" "terraform_apply" {
  client_id = azuread_application.terraform_apply.client_id
}

resource "azuread_application_federated_identity_credential" "terraform_apply_env" {
  application_id = azuread_application.terraform_apply.id
  display_name   = "gh-actions-terraform-${var.gh_environment}"
  description    = "GitHub Actions OIDC - terraform apply, GitHub Environment ${var.gh_environment}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.gh_org}/${var.gh_repo}:environment:${var.gh_environment}"
}

data "azurerm_resource_group" "terraform_managed" {
  name = local.resource_group_name
}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

resource "azurerm_role_assignment" "terraform_apply_contributor" {
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_resource_group.terraform_managed.id
}

resource "azurerm_role_assignment" "terraform_apply_aks_admin" {
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  scope                = data.azurerm_resource_group.terraform_managed.id
}

data "azurerm_role_definition" "acr_pull" {
  name = "AcrPull"
}

resource "azurerm_role_assignment" "terraform_apply_rbac_admin_acr" {
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Role Based Access Control Administrator"
  scope                = data.azurerm_container_registry.acr.id

  # So permite criar/remover atribuicoes do role AcrPull nesse ACR (evita que
  # esta permissao de "gerenciar RBAC" sirva para o app se auto-elevar a outro
  # role).
  condition_version = "2.0"
  condition         = <<-EOT
    ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${data.azurerm_role_definition.acr_pull.role_definition_id}}))
    AND
    ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${data.azurerm_role_definition.acr_pull.role_definition_id}}))
  EOT
}

# O provider azurerm (v4+) passou a gerenciar recursos de dados de storage
# (azurerm_storage_container, usado em bootstrap/00-backend) via Azure AD por
# padrao, em vez de buscar a account key. "Contributor" so da acesso de
# controle (ARM) na conta de storage — sem esta role de dados, o apply falha
# com 403 AuthorizationPermissionMismatch ao criar/gerenciar o container.
# (data source "azurerm_storage_account.terraform_state" definida em
# terraform_plan_app.tf, reaproveitada aqui.)
resource "azurerm_role_assignment" "terraform_apply_storage_blob_contributor" {
  count                = var.terraform_state_storage_account_exists ? 1 : 0
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = data.azurerm_storage_account.terraform_state[0].id
}
