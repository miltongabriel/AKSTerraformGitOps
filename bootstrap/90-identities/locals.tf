locals {
  # Precisa bater com o nome gerado em bootstrap/00-backend/storageContainer.tf
  resource_group_name = "rg-${var.project_name}-${var.environment}-${var.location}"

  # Precisa bater com o nome gerado em bootstrap/00-backend/storageContainer.tf
  terraform_state_storage_account_name = "st${var.project_name}${var.location}"
}
