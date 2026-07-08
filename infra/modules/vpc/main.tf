# VPC with public + private subnets, sized from the given AZ list.
# Subnets are tagged for EKS load-balancer discovery.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = var.name
  cidr = var.cidr
  azs  = var.azs

  # /20 private + /20 public subnets carved out of the VPC CIDR, one per AZ.
  private_subnets = [for i, az in var.azs : cidrsubnet(var.cidr, 4, i)]
  public_subnets  = [for i, az in var.azs : cidrsubnet(var.cidr, 4, i + 8)]

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required for the AWS Load Balancer Controller / EKS to discover subnets.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}
