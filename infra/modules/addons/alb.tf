# AWS Load Balancer Controller (optional). Provisions ALBs from Ingress
# objects. Only installed when enable_alb = true (typically staging/prod).

module "alb_pod_identity" {
  count   = var.enable_alb ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7"

  name = "${var.cluster_name}-aws-lbc"

  attach_aws_lb_controller_policy = true

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = var.tags
}

resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_alb ? 1 : 0

  name            = "aws-load-balancer-controller"
  namespace       = "kube-system"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-load-balancer-controller"
  version         = var.chart_versions.alb_controller
  atomic          = true
  cleanup_on_fail = true

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "region"
    value = var.region
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [module.alb_pod_identity]
}
