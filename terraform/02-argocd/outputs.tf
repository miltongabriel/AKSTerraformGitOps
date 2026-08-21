output "argocd_namespace" {
  value = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "argocd_port_forward_command" {
  value = "kubectl port-forward svc/argocd-server -n ${kubernetes_namespace_v1.argocd.metadata[0].name} 8080:80"
}

output "argocd_admin_password_command" {
  value = "kubectl -n ${kubernetes_namespace_v1.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}
