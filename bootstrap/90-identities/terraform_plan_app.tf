# App Registration + federated credential (OIDC), used by the "infra_plan"
# job (GitHub Environment var.gh_plan_environment) of the
# tf-plan-approve-apply.yaml workflow. No Contributor/subscription-level
# role - all access is scoped to the terraform/ resource group + the ACR.
#
# Kubernetes-RBAC access against the AKS cluster is "Azure Kubernetes
# Service RBAC Admin", not a narrower custom role: a hand-picked
# data_actions list (namespaces/read, secrets/read,
# "customresources/read") looked read-only and sufficient on paper, but
# "customresources/read" turned out not to actually authorize reads of
# third-party CRD instances (e.g. ArgoCD's AppProject/Application) in
# practice - Azure's AKS-RBAC data actions are a fixed, pre-registered
# list per API group/resource, with no way to reference an arbitrary
# 3rd-party group like argoproj.io, and no working generic fallback
# short of a full dataActions wildcard. "RBAC Admin" has that wildcard
# (dataActions: ["Microsoft.ContainerService/managedClusters/*"]) with
# only namespaces/resourcequotas write+delete excluded - not the
# read-only role this was originally designed to be, but `terraform
# plan` never issues writes regardless of what the identity is allowed
# to do, and Admin is still meaningfully narrower than the "RBAC Cluster
# Admin" tier terraform_apply needs (no namespace/quota admin capability
# at all).

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

resource "azurerm_role_assignment" "terraform_plan_aks_admin" {
  principal_id         = azuread_service_principal.terraform_plan.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Admin"
  scope                = data.azurerm_resource_group.terraform_managed.id
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
