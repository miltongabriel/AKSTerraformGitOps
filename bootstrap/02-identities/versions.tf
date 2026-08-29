# Modulo de bootstrap: cria os App Registrations (OIDC) usados pelos workflows
# do GitHub Actions. E aplicado manualmente por um operador (com "az login" /
# credenciais proprias), NAO pelo pipeline de CI.
#
# Usa o backend remoto criado por bootstrap/00-backend — ver backend.tf. So
# bootstrap/00-backend precisa ficar com state local (ele que cria a propria
# storage account do state remoto; todo o resto, incluindo este modulo, roda
# depois e pode apontar pra ela).

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.1.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
  }
  required_version = ">= 1.15.8"
}
