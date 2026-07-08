# Argo CD, plus the single app-of-apps that hands control to GitOps.

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_versions.argo_cd
  atomic           = true
  cleanup_on_fail  = true

  # Let Terraform install Argo CD; do not let it fight in-cluster changes to
  # values that Argo CD manages for itself once running.
  lifecycle {
    ignore_changes = all
  }
}

# Optional: deploy key for a PRIVATE gitops repo. For a public HTTPS repo this
# secret is unnecessary and is not created.
resource "kubernetes_secret" "gitops_repo" {
  count = var.gitops_repo_ssh_key == "" ? 0 : 1

  metadata {
    name      = "gitops-repo"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = var.gitops_repo_url
    sshPrivateKey = var.gitops_repo_ssh_key
  }

  depends_on = [helm_release.argocd]
}

# The app-of-apps. Applied as a raw manifest so there is no plan-time
# dependency on the Argo CD CRDs being installed first.
resource "kubectl_manifest" "app_of_apps" {
  depends_on = [helm_release.argocd]

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "app-of-apps"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.target_revision
        path           = var.app_of_apps_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
      revisionHistoryLimit = 3
    }
  })
}
