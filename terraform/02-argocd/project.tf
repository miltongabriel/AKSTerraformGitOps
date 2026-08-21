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
    sshPrivateKey   = file(var.argocd_project_ssh_private_key_path)
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "kubectl_manifest" "argocd_root_app" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: root-app
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: 'git@github.com:miltongabriel/AKSTerraformGitOps.git'
        targetRevision: HEAD
        path: argocd/
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
    kubernetes_secret_v1.project_repo_secret
  ]
}