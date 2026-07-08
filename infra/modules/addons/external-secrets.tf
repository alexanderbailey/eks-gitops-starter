# External Secrets Operator + its AWS access via EKS Pod Identity.
#
# The pod-identity module builds the IAM role with a scoped Secrets Manager
# read policy and creates the association to the controller's ServiceAccount.
# No IRSA/OIDC and no SA annotations required.

module "eso_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7"

  name = "${var.cluster_name}-external-secrets"

  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = var.secrets_manager_arns
  external_secrets_create_permission    = false

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }

  tags = var.tags
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.chart_versions.external_secrets
  atomic           = true
  cleanup_on_fail  = true

  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  depends_on = [module.eso_pod_identity]
}
