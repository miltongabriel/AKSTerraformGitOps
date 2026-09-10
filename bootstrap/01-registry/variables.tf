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

variable "resource_group_name" {
  description = "Resource group do ACR gerenciado por este modulo"
  type        = string
  default     = "aksterraformgitops"
}

variable "location" {
  description = "Regiao do resource group/ACR"
  type        = string
  default     = "westcentralus"
}

variable "acr_name" {
  description = "Nome do ACR gerenciado por este modulo"
  type        = string
  default     = "gbenettiregistry"
}

variable "acr_sku" {
  description = "SKU do Container Registry"
  type        = string
  default     = "Basic"
}
