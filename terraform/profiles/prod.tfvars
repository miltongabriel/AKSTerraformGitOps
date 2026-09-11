# Used by every step
# subscription_id/tenant_id are NOT set here - they're supplied via
# TF_VAR_subscription_id/TF_VAR_tenant_id (CI: from the AZURE_SUBSCRIPTION_ID/
# AZURE_TENANT_ID secrets already used for azure/login; locally: run.sh
# exports them from `az account show`), so these values never need to sit in
# a tracked file. See README.md's Deployment step 2 warning for why.
location = "westcentralus"

# Used by every step except bootstrap/01-registry
environment  = "prod"
project_name = "aksgitops"

# bootstrap/01-registry - shared across every environment, same ACR as dev
registry_resource_group_name = "aksterraformgitops" # ACR's resource group - different naming convention than the shared rg-* pattern above
acr_name                     = "gbenettiregistry"
acr_sku                      = "Basic"

# bootstrap/02-keyvault
argocd_project_ssh_private_key_path = "../../argocd-ssh-key"

# bootstrap/90-identities
gh_org                   = "miltongabriel@36887741"
gh_repo                  = "AKSTerraformGitOps@1335275844"
gh_registry_environment  = "build-push"
gh_environment           = "prod-apply"
gh_plan_environment      = "prod-plan"
registry_app_name        = "gh-actions-gbenettiregistry"
terraform_apply_app_name = "gh-actions-terraform-apply-prod"
terraform_plan_app_name  = "gh-actions-terraform-plan-prod"
operator_aad_object_ids  = ["74a8e0a7-e567-40b2-bae2-9bad642770fd"]

# terraform/01-aks
aks_default_node_pool_vm_size = "Standard_B2pls_v2" # same cheap free-tier size as dev - bump this before running any real production workload
# aks_k8s_version not set - defaults to a pinned known-good version
# aks_admin_group_object_ids not set - optional break-glass admin list, defaults to []

# terraform/02-argocd
argocd_namespace        = "argocd"
argocd_project_repo_url = "git@github.com:miltongabriel/AKSTerraformGitOps.git"
argocd_project_path     = "k8s"
argocd_project_name     = "webapp"
argocd_target_revision  = "prod" # this environment's branch - promoted from test via promote.yml
# argocd_chart_version not set - defaults to a pinned known-good version
