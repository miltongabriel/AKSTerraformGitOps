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
  description = "Resource group do ACR (criado originalmente por setup_registry.sh)"
  type        = string
  default     = "aksterraformgitops"
}

variable "location" {
  description = "Regiao do resource group/ACR"
  type        = string
  default     = "westcentralus"
}

variable "acr_name" {
  description = "Nome do ACR (criado originalmente por setup_registry.sh)"
  type        = string
  default     = "gbenettiregistry"
}

variable "acr_sku" {
  description = "SKU do Container Registry"
  type        = string
  default     = "Basic"
}
