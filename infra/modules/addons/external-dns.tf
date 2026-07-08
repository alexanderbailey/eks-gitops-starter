# External DNS (optional). Creates Route53 records from Ingress/Service
# objects. Only installed when enable_external_dns = true.

module "external_dns_pod_identity" {
  count   = var.enable_external_dns ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7"

  name = "${var.cluster_name}-external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = var.external_dns_zone_arns

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = "external-dns"
      service_account = "external-dns"
    }
  }

  tags = var.tags
}

resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = true
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.chart_versions.external_dns
  atomic           = true
  cleanup_on_fail  = true

  set {
    name  = "provider"
    value = "aws"
  }
  set {
    name  = "policy"
    value = "sync"
  }
  set {
    name  = "domainFilters[0]"
    value = var.external_dns_domain_filter
  }
  set {
    name  = "txtOwnerId"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  depends_on = [module.external_dns_pod_identity]
}
