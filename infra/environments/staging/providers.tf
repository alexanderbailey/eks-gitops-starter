provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "eks-gitops-starter"
      ManagedBy   = "terraform"
      Environment = var.name
    }
  }
}

# The kubernetes-family providers authenticate to the cluster this root
# creates, using `aws eks get-token`. Their config references the cluster
# module's outputs; Terraform resolves them after the cluster exists.
locals {
  exec_args = ["eks", "get-token", "--cluster-name", module.cluster.cluster_name, "--region", var.region]
}

provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = local.exec_args
  }
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = local.exec_args
    }
  }
}

provider "kubectl" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = local.exec_args
  }
}
