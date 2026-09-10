# App Registration + federated credential (OIDC) used by the
# "apply-on-approval" job (GitHub Environment var.gh_environment) of the
# tf-plan-approve-apply.yaml workflow. Least privilege: no subscription-level
# role — all of the app's access is scoped to the terraform/ resource group
# + the ACR.

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

resource "azurerm_role_assignment" "terraform_apply_contributor" {
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_resource_group.terraform_managed.id
}

resource "azurerm_role_assignment" "terraform_apply_aks_admin" {
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = data.azurerm_resource_group.terraform_managed.id
}

# ARM-level (not Kubernetes-RBAC) role: without it, listClusterUserCredential
# is denied and terraform can't even fetch a kubeconfig to authenticate with
# - see the comment in operator_access.tf.
resource "azurerm_role_assignment" "terraform_apply_aks_cluster_user" {
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  scope                = data.azurerm_resource_group.terraform_managed.id
}

data "azurerm_role_definition" "acr_pull" {
  name = "AcrPull"
}

resource "azurerm_role_assignment" "terraform_apply_rbac_admin_acr" {
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Role Based Access Control Administrator"
  scope                = data.terraform_remote_state.registry.outputs.acr_id

  # Only allows creating/removing AcrPull role assignments on this ACR
  # (prevents this "manage RBAC" permission from letting the app
  # self-elevate to another role).
  condition_version = "2.0"
  condition         = <<-EOT
    ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${data.azurerm_role_definition.acr_pull.role_definition_id}}))
    AND
    ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${data.azurerm_role_definition.acr_pull.role_definition_id}}))
  EOT
}

resource "azurerm_role_assignment" "terraform_apply_storage_blob_contributor" {
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = data.azurerm_storage_account.terraform_state.id
}

resource "azurerm_role_assignment" "terraform_apply_keyvault_secrets_reader" {
  principal_id         = azuread_service_principal.terraform_apply.object_id
  role_definition_name = "Key Vault Secrets User"
  scope                = data.terraform_remote_state.keyvault.outputs.key_vault_id
}
