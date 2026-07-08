locals {
  # Scope Secrets Manager access to this account when known, else any account.
  secrets_manager_arns = var.aws_account_id == "" ? [
    "arn:aws:secretsmanager:${var.region}:*:secret:*"
    ] : [
    "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:*"
  ]
}

module "cluster" {
  source = "../../modules/cluster"

  name   = var.name
  region = var.region

  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  single_nat_gateway = var.single_nat_gateway

  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  node_instance_types            = var.node_instance_types
  node_min_size                  = var.node_min_size
  node_max_size                  = var.node_max_size
  node_desired_size              = var.node_desired_size

  secrets_manager_arns = local.secrets_manager_arns

  gitops_repo_url     = var.gitops_repo_url
  app_of_apps_path    = var.app_of_apps_path
  gitops_repo_ssh_key = var.gitops_repo_ssh_key

  enable_alb                 = var.enable_alb
  enable_external_dns        = var.enable_external_dns
  external_dns_domain_filter = var.cluster_domain

  enable_rds              = var.enable_rds
  rds_instance_class      = var.rds_instance_class
  rds_multi_az            = var.rds_multi_az
  rds_deletion_protection = var.rds_deletion_protection
}
