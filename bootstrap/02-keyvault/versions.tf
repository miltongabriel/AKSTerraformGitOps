# Modulo de bootstrap: cria o Azure Key Vault que guarda a chave privada SSH
# do ArgoCD (lida por terraform/02-argocd via data source, em vez do
# Terraform ler um arquivo local com file()). Aplicado manualmente por um
# operador (com "az login"), depois de bootstrap/01-registry e antes de
# bootstrap/90-identities — a ordem importa: 90-identities concede aos apps
# de CI a role de leitura neste vault, entao o vault precisa existir antes.
#
# Usa o backend remoto criado por bootstrap/00-backend (a storage account do
# tfstate ja existe nesse ponto) — ver backend.tf.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.1.0"
    }
  }
  required_version = ">= 1.15.8"
}
