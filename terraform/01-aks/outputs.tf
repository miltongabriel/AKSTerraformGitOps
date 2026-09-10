output "Access_credentials" {
  value = "az aks get-credentials --resource-group ${azurerm_kubernetes_cluster.aks.resource_group_name} --name ${azurerm_kubernetes_cluster.aks.name} && kubelogin convert-kubeconfig -l azurecli"
}

output "cluster_name" {
  description = "Nome do cluster AKS - consumido via terraform_remote_state por terraform/02-argocd em vez de reconstruido por convencao de nome"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  description = "Resource group do cluster AKS - consumido via terraform_remote_state por terraform/02-argocd em vez de reconstruido por convencao de nome"
  value       = azurerm_kubernetes_cluster.aks.resource_group_name
}

output "oidc_issuer_url" {
  description = "AKS OIDC issuer URL - needed if a future workload wires up pod-level Azure Workload Identity (azurerm_federated_identity_credential trusting a K8s ServiceAccount). Not consumed anywhere in this repo yet."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "kubelogin_convert_command" {
  description = "Local accounts are disabled (local_account_disabled = true) - az aks get-credentials returns an AAD-based kubeconfig using the legacy client-go auth-provider plugin, which current kubectl/client-go no longer support directly. Run this once after get-credentials to rewrite it into the modern exec-plugin form."
  value       = "kubelogin convert-kubeconfig -l azurecli"
}