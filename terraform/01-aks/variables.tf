variable "environment" {
  description = "Environment name (e.g. \"dev\") - shared across every bootstrap/terraform step; must match terraform/profiles/dev.tfvars."
  type        = string
}

variable "project_name" {
  description = "Name prefix applied to resource names - shared across every bootstrap/terraform step; must match terraform/profiles/dev.tfvars."
  type        = string
}

variable "location" {
  description = "Azure region for the resources - shared across every bootstrap/terraform step; must match terraform/profiles/dev.tfvars."
  type        = string
}

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

variable "aks_k8s_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.35.7"
}

variable "aks_default_node_pool_vm_size" {
  description = "VM size for the default node pool in the AKS cluster"
  type        = string
}

variable "aks_admin_group_object_ids" {
  description = "Optional Azure AD group object IDs granted AKS-managed break-glass admin access (bypasses Azure RBAC checks entirely). Leave empty and use the per-identity role assignments in bootstrap/90-identities (terraform_apply/terraform_plan/operator_access.tf) instead, unless a break-glass mechanism is specifically wanted."
  type        = list(string)
  default     = []
}