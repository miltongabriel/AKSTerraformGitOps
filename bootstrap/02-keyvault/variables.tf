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

variable "argocd_project_ssh_private_key_path" {
  description = "Caminho local para a chave privada SSH do ArgoCD (mesma chave gerada com ssh-keygen no README). Lida uma unica vez aqui, via file(), para seedar o segredo no Key Vault - terraform/02-argocd nunca mais toca no arquivo local, so le o Key Vault."
  type        = string
  sensitive   = true
}
