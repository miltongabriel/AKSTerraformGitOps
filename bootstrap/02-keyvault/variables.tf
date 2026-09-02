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

variable "argocd_project_ssh_private_key_path" {
  description = "Local path to the ArgoCD SSH private key (the same key generated with ssh-keygen in the README). Read once here, via file(), to seed the Key Vault secret - terraform/02-argocd never touches the local file again, it only reads Key Vault."
  type        = string
  sensitive   = true
}
