terraform {
  backend "azurerm" {
    # All the information for the backend is injected via the backend.tfvars file.
    # This is to avoid hardcoding sensitive information in the codebase.
    key =  "terraform/argocd.tfstate"
  }
}