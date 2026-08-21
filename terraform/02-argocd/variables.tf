variable "environment" {
  description = "Environment name (Dev, Test, Prod)"
  type        = string
}

variable "project_name" {
  description = "Name prefix applied to all resources and tags"
  type        = string
  default     = "aksgitops"
}

variable "location" {
  description = "Location of the resources"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}
variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  sensitive   = true
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD installation"
  type        = string
}

variable "argocd_project_repo_url" {
  description = "URL of the project repository"
  type        = string
}

variable "argocd_project_path" {
  description = "Path to the project within the repository"
  type        = string
}

variable "argocd_project_name" {
  description = "Name for the project in Kubernetes"
  type        = string
}

variable "argocd_project_ssh_private_key_path" {
  description = "Path to the SSH private key for the project repository"
  type        = string
}