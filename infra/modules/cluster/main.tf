# Composes one environment: network -> cluster -> in-cluster platform.
# The helm/kubernetes/kubectl providers are inherited from the calling
# environment root (which configures them against this cluster's endpoint).

locals {
  cluster_name = "${var.name}-cluster"
  tags         = merge({ Environment = var.name }, var.tags)
}

module "vpc" {
  source = "../vpc"

  name               = "${var.name}-vpc"
  cidr               = var.vpc_cidr
  azs                = var.azs
  single_nat_gateway = var.single_nat_gateway
  tags               = local.tags
}

module "eks" {
  source = "../eks"

  cluster_name                   = local.cluster_name
  cluster_version                = var.cluster_version
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnet_ids
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  node_instance_types            = var.node_instance_types
  node_min_size                  = var.node_min_size
  node_max_size                  = var.node_max_size
  node_desired_size              = var.node_desired_size
  tags                           = local.tags
}

module "addons" {
  source = "../addons"

  cluster_name = module.eks.cluster_name
  region       = var.region

  secrets_manager_arns = var.secrets_manager_arns

  gitops_repo_url     = var.gitops_repo_url
  app_of_apps_path    = var.app_of_apps_path
  gitops_repo_ssh_key = var.gitops_repo_ssh_key
  target_revision     = var.target_revision

  enable_alb          = var.enable_alb
  vpc_id              = module.vpc.vpc_id
  enable_external_dns = var.enable_external_dns

  external_dns_domain_filter = var.external_dns_domain_filter

  tags = local.tags
}

module "rds" {
  count  = var.enable_rds ? 1 : 0
  source = "../rds"

  name       = "${var.name}-db"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.eks.node_security_group_id]

  instance_class      = var.rds_instance_class
  multi_az            = var.rds_multi_az
  deletion_protection = var.rds_deletion_protection

  tags = local.tags
}
