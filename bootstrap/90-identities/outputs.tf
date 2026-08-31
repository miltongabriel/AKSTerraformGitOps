output "registry_app_client_id" {
  value = azuread_application.registry.client_id
}

output "terraform_apply_app_client_id" {
  value = azuread_application.terraform_apply.client_id
}

output "terraform_plan_app_client_id" {
  value = azuread_application.terraform_plan.client_id
}

output "tenant_id" {
  value     = var.tenant_id
  sensitive = true
}

output "subscription_id" {
  value     = var.subscription_id
  sensitive = true
}

output "resource_group_name" {
  value = local.resource_group_name
}

output "github_secrets_setup" {
  description = "Copie estes valores para os GitHub Environments correspondentes"
  value = {
    (var.gh_environment) = {
      AZURE_CLIENT_ID       = azuread_application.terraform_apply.client_id
      AZURE_TENANT_ID       = var.tenant_id
      AZURE_SUBSCRIPTION_ID = var.subscription_id
    }
    (var.gh_plan_environment) = {
      AZURE_CLIENT_ID       = azuread_application.terraform_plan.client_id
      AZURE_TENANT_ID       = var.tenant_id
      AZURE_SUBSCRIPTION_ID = var.subscription_id
    }
  }
  sensitive = true
}
