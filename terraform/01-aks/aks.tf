resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.project_name}-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = local.tfstate_resource_group_name
  dns_prefix          = "aks${var.project_name}${var.environment}${var.location}"
  kubernetes_version  = var.aks_k8s_version
  # Deliberate: the API server is publicly reachable, protected only by Azure AD RBAC below (no network isolation).
  private_cluster_enabled = false

  # azure_active_directory_role_based_access_control below layers Azure AD as an authz webhook on top of this - not redundant despite the near-identical name.
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.aks_admin_group_object_ids
    azure_rbac_enabled     = true
  }

  # All cluster access (CI and human operators) goes through Azure AD RBAC instead of local accounts - see terraform/02-argocd/providers.tf for the exec+kubelogin auth this requires.
  local_account_disabled = true

  # Enables pod-level Azure Workload Identity capability - not consumed by anything in this repo yet, left on as groundwork for a future enhancement.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name            = "${var.environment}akspool"
    node_count      = 1
    max_pods        = 30
    vm_size         = var.aks_default_node_pool_vm_size
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  # Node Autoprovisioning (Karpenter-based): the cluster can create node pools beyond the fixed default_node_pool above as workloads demand it.
  node_provisioning_profile {
    mode = "Auto"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].upgrade_settings
    ]
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = data.terraform_remote_state.registry.outputs.acr_id
  # The kubelet identity is a managed identity that may not have propagated in AAD yet at plan time - without this, the role assignment can intermittently fail.
  skip_service_principal_aad_check = true
}