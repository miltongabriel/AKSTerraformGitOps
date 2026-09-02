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

variable "argocd_namespace" {
  description = "Namespace for ArgoCD installation."
  type        = string
}

variable "argocd_project_repo_url" {
  description = "Git clone URL (SSH) of the repository ArgoCD watches - used for the repo secret, the AppProject's sourceRepos, and the root Application's source."
  type        = string
}

variable "argocd_project_path" {
  description = "Path (inside the repository) that the root Application (App-of-Apps) syncs, e.g. \"argocd\""
  type        = string
}

variable "argocd_chart_version" {
  description = "Version of the argo/argo-cd Helm chart to install (pinned for reproducible deploys)"
  type        = string
  default     = "10.4.0"
}

variable "argocd_project_name" {
  description = "Name of the ArgoCD AppProject the root Application belongs to (also used as the Git repo secret's name prefix)."
  type        = string
}