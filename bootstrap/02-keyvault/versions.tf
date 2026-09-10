# Bootstrap module: creates the Azure Key Vault holding the ArgoCD SSH
# private key. Applied manually by an operator, after bootstrap/01-registry
# and before bootstrap/90-identities — see bootstrap/README.md for the full
# step order and rationale.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.1.0"
    }
  }
  required_version = ">= 1.15.8"
}
