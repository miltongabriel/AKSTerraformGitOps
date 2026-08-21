resource "azurerm_kubernetes_cluster" "aks" {
    name                              = "aks-${var.project_name}-${var.environment}-${var.location}"
    location                          = var.location
    resource_group_name               = "rg-${var.project_name}-${var.environment}-${var.location}"
    dns_prefix                        = "aks${var.project_name}${var.environment}${var.location}"
    kubernetes_version                = var.aks_k8s_version
    role_based_access_control_enabled = true
    private_cluster_enabled           = false

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

    node_provisioning_profile {
        mode = "Auto"
    }

    # Ignore changes to prevent unwanted upgrades
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