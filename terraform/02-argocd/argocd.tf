resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      "app.kubernetes.io/name" = "argocd"
      environment              = var.environment
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  set = [
    # Uncomment the following lines to expose ArgoCD server via LoadBalancer (not recommended for production)
    # {
  #     name  = "server.service.type"
  #     value = "LoadBalancer"
    # },
    # {
  #     name  = "server.service.loadBalancerSourceRanges"
  #     value = "{0.0.0.0/0}"
    # },
    {
      name  = "configs.params.server.insecure"
      value = "true"
    },
    {
      name  = "server.extraArgs"
      value = "{--insecure}"
    },
    {
      name  = "server.resources.limits.cpu"
      value = "500m"                
    },
    {
      name  = "server.resources.limits.memory"
      value = "512Mi"                
    },
    {
      name  = "server.resources.requests.cpu"
      value = "250m"                
    },
    {
      name  = "server.resources.requests.memory"
      value = "256Mi"                
    }
  ]

  depends_on = [kubernetes_namespace_v1.argocd]
}