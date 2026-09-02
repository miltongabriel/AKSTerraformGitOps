provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  features {}
}

# kubelogin exchanges the current Azure AD session (azure/login in CI, `az login` locally) for an AKS access token in "azurecli" mode - local accounts are disabled, so this replaces the old client-certificate kube_config fields; "workloadidentity" mode is for pod-level identity instead, not used here; 6dae42f8-4368-4678-94ff-3960e28e3630 is AKS's fixed, tenant-independent AAD server app ID.
locals {
  kubelogin_exec_args = [
    "get-token",
    "--login", "azurecli",
    "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630",
  ]
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)

  # Classic SDKv2 block syntax - both this provider and kubectl (alekc) use it.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = local.kubelogin_exec_args
  }
}

provider "kubectl" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = local.kubelogin_exec_args
  }
}

provider "helm" {
  kubernetes = {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = local.kubelogin_exec_args
    }
  }
}