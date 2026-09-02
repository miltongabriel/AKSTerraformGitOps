# App Registration + federated credential (OIDC), READ-ONLY, used by the
# "infra_plan" job (GitHub Environment var.gh_plan_environment) of the
# tf-plan-approve-apply.yaml workflow. Read-only permissions on Azure
# Resource Manager only — no Contributor/RBAC Admin.

resource "azurerm_role_definition" "terraform_plan_aks_reader" {
  name        = "AKS RBAC Terraform Plan Reader - ${var.project_name}-${var.environment}"
  scope       = data.azurerm_resource_group.terraform_managed.id
  description = "Read-only AKS RBAC access (Namespace, Secrets, custom resources) scoped to exactly what 'terraform plan' needs against terraform/02-argocd. No write/delete dataActions."

  permissions {
    data_actions = [
      "Microsoft.ContainerService/managedClusters/namespaces/read",
      "Microsoft.ContainerService/managedClusters/secrets/read",
      "Microsoft.ContainerService/managedClusters/customresources/read",
    ]
  }

  assignable_scopes = [
    data.azurerm_resource_group.terraform_managed.id,
  ]
}

resource "azuread_application" "terraform_plan" {
  display_name = var.terraform_plan_app_name
}

resource "azuread_service_principal" "terraform_plan" {
  client_id = azuread_application.terraform_plan.client_id
}

resource "azuread_application_federated_identity_credential" "terraform_plan_env" {
  application_id = azuread_application.terraform_plan.id
  display_name   = "gh-actions-terraform-${var.gh_plan_environment}"
  description    = "GitHub Actions OIDC - terraform plan (read-only), GitHub Environment ${var.gh_plan_environment}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.gh_org}/${var.gh_repo}:environment:${var.gh_plan_environment}"
}

resource "azurerm_role_assignment" "terraform_plan_reader_rg" {
  principal_id         = azuread_service_principal.terraform_plan.object_id
  role_definition_name = "Reader"
  scope                = data.azurerm_resource_group.terraform_managed.id
}

resource "azurerm_role_assignment" "terraform_plan_reader_acr" {
  principal_id         = azuread_service_principal.terraform_plan.object_id
  role_definition_name = "Reader"
  scope                = data.terraform_remote_state.registry.outputs.acr_id
}

resource "azurerm_role_assignment" "terraform_plan_aks_reader" {
  principal_id       = azuread_service_principal.terraform_plan.object_id
  role_definition_id = azurerm_role_definition.terraform_plan_aks_reader.role_definition_resource_id
  scope              = data.azurerm_resource_group.terraform_managed.id
}

# ARM-level (not Kubernetes-RBAC) role: without it, listClusterUserCredential
# is denied and `terraform plan` against 02-argocd can't even fetch a
# kubeconfig to authenticate with - see the comment in operator_access.tf.
resource "azurerm_role_assignment" "terraform_plan_aks_cluster_user" {
  principal_id         = azuread_service_principal.terraform_plan.object_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  scope                = data.azurerm_resource_group.terraform_managed.id
}

data "azurerm_storage_account" "terraform_state" {
  name                = local.terraform_state_storage_account_name
  resource_group_name = data.azurerm_resource_group.terraform_managed.name
}

resource "azurerm_role_assignment" "terraform_plan_blob_reader" {
  principal_id         = azuread_service_principal.terraform_plan.object_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = data.azurerm_storage_account.terraform_state.id
}

resource "azurerm_role_assignment" "terraform_plan_keyvault_secrets_reader" {
  principal_id         = azuread_service_principal.terraform_plan.object_id
  role_definition_name = "Key Vault Secrets User"
  scope                = data.terraform_remote_state.keyvault.outputs.key_vault_id
}
