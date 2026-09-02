# Used by every step
subscription_id = "1bd9c71c-e648-453c-beaf-e5a084a52d50"
tenant_id       = "ffcbd59c-ff21-4edc-b020-3a682dca7757"
location        = "westcentralus"

# Used by every step except bootstrap/01-registry
environment  = "dev"
project_name = "aksgitops"

# bootstrap/01-registry
registry_resource_group_name = "aksterraformgitops" # ACR's resource group - different naming convention than the shared rg-* pattern above
acr_name                     = "gbenettiregistry"
acr_sku                      = "Basic"

# bootstrap/02-keyvault
argocd_project_ssh_private_key_path = "../../argocd-ssh-key"

# bootstrap/90-identities
gh_org                   = "miltongabriel@36887741"
gh_repo                  = "AKSTerraformGitOps@1335275844"
gh_registry_environment  = "build-push"
gh_environment           = "dev-apply"
gh_plan_environment      = "dev-plan"
registry_app_name        = "gh-actions-gbenettiregistry"
terraform_apply_app_name = "gh-actions-terraform-apply-dev"
terraform_plan_app_name  = "gh-actions-terraform-plan-dev"
operator_aad_object_ids  = ["0820b7c1-f351-4b2a-b21d-cd704bd3192d"]

# terraform/01-aks
aks_default_node_pool_vm_size = "Standard_B2pls_v2" # cheapest found in free tier - k8s/deployment.yaml's resource requests/limits are sized to fit it
# aks_k8s_version not set - defaults to a pinned known-good version
# aks_admin_group_object_ids not set - optional break-glass admin list, defaults to []

# terraform/02-argocd
argocd_namespace        = "argocd"
argocd_project_repo_url = "git@github.com:miltongabriel/AKSTerraformGitOps.git"
argocd_project_path     = "k8s"
argocd_project_name     = "webapp"
# argocd_chart_version not set - defaults to a pinned known-good version
