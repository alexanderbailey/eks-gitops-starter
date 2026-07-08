# EKS cluster using the community module.
#
# Modern choices:
#   - authentication_mode = "API" + access entries (no aws-auth ConfigMap)
#   - the EKS Pod Identity Agent addon, so workloads get AWS creds via Pod
#     Identity associations (see the addons module) instead of IRSA/OIDC.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = var.cluster_endpoint_public_access

  # Access entries; grant the identity running Terraform cluster-admin so the
  # provider can bootstrap in-cluster resources.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = {}
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = var.tags
}
