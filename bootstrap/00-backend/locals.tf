locals {
  # The tfstate storage account is shared across every environment (one per
  # region - see CLAUDE.md's naming conventions), but it physically lives in
  # whichever environment's resource group first created it - "dev", since
  # that's the only environment this module has ever been applied for so
  # far. Every environment's storage account resource has to keep pointing
  # at that same resource group (not its own var.environment-derived one),
  # or Terraform would plan to destroy and recreate the shared,
  # prevent_destroy'd storage account inside its own environment's resource
  # group instead of recognizing the existing one.
  storage_account_resource_group_name = "rg-${var.project_name}-dev-${var.location}"
}
