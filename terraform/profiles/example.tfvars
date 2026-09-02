# Used by every step 
subscription_id = "00000000-0000-0000-0000-000000000000"
tenant_id       = "00000000-0000-0000-0000-000000000000"
location        = "LOC"

# Used by every step except bootstrap/01-registry
environment  = "ENV"
project_name = "PROJ_NAME"

# bootstrap/01-registry
registry_resource_group_name = "REGISTRY_RESOURCE_GROUP"
acr_name                     = "ACRNAME"
acr_sku                      = "Basic"

# bootstrap/02-keyvault
argocd_project_ssh_private_key_path = "Wherever/you/keep/your/private/key" #This is the private key that has access to the repo. It should be in a secure location and not committed to source control. Only used by bootstrap/02-keyvault (to seed the Key Vault secret) - terraform/02-argocd reads it back from Key Vault, not from this path.

# bootstrap/90-identities
gh_org                   = "your-github-username@00000000" # login@id format required by the OIDC subject
gh_repo                  = "your-repo-name@00000000"       # repo@id format required by the OIDC subject
gh_registry_environment  = "build-push"                    # must match .github/workflows/build-push-app.yml's environment
gh_environment           = "dev-apply"                     # must match tf-plan-approve-apply.yaml's apply job environment
gh_plan_environment      = "dev-plan"                      # must match tf-plan-approve-apply.yaml's plan job environment
registry_app_name        = "gh-actions-registry-push"
terraform_apply_app_name = "gh-actions-terraform-apply"
terraform_plan_app_name  = "gh-actions-terraform-plan"
operator_aad_object_ids  = ["00000000-0000-0000-0000-000000000000"]

# terraform/01-aks
aks_k8s_version               = "1.35.7"
aks_default_node_pool_vm_size = "Standard_B2pls_v2" #Cheapest found in free tier
# aks_admin_group_object_ids not set - optional break-glass admin list, defaults to []

# terraform/02-argocd
argocd_namespace        = "argocd"
argocd_project_repo_url = "git@github.com:organization/repository.git"
argocd_project_path     = "argocd"
argocd_project_name     = "webapp"
# argocd_chart_version not set - defaults to a pinned known-good version
