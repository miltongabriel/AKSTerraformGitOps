# Traduzido de setup_appRegistrationTerraformPlan.sh
#
# App Registration + federated credential (OIDC) READ-ONLY, usado pelo job
# "infra_plan" (GitHub Environment var.gh_plan_environment) do workflow
# tf-plan-approve-apply.yaml. So permissoes de leitura no Azure Resource
# Manager — nenhum Contributor/RBAC Admin.
#
# Duas ressalvas herdadas do script original (ver comentarios la):
# 1) O backend "azurerm" so consegue ler o tfstate sem a account key
#    (listkeys e uma acao de escrita, que "Reader" nao tem) se o
#    "terraform init" do job infra_plan usar
#    -backend-config="use_azuread_auth=true". Sem isso, o init falha com este
#    app.
# 2) Este AKS usa contas locais (sem Azure RBAC habilitado). Nesse modo,
#    "Cluster User" e "Cluster Admin" retornam o MESMO kube_config — ou seja,
#    o bloqueio de escrita so e garantido no nivel do Azure Resource Manager
#    (terraform/01-aks), nao no nivel do Kubernetes em si (terraform/02-argocd).
#    Para fechar essa lacuna seria preciso habilitar Azure RBAC no AKS e usar o
#    role "Azure Kubernetes Service RBAC Reader".

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
  scope                = data.azurerm_container_registry.acr.id
}

resource "azurerm_role_assignment" "terraform_plan_aks_user" {
  principal_id         = azuread_service_principal.terraform_plan.object_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  scope                = data.azurerm_resource_group.terraform_managed.id
}

# A storage account do tfstate só existe depois que bootstrap/00-backend for
# aplicado (com o app de apply). Por isso esta role assignment fica atrás de
# uma flag: rode este modulo uma primeira vez com
# terraform_state_storage_account_exists = false (cria os apps + os 3 roles
# acima), depois aplique o bootstrap/00-backend, e so entao rode este modulo
# de novo com a flag em true para liberar a leitura do state.
data "azurerm_storage_account" "terraform_state" {
  count               = var.terraform_state_storage_account_exists ? 1 : 0
  name                = local.terraform_state_storage_account_name
  resource_group_name = data.azurerm_resource_group.terraform_managed.name
}

resource "azurerm_role_assignment" "terraform_plan_blob_reader" {
  count                = var.terraform_state_storage_account_exists ? 1 : 0
  principal_id         = azuread_service_principal.terraform_plan.object_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = data.azurerm_storage_account.terraform_state[0].id
}

# terraform plan (job infra_plan, read-only) tambem precisa ler o segredo da
# chave SSH do ArgoCD para "terraform plan" no modulo terraform/02-argocd nao
# falhar. data source "azurerm_key_vault.vault" definida em
# terraform_apply_app.tf, reaproveitada aqui.
resource "azurerm_role_assignment" "terraform_plan_keyvault_secrets_reader" {
  principal_id         = azuread_service_principal.terraform_plan.object_id
  role_definition_name = "Key Vault Secrets User"
  scope                = data.azurerm_key_vault.vault.id
}
