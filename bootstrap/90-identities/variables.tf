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

# Must match terraform/profiles/dev.tfvars
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

# -- App 1: registry ---------------------------------------------------------

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

# -- App 2: terraform apply --------------------------------------------------

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

# -- App 3: terraform plan / read-only ---------------------------------------

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

# -- Human/operator access to AKS via Azure RBAC (see operator_access.tf) ---

variable "operator_aad_object_ids" {
  description = "Object IDs do Azure AD (usuarios ou grupos) que recebem 'Azure Kubernetes Service RBAC Cluster Admin' no cluster - necessario porque terraform/01-aks roda com local_account_disabled = true. Ver operator_access.tf."
  type        = list(string)
  default     = []
}
