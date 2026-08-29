# Modulo de bootstrap: cria o Resource Group + Container Registry (ACR)
# usados pelo build-push-app.yml e pelos apps de identidade (bootstrap/02-identities).
# Aplicado manualmente por um operador (com "az login"), depois de bootstrap/00-backend.
#
# Usa o backend remoto criado por bootstrap/00-backend (a storage account do
# tfstate ja existe nesse ponto) — ver backend.tf. So bootstrap/00-backend
# precisa ficar com state local.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.1.0"
    }
  }
  required_version = ">= 1.15.8"
}
