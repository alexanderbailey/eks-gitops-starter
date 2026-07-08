# cert-manager operator. The ClusterIssuer(s) are delivered via GitOps
# (platform-addons), not here — this only installs the controller + CRDs.

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.chart_versions.cert_manager
  atomic           = true
  cleanup_on_fail  = true

  set {
    name  = "crds.enabled"
    value = "true"
  }
}
