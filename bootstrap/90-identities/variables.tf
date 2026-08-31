variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  sensitive   = true
}

variable "gh_org" {
  description = "Organizacao/usuario do GitHub no formato exigido pelo subject OIDC (login@id)"
  type        = string
  default     = "miltongabriel@36887741"
}

variable "gh_repo" {
  description = "Repositorio do GitHub no formato exigido pelo subject OIDC (repo@id)"
  type        = string
  default     = "AKSTerraformGitOps@1335275844"
}

# Precisam bater com terraform/profiles/dev.tfvars
variable "project_name" {
  description = "Prefixo usado nos recursos de bootstrap/00-backend e terraform/ (01-aks/02-argocd)"
  type        = string
  default     = "aksgitops"
}

variable "environment" {
  description = "Ambiente gerenciado por bootstrap/00-backend e terraform/ (01-aks/02-argocd)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Regiao dos recursos gerenciados pelo terraform/"
  type        = string
  default     = "westcentralus"
}

variable "acr_name" {
  description = "Nome do ACR existente (criado por bootstrap/01-registry)"
  type        = string
  default     = "gbenettiregistry"
}

variable "acr_resource_group_name" {
  description = "Resource group do ACR existente (criado por bootstrap/01-registry)"
  type        = string
  default     = "aksterraformgitops"
}

# -- App 1: registry (setup_appRegistration.sh) -----------------------------

variable "registry_app_name" {
  description = "Nome do App Registration usado pelo workflow build-push-app.yml"
  type        = string
  default     = "gh-actions-gbenettiregistry"
}

variable "gh_registry_environment" {
  description = "GitHub Environment usado pelo job de build/push (build-push-app.yml)"
  type        = string
  default     = "build-push"
}

# -- App 2: terraform apply (setup_appRegistrationTerraform.sh) -------------

variable "terraform_apply_app_name" {
  description = "Nome do App Registration com permissao de escrita (job apply-on-approval)"
  type        = string
  default     = "gh-actions-terraform-apply-dev"
}

variable "gh_environment" {
  description = "GitHub Environment usado pelo job de apply (tf-plan-approve-apply.yaml)"
  type        = string
  default     = "dev-apply"
}

# -- App 3: terraform plan / read-only (setup_appRegistrationTerraformPlan.sh)

variable "terraform_plan_app_name" {
  description = "Nome do App Registration read-only (job infra_plan)"
  type        = string
  default     = "gh-actions-terraform-plan-dev"
}

variable "gh_plan_environment" {
  description = "GitHub Environment usado pelo job de plan (precisa ser diferente de gh_environment para os dois apps terem secrets separados)"
  type        = string
  default     = "dev-plan"
}

variable "terraform_state_storage_account_exists" {
  description = "Defina como true somente depois que bootstrap/00-backend ja tiver sido aplicado (a storage account do tfstate ja existe). Controla a criacao da role assignment 'Storage Blob Data Reader' do app de plan — ver comentario em terraform_plan_app.tf."
  type        = bool
  default     = true
}
