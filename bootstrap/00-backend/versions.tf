terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.1.0"
    }
  }
  required_version = ">= 1.15.8"

  # Explicit local backend so -backend-config="path=<environment>.tfstate"
  # (bootstrap/run.sh) actually takes effect - without a backend block here,
  # -backend-config is silently ignored and every environment would share
  # the same default terraform.tfstate.
  backend "local" {}
}