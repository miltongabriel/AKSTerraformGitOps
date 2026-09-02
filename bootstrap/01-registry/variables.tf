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

variable "registry_resource_group_name" {
  description = "Resource group for the ACR managed by this module (its own naming convention, separate from the shared rg-* resource group used elsewhere)."
  type        = string
}

variable "location" {
  description = "Azure region for the resources - shared across every bootstrap/terraform step; must match terraform/profiles/dev.tfvars."
  type        = string
}

variable "acr_name" {
  description = "Name of the ACR managed by this module."
  type        = string
}

variable "acr_sku" {
  description = "SKU of the Container Registry."
  type        = string
}
