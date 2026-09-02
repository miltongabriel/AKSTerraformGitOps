resource "kubernetes_secret_v1" "project_repo_secret" {
  metadata {
    name      = "${var.argocd_project_name}-repo-secret"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = var.argocd_project_repo_url
    sshPrivateKey = sensitive(data.azurerm_key_vault_secret.argocd_ssh_private_key.value)
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "kubectl_manifest" "argocd_project" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: AppProject
    metadata:
      name: ${var.argocd_project_name}
      namespace: argocd
    spec:
      description: 'Applications for the ${var.argocd_project_name} GitOps project'
      sourceRepos:
        - '${var.argocd_project_repo_url}'
      # Wildcard destinations/kinds are deliberate for this single-tenant learning cluster, not an oversight.
      destinations:
        - server: 'https://kubernetes.default.svc'
          namespace: '*'
      namespaceResourceWhitelist:
        - group: '*'
          kind: '*'
  YAML

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_root_app" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: root-app
      namespace: argocd
    spec:
      project: ${var.argocd_project_name}
      source:
        repoURL: '${var.argocd_project_repo_url}'
        targetRevision: HEAD
        path: '${var.argocd_project_path}'
      destination:
        server: 'https://kubernetes.default.svc'
        namespace: argocd
      # prune deletes any cluster resource removed from Git; selfHeal reverts manual in-cluster edits back to what's in Git - both automatic.
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
  YAML

  depends_on = [
    helm_release.argocd,
    kubernetes_secret_v1.project_repo_secret,
    kubectl_manifest.argocd_project
  ]
}