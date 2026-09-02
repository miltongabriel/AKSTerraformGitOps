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