locals {
  # Must match the name generated in bootstrap/00-backend/storageContainer.tf.
  # Used only to locate other modules' remote state (same storage
  # account/container, only the "key" differs) via terraform_remote_state.
  tfstate_resource_group_name  = "rg-${var.project_name}-${var.environment}-${var.location}"
  tfstate_storage_account_name = "st${var.project_name}${var.location}"
  tfstate_container_name       = "container-${var.project_name}-${var.environment}-${var.location}-tfstates"
}
