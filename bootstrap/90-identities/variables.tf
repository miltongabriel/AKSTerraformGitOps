variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
  sensitive   = true
}

variable "gh_org" {
  description = "GitHub organization/user in the format required by the OIDC subject (login@id)."
  type        = string
}

variable "gh_repo" {
  description = "GitHub repository in the format required by the OIDC subject (repo@id)."
  type        = string
}

variable "project_name" {
  description = "Name prefix applied to resource names - shared across every bootstrap/terraform step; must match terraform/profiles/dev.tfvars."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. \"dev\") - shared across every bootstrap/terraform step; must match terraform/profiles/dev.tfvars."
  type        = string
}

variable "location" {
  description = "Azure region for the resources - shared across every bootstrap/terraform step; must match terraform/profiles/dev.tfvars."
  type        = string
}

# -- App 1: registry ---------------------------------------------------------

variable "registry_app_name" {
  description = "Name of the App Registration used by the build-push-app.yml workflow."
  type        = string
}

variable "gh_registry_environment" {
  description = "GitHub Environment used by the build/push job (build-push-app.yml)."
  type        = string
}

# -- App 2: terraform apply --------------------------------------------------

variable "terraform_apply_app_name" {
  description = "Name of the App Registration with write permission (apply-on-approval job)."
  type        = string
}

variable "gh_environment" {
  description = "GitHub Environment used by the apply job (tf-plan-approve-apply.yaml)."
  type        = string
}

# -- App 3: terraform plan / read-only ---------------------------------------

variable "terraform_plan_app_name" {
  description = "Name of the read-only App Registration (infra_plan job)."
  type        = string
}

variable "gh_plan_environment" {
  description = "GitHub Environment used by the plan job (must differ from gh_environment so the two apps get separate secrets)."
  type        = string
}

# -- Human/operator access to AKS via Azure RBAC (see operator_access.tf) ---

variable "operator_aad_object_ids" {
  description = "Azure AD object IDs (users or groups) granted 'Azure Kubernetes Service RBAC Cluster Admin' on the cluster - needed because terraform/01-aks runs with local_account_disabled = true. See operator_access.tf."
  type        = list(string)
}
