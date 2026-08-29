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