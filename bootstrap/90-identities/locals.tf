locals {
  # Must match the name generated in bootstrap/00-backend/storageContainer.tf.
  # Used only to locate other modules' remote state (same storage
  # account/container, only the "key" differs) via terraform_remote_state.
  resource_group_name                  = "rg-${var.project_name}-${var.environment}-${var.location}"
  terraform_state_storage_account_name = "st${var.project_name}${var.location}"
  terraform_state_container_name       = "container-${var.project_name}-${var.environment}-${var.location}-tfstates"

  # bootstrap/01-registry is deliberately shared across every environment
  # (one ACR, no `environment` variable in that module at all) and has only
  # ever been applied once, against "dev"'s container - every environment's
  # registry remote-state lookup has to keep pointing there specifically,
  # never at var.environment's own container, or a second environment would
  # find no existing registry state and try to create a duplicate ACR.
  registry_state_container_name = "container-${var.project_name}-dev-${var.location}-tfstates"
}
