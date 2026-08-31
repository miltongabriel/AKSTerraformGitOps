# Traduzido de setup_appRegistration.sh
#
# App Registration + federated credential (OIDC) usado pelo workflow
# build-push-app.yml para dar push da imagem no ACR. Unica permissao: AcrPush,
# escopada ao proprio ACR.

resource "azuread_application" "registry" {
  display_name = var.registry_app_name
}

resource "azuread_service_principal" "registry" {
  client_id = azuread_application.registry.client_id
}

resource "azuread_application_federated_identity_credential" "registry_branch" {
  application_id = azuread_application.registry.id
  # Nome fixo (nao interpolado a partir de var.gh_repo): o recurso ja existe
  # no Azure com este display_name exato ("gh-actions-AKSTerraformGitOps-main",
  # sem o sufixo "@<id>" que var.gh_repo tem hoje). Usar a interpolacao aqui
  # geraria um diff de "forces replacement" no import, destruindo e recriando
  # o federated credential.
  display_name = "gh-actions-AKSTerraformGitOps-main"
  audiences    = ["api://AzureADTokenExchange"]
  issuer       = "https://token.actions.githubusercontent.com"
  subject      = "repo:${var.gh_org}/${var.gh_repo}:environment:${var.gh_registry_environment}"
}

data "azurerm_container_registry" "registry" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

resource "azurerm_role_assignment" "registry_acr_push" {
  principal_id         = azuread_service_principal.registry.object_id
  role_definition_name = "AcrPush"
  scope                = data.azurerm_container_registry.registry.id
  # skip_service_principal_aad_check e um flag so de create (nao existe na API
  # do Azure, nao e lido de volta). Como este role assignment ja existe e foi
  # importado, definir esse campo aqui so gera um diff que o provider nao
  # sabe aplicar via update ("doesn't support update") — deixamos de fora.
}
