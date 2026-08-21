resource "azurerm_resource_group" "resource_group" {
  name     = "rg-${var.project_name}-${var.environment}-${var.location}"
  location = var.location
}

resource "azurerm_storage_account" "terraform_state" {
  name                            = "st${var.project_name}${var.location}"
  resource_group_name             = azurerm_resource_group.resource_group.name
  location                        = azurerm_resource_group.resource_group.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = {
    environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "container-${var.project_name}-${var.environment}-${var.location}-tfstates"
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}