locals {
  # Wrapped in sensitive() so the private key content (not just the file path) is treated as
  # sensitive by the Terraform CLI/plan output, not only the state file.
  argocd_repo_ssh_private_key = sensitive(file(var.argocd_project_ssh_private_key_path))
}

resource "kubernetes_secret_v1" "project_repo_secret" {
  metadata {
    name      = "${var.argocd_project_name}-repo-secret"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type            = "git"
    url             = var.argocd_project_repo_url
    sshPrivateKey   = local.argocd_repo_ssh_private_key
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
      destinations:
        - server: 'https://kubernetes.default.svc'
          namespace: argocd
        - server: 'https://kubernetes.default.svc'
          namespace: mywebapp
        - server: 'https://kubernetes.default.svc'
          namespace: mywebapp2
      clusterResourceWhitelist:
        - group: ''
          kind: Namespace
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