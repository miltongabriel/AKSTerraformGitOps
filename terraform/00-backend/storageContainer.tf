resource "azurerm_resource_group" "resource_group" {
  name     = "rg-${var.project_name}-${var.environment}-${var.location}"
  location = var.location
}

locals {
  # Azure Storage Account names must be 3-24 chars, lowercase alphanumeric only, and globally
  # unique. The previous "st${project_name}${location}" scheme had no `environment` segment and
  # was already at the 24-char limit for this project/location, so a second environment (test/
  # prod) in the same project+location would either fail to apply or collide with `dev`'s state.
  # We truncate project_name+location and append a short deterministic hash of `environment` so
  # every environment gets a stable, unique name that still fits the 24-char limit.
  # NOTE: this changes the computed name for any already-applied environment. Re-applying 00-backend
  # against an existing deployment will try to replace the storage account (blocked by
  # `prevent_destroy` below) — treat that as a manual state-migration runbook, not a plain apply.
  storage_account_base = lower(replace("${var.project_name}${var.location}", "/[^a-zA-Z0-9]/", ""))
  storage_account_name = "st${substr(local.storage_account_base, 0, 16)}${substr(md5(var.environment), 0, 6)}"
}

resource "azurerm_storage_account" "terraform_state" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
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
  name                    = "container-${var.project_name}-${var.environment}-${var.location}-tfstates"
  storage_account_id      = azurerm_storage_account.terraform_state.id
  container_access_type   = "private"

  lifecycle {
    prevent_destroy = true
  }
}