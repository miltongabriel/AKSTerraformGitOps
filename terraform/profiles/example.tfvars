# Used by every step
# subscription_id/tenant_id are NOT set here - they're supplied via
# TF_VAR_subscription_id/TF_VAR_tenant_id (CI: from the AZURE_SUBSCRIPTION_ID/
# AZURE_TENANT_ID secrets already used for azure/login; locally: run.sh
# exports them from `az account show`), so these values never need to sit in
# a tracked file. See README.md's Deployment step 2 warning for why.
location = "LOC"

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
argocd_target_revision  = "main" # this environment's branch - "main" for dev, or a promoted environment's own branch (e.g. "test"/"prod")
# argocd_chart_version not set - defaults to a pinned known-good version
