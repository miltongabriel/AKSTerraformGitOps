# App Registration + federated credential (OIDC) used by the
# build-push-app.yml workflow to push the image to ACR. Single permission:
# AcrPush, scoped to the ACR itself.

resource "azuread_application" "registry" {
  display_name = var.registry_app_name
}

resource "azuread_service_principal" "registry" {
  client_id = azuread_application.registry.client_id
}

resource "azuread_application_federated_identity_credential" "registry_branch" {
  application_id = azuread_application.registry.id
  display_name   = "gh-actions-AKSTerraformGitOps-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.gh_org}/${var.gh_repo}:environment:${var.gh_registry_environment}"
}

resource "azurerm_role_assignment" "registry_acr_push" {
  principal_id         = azuread_service_principal.registry.object_id
  role_definition_name = "AcrPush"
  scope                = data.terraform_remote_state.registry.outputs.acr_id
}
